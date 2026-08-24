const admin = require('firebase-admin');
const crypto = require('crypto');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  try {
    let serviceAccount;
    if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
      const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
      serviceAccount = JSON.parse(decodedKey);
    } else {
      serviceAccount = require('../../../firebase-admin-key.json');
    }
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.log('Firebase admin initialization error', error.stack);
  }
}

const db = admin.firestore();

module.exports = async (req, res) => {
  // CORS Setup
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { verificationId, resetToken, newPassword } = req.body;

    if (!verificationId || !resetToken || !newPassword) {
      return res.status(400).json({ success: false, error: 'Missing required parameters.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, error: 'Password must be at least 6 characters long.' });
    }

    const sessionRef = db.collection('password_reset_sessions').doc(verificationId);
    
    // Use transaction to ensure session is only used once
    const result = await db.runTransaction(async (transaction) => {
      const sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) {
        throw new Error('Session not found.');
      }

      const session = sessionDoc.data();
      const now = admin.firestore.Timestamp.now();

      // 1. Validation Checks
      if (session.used) {
        throw new Error('This password reset session has already been used.');
      }

      if (!session.verified) {
        throw new Error('OTP has not been verified.');
      }

      if (!session.resetTokenHash || !session.resetTokenExpiresAt) {
        throw new Error('Reset token is invalid.');
      }

      if (session.resetTokenExpiresAt.toDate() < now.toDate()) {
        throw new Error('Reset token has expired.');
      }

      const computedHash = crypto.createHash('sha256').update(resetToken).digest('hex');
      if (computedHash !== session.resetTokenHash) {
        throw new Error('Invalid reset token.');
      }

      // 2. Mark session as used
      transaction.update(sessionRef, {
        used: true,
        usedAt: now
      });

      return session;
    });

    const { firebaseUid, userId, accountCollection } = result;

    // 3. Update password in Firebase Auth (Primary Source of Truth)
    await admin.auth().updateUser(firebaseUid, {
      password: newPassword
    });

    // 4. Update password in Firestore to keep legacy systems consistent
    if (accountCollection && userId) {
      const userRef = db.collection(accountCollection).doc(userId);
      await userRef.update({ password: newPassword }).catch(err => {
        console.warn(`Failed to update password in ${accountCollection} for user ${userId}:`, err);
      });
    }

    // 5. Invalidate any other active reset sessions for this user (Optional cleanup)
    // We can do this asynchronously so it doesn't block the response
    db.collection('password_reset_sessions')
      .where('firebaseUid', '==', firebaseUid)
      .where('used', '==', false)
      .get()
      .then(snapshot => {
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
          if (doc.id !== verificationId) {
            batch.update(doc.ref, { used: true, usedAt: admin.firestore.Timestamp.now() });
          }
        });
        return batch.commit();
      })
      .catch(err => console.warn('Failed to cleanup other sessions:', err));

    // 6. Generate Custom Token for auto-login
    const customToken = await admin.auth().createCustomToken(firebaseUid);

    return res.status(200).json({
      success: true,
      message: 'Password reset successfully.',
      customToken: customToken
    });

  } catch (error) {
    console.error('Error in reset password:', error);
    if (error.message && (error.message.includes('Session') || error.message.includes('OTP') || error.message.includes('token'))) {
      return res.status(400).json({ success: false, error: error.message });
    }
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};

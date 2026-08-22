const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const crypto = require('crypto');

// Initialize Firebase Admin if it hasn't been already
if (!admin.apps.length) {
  try {
    const serviceAccount = require('../firebase-admin-key.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } catch (error) {
    console.error("Firebase Admin Initialization Error:", error);
  }
}

// Helper to hash OTP (must match Dart implementation)
function hashOtp(otp) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

module.exports = async (req, res) => {
  // Setup CORS
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ message: 'Method Not Allowed' });
    }

    try {
      const { email, otp, newPassword } = req.body;

      if (!email || !otp || !newPassword) {
        return res.status(400).json({ message: 'Missing required fields' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      const db = admin.firestore();

      // 1. Fetch OTP Request from Firestore
      const docRef = db.collection('password_reset_requests').doc(normalizedEmail);
      const doc = await docRef.get();

      if (!doc.exists) {
        return res.status(400).json({ message: 'No active password reset request found.' });
      }

      const data = doc.data();

      // 2. Validate OTP
      if (data.used) {
        return res.status(400).json({ message: 'This code has already been used.' });
      }

      const expiresAt = data.expiresAt.toDate();
      if (new Date() > expiresAt) {
        return res.status(400).json({ message: 'Your verification code has expired.' });
      }

      const attempts = data.attempts || 0;
      const maxAttempts = data.maxAttempts || 5;

      if (attempts >= maxAttempts) {
        return res.status(400).json({ message: 'Too many failed attempts. Please request a new code.' });
      }

      const enteredHash = hashOtp(otp);
      if (data.otpHash !== enteredHash) {
        await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
        return res.status(400).json({ message: 'The verification code is incorrect.' });
      }

      // 3. OTP is valid! Update the password using Firebase Admin
      const userRecord = await admin.auth().getUserByEmail(normalizedEmail);

      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword
      });

      // 3.5 Update password in custom Firestore collections if it exists
      const collections = [
        'users',
        'workers',
        'transports',
        'healthcare',
        'shops_businesses',
      ];
      for (const collectionName of collections) {
        const querySnapshot = await db.collection(collectionName).where('email', '==', normalizedEmail).get();
        if (!querySnapshot.empty) {
          const promises = querySnapshot.docs.map(userDoc => 
            userDoc.ref.update({
              password: newPassword,
              updated_at: admin.firestore.FieldValue.serverTimestamp()
            })
          );
          await Promise.all(promises);
        }
      }

      // 4. Mark OTP as used
      await docRef.update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return res.status(200).json({ message: 'Password updated successfully!' });

    } catch (error) {
      console.error('Error updating password:', error);
      return res.status(500).json({ message: 'Internal Server Error' });
    }
  });
};

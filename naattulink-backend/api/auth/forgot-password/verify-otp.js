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
    const { verificationId, otp } = req.body;

    if (!verificationId || !otp) {
      return res.status(400).json({ success: false, error: 'Missing verificationId or otp' });
    }

    const sessionRef = db.collection('password_reset_sessions').doc(verificationId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return res.status(404).json({ success: false, error: 'Session not found or expired.' });
    }

    const session = sessionDoc.data();
    const now = admin.firestore.Timestamp.now();

    // 1. Validation Checks
    if (session.used) {
      return res.status(400).json({ success: false, error: 'This session has already been used.' });
    }

    if (session.expiresAt.toDate() < now.toDate()) {
      return res.status(400).json({ success: false, error: 'OTP has expired. Please request a new one.' });
    }

    if (session.attempts >= session.maxAttempts) {
      return res.status(400).json({ success: false, error: 'Maximum attempts reached. Please request a new OTP.' });
    }
    
    if (session.verified) {
      // If they somehow call this again after verifying
      return res.status(400).json({ success: false, error: 'OTP already verified for this session.' });
    }

    // 2. Hash and Compare OTP
    const pepper = process.env.OTP_PEPPER || 'default_dev_pepper_please_change';
    const computedHash = crypto.createHmac('sha256', pepper).update(otp.toString().trim()).digest('hex');

    if (computedHash !== session.otpHash) {
      // Increment attempts
      await sessionRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
      const remaining = session.maxAttempts - session.attempts - 1;
      return res.status(400).json({ 
        success: false, 
        error: `Invalid OTP. You have ${remaining} attempts left.` 
      });
    }

    // 3. Success: Generate Reset Token
    const rawResetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto.createHash('sha256').update(rawResetToken).digest('hex');
    
    // Set reset token expiry to 10 minutes from now
    const resetTokenExpiresAt = new admin.firestore.Timestamp(now.seconds + 10 * 60, now.nanoseconds);

    await sessionRef.update({
      verified: true,
      verifiedAt: now,
      resetTokenHash: resetTokenHash,
      resetTokenExpiresAt: resetTokenExpiresAt
    });

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      resetToken: rawResetToken
    });

  } catch (error) {
    console.error('Error in verify-otp:', error);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};

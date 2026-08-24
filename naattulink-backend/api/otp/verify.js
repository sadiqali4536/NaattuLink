const admin = require('firebase-admin');
const crypto = require('crypto');

if (!admin.apps.length) {
  try {
    let serviceAccount;
    if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
      const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
      serviceAccount = JSON.parse(decodedKey);
    } else {
      serviceAccount = require('../../firebase-admin-key.json');
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
  // CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const { requestId, otp, purpose } = req.body;

    if (!requestId || !otp || !purpose) {
      return res.status(400).json({ error: 'Missing requestId, otp, or purpose' });
    }

    const otpDocRef = db.collection('otp_requests').doc(requestId);
    const otpDoc = await otpDocRef.get();

    if (!otpDoc.exists) {
      return res.status(404).json({ error: 'Invalid or missing OTP request.' });
    }

    const data = otpDoc.data();

    if (data.purpose !== purpose) {
      return res.status(400).json({ error: 'Invalid purpose.' });
    }

    if (data.used) {
      return res.status(400).json({ error: 'This OTP has already been used.' });
    }

    if (data.attempts >= data.maxAttempts) {
      return res.status(403).json({ error: 'Maximum attempts reached. This OTP is permanently locked.' });
    }

    const now = admin.firestore.Timestamp.now();
    if (now.toMillis() > data.expiresAt.toMillis()) {
      return res.status(400).json({ error: 'This OTP has expired. Please request a new one.' });
    }

    // HMAC the provided OTP
    const pepper = process.env.OTP_PEPPER || 'default_dev_pepper_please_change';
    const inputHash = crypto.createHmac('sha256', pepper).update(otp.toString()).digest('hex');

    if (inputHash !== data.otpHash) {
      // Wrong OTP. Increment attempts.
      const newAttempts = (data.attempts || 0) + 1;
      await otpDocRef.update({ attempts: newAttempts });

      return res.status(401).json({
        error: 'Incorrect OTP.',
        attemptsRemaining: data.maxAttempts - newAttempts
      });
    }

    // Correct OTP. Mark as used and verified.
    await otpDocRef.update({ used: true, status: 'verified', attempts: (data.attempts || 0) + 1 });

    // If purpose is password reset, generate a short-lived reset token
    let resetToken = null;
    let customToken = null;

    if (purpose === 'password_reset') {
      resetToken = 'reset_' + crypto.randomBytes(32).toString('hex');

      const tokenExpiresAt = new admin.firestore.Timestamp(now.seconds + 10 * 60, now.nanoseconds); // 10 mins
      await db.collection('password_reset_tokens').doc(resetToken).set({
        uid: data.uid,
        identifier: data.identifier,
        expiresAt: tokenExpiresAt,
        used: false,
        createdAt: now
      });
    } else if (purpose === 'login') {
      // Create a Firebase Custom Auth Token so Flutter can sign in
      customToken = await admin.auth().createCustomToken(data.uid);
    }

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
      resetToken: resetToken, // Only provided if purpose is password_reset
      customToken: customToken // Only provided if purpose is login
    });

  } catch (error) {
    console.error('Error verifying OTP:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

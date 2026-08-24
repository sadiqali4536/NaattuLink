const admin = require('firebase-admin');
const crypto = require('crypto');

// Initialize Firebase Admin (Only once per cold start)
if (!admin.apps.length) {
  try {
    // We expect FIREBASE_PRIVATE_KEY to be a string that might have literal \n or actual newlines
    let privateKey = process.env.FIREBASE_PRIVATE_KEY;
    if (privateKey) {
      privateKey = privateKey.replace(/\\n/g, '\n');
    }

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey,
      }),
    });
  } catch (error) {
    console.error('Firebase Admin Initialization Error:', error);
  }
}

export default async function handler(req, res) {
  // CORS Handling for Vercel
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method Not Allowed' });
  }

  const { email, otp, newPassword } = req.body;

  if (!email || !otp || !newPassword) {
    return res.status(400).json({ success: false, message: 'Missing required fields.' });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const db = admin.firestore();

  try {
    const requestRef = db.collection('password_reset_requests').doc(normalizedEmail);
    
    // Run inside a transaction to prevent race conditions on `attempts`
    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(requestRef);
      
      if (!doc.exists) {
        throw new Error('NOT_FOUND');
      }

      const data = doc.data();

      if (data.used) {
        throw new Error('ALREADY_USED');
      }

      const attempts = data.attempts || 0;
      const maxAttempts = data.maxAttempts || 5;

      if (attempts >= maxAttempts) {
        throw new Error('MAX_ATTEMPTS');
      }

      // Check Expiration
      const expiresAt = data.expiresAt.toDate();
      if (new Date() > expiresAt) {
        throw new Error('EXPIRED');
      }

      // Hash the incoming OTP
      const incomingHash = crypto.createHash('sha256').update(otp.toString()).digest('hex');

      if (incomingHash !== data.otpHash) {
        // Increment attempts
        transaction.update(requestRef, { attempts: attempts + 1 });
        throw new Error('INVALID_OTP');
      }

      // 1. Success! Update Firebase Auth Password
      const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword,
      });

      // 2. Mark request as used
      transaction.update(requestRef, { 
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    return res.status(200).json({ success: true, message: 'Password updated successfully.' });

  } catch (error) {
    console.error('Password Reset Error:', error.message);

    // Generic error responses to prevent enumeration
    if (error.message === 'NOT_FOUND' || error.code === 'auth/user-not-found') {
      return res.status(400).json({ success: false, message: 'Invalid request or OTP expired.' });
    }
    if (error.message === 'ALREADY_USED') {
      return res.status(400).json({ success: false, message: 'This OTP has already been used.' });
    }
    if (error.message === 'MAX_ATTEMPTS') {
      return res.status(400).json({ success: false, message: 'Too many failed attempts. Please request a new OTP.' });
    }
    if (error.message === 'EXPIRED') {
      return res.status(400).json({ success: false, message: 'OTP has expired.' });
    }
    if (error.message === 'INVALID_OTP') {
      return res.status(400).json({ success: false, message: 'Incorrect OTP.' });
    }

    return res.status(500).json({ success: false, message: 'An internal server error occurred.' });
  }
}

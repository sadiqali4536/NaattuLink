const admin = require('firebase-admin');
const crypto = require('crypto');
const smsService = require('../../../services/sms/smsAccountManager');
const emailJsProvider = require('../../../services/email/emailJsProvider');

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

function normalizePhoneNumber(phone) {
  let normalized = phone.trim();
  normalized = normalized.replace(/[\s\-\(\)]/g, '');
  
  if (normalized.startsWith('00')) {
    normalized = '+' + normalized.substring(2);
  }
  
  if (!normalized.startsWith('+')) {
    if (normalized.length === 10) {
      normalized = '+91' + normalized;
    } else if (normalized.length === 12 && normalized.startsWith('91')) {
      normalized = '+' + normalized;
    }
  }
  
  return normalized;
}

function maskEmail(email) {
  if (!email) return null;
  const [name, domain] = email.split('@');
  if (!name || !domain) return email;
  if (name.length <= 2) return `${name}***@${domain}`;
  return `${name.substring(0, 2)}***@${domain}`;
}

function maskPhone(phone) {
  if (!phone) return null;
  const cleaned = phone.replace(/\s+/g, '');
  if (cleaned.length < 4) return cleaned;
  return `+91 ******${cleaned.substring(cleaned.length - 4)}`;
}

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
    const { identifier, method } = req.body;

    if (!identifier || !method) {
      return res.status(400).json({ error: 'Missing identifier or method' });
    }

    if (method !== 'email' && method !== 'sms') {
      return res.status(400).json({ error: 'Invalid method. Must be "email" or "sms".' });
    }

    // 1. Identify User
    const collections = ['users', 'workers', 'transports', 'healthcare', 'shops_businesses'];
    let userDoc = null;
    let foundCollection = null;

    if (identifier.includes('@')) {
      const normalizedEmail = identifier.trim().toLowerCase();
      for (const collectionName of collections) {
        const querySnapshot = await db.collection(collectionName).where('email', '==', normalizedEmail).limit(1).get();
        if (!querySnapshot.empty) {
          userDoc = querySnapshot.docs[0];
          foundCollection = collectionName;
          break;
        }
      }
    } else {
      const normalizedPhone = identifier.trim().replace(/[\s\-\(\)]/g, '');
      const phoneWithPrefix = normalizedPhone.startsWith('+91') ? normalizedPhone : '+91' + normalizedPhone.replace(/^91/, '');
      const rawPhone = phoneWithPrefix.replace('+91', '');

      for (const collectionName of collections) {
        const querySnapshot = await db.collection(collectionName)
            .where('phone', 'in', [rawPhone, phoneWithPrefix])
            .limit(1).get();
            
        if (!querySnapshot.empty) {
          userDoc = querySnapshot.docs[0];
          foundCollection = collectionName;
          break;
        }
      }
    }

    if (!userDoc) {
      return res.status(404).json({ success: false, error: 'User not found.' });
    }

    const userData = userDoc.data();
    
    // Validate that the requested method is available for this user
    let destinationToUse = null;
    let maskedDestination = null;

    if (method === 'email') {
      if (!userData.email || userData.email.trim() === '') {
        return res.status(400).json({ success: false, error: 'Email method is not available for this account.' });
      }
      destinationToUse = userData.email.trim().toLowerCase();
      maskedDestination = maskEmail(destinationToUse);
    } else if (method === 'sms') {
      const phone = userData.phone || userData.phoneNumber;
      if (!phone || phone.trim() === '') {
        return res.status(400).json({ success: false, error: 'SMS method is not available for this account.' });
      }
      destinationToUse = normalizePhoneNumber(phone);
      maskedDestination = maskPhone(destinationToUse);
    }

    // Attempt to get firebaseUid. Usually the document ID in Firestore is the firebaseUid.
    const firebaseUid = userDoc.id; // Or userData.uid if they differ, but usually doc ID = auth UID

    // 2. Generate Secure OTP and Hash
    let otp = crypto.randomInt(1000, 10000).toString();
    // Test bypass
    if (method === 'sms' && (destinationToUse === '+919207564536' || destinationToUse === '9207564536')) {
      otp = '123456';
    }

    console.log('=================================');
    console.log(`🔑 GENERATED OTP for password reset via ${method}: ${otp}`);
    console.log('=================================');

    const pepper = process.env.OTP_PEPPER || 'default_dev_pepper_please_change';
    const otpHash = crypto.createHmac('sha256', pepper).update(otp).digest('hex');

    // 3. Create OTP Request Record
    const verificationId = 'vrf_' + crypto.randomBytes(16).toString('hex');
    const now = admin.firestore.Timestamp.now();
    const expiresAt = new admin.firestore.Timestamp(now.seconds + 10 * 60, now.nanoseconds); // 10 mins

    const sessionData = {
      firebaseUid: firebaseUid,
      userId: userDoc.id,
      accountCollection: foundCollection,
      role: userData.role || 'user',
      
      method: method,
      destinationMasked: maskedDestination,
      
      otpHash: otpHash,
      expiresAt: expiresAt,
      
      attempts: 0,
      maxAttempts: 5,
      
      resendCount: 0,
      maxResends: 3,
      
      verified: false,
      verifiedAt: null,
      
      used: false,
      usedAt: null,
      
      createdAt: now
    };

    const sessionDocRef = db.collection('password_reset_sessions').doc(verificationId);
    await sessionDocRef.set(sessionData);

    // 4. Send OTP via requested method
    let deliverySuccess = false;

    if (method === 'email') {
      const emailResult = await emailJsProvider.sendEmailOtp(destinationToUse, otp);
      deliverySuccess = emailResult.success;
      if (!deliverySuccess) {
         console.error('EmailJS delivery failed:', emailResult.error);
      }
    } else if (method === 'sms') {
      if (destinationToUse === '+919207564536' || destinationToUse === '9207564536') {
        deliverySuccess = true; // Bypass
      } else {
        const smsMessage = `Your NaattuLink password reset OTP is ${otp}`;
        const smsResult = await smsService.sendSmsWithFailover({
          phone: destinationToUse,
          message: smsMessage
        });
        deliverySuccess = smsResult.success;
      }
    }

    if (!deliverySuccess) {
      // Clean up session if delivery totally failed
      await sessionDocRef.delete();
      return res.status(503).json({ success: false, error: `Failed to deliver OTP via ${method}. Please try again later.` });
    }

    return res.status(200).json({
      success: true,
      verificationId: verificationId,
      method: method,
      expiresIn: 600,
      destination: maskedDestination
    });

  } catch (error) {
    console.error('Error in send-otp:', error);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};

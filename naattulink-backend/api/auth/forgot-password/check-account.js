const admin = require('firebase-admin');

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
    const { identifier } = req.body;

    if (!identifier) {
      return res.status(400).json({ error: 'Missing identifier' });
    }

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
    const methods = [];

    if (userData.email && userData.email.trim().length > 0) {
      methods.push({
        type: 'email',
        maskedValue: maskEmail(userData.email)
      });
    }

    const phone = userData.phone || userData.phoneNumber;
    if (phone && phone.trim().length > 0) {
      methods.push({
        type: 'sms',
        maskedValue: maskPhone(phone)
      });
    }

    if (methods.length === 0) {
      return res.status(400).json({ success: false, error: 'No recovery methods available for this account.' });
    }

    return res.status(200).json({
      success: true,
      accountFound: true,
      methods: methods
    });

  } catch (error) {
    console.error('Error in check-account:', error);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};

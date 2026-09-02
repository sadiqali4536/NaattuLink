const admin = require('firebase-admin');

// Ensure Firebase is initialized
if (!admin.apps.length) {
  try {
    let serviceAccount;
    if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
      const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
      serviceAccount = JSON.parse(decodedKey);
    } else {
      serviceAccount = require('../../firebase-admin-key.json');
    }
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } catch (error) {
    console.error("Firebase Admin Initialization Error:", error);
  }
}

/**
 * Verifies the Firebase ID token from the Authorization header.
 * @param {Object} req 
 * @returns {Promise<Object>} The decoded token, or throws an error
 */
async function authenticateUser(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('UNAUTHORIZED: Missing or invalid Authorization header');
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new Error('UNAUTHORIZED: Invalid token');
  }
}

/**
 * Verifies the Firebase ID token and checks if the user has admin custom claims or role.
 * (Adjust this based on how admins are identified in NaattuLink. Usually custom claims `admin: true`
 * or a specific role field in the Firestore user document).
 * @param {Object} req 
 * @returns {Promise<Object>}
 */
async function authenticateAdmin(req) {
  const decodedToken = await authenticateUser(req);
  
  // Checking custom claim first
  if (decodedToken.admin === true) {
    return decodedToken;
  }

  // Fallback: check Firestore users collection if role == 'admin'
  try {
    const doc = await admin.firestore().collection('users').doc(decodedToken.uid).get();
    if (doc.exists && doc.data().role === 'admin') {
      return decodedToken;
    }
  } catch (error) {
    console.error("Error verifying admin role:", error);
  }
  
  throw new Error('FORBIDDEN: Admin access required');
}

module.exports = {
  authenticateUser,
  authenticateAdmin
};

const ImageKitService = require('../../services/imagekit/imagekitService');
const { authenticateAdmin } = require('./utils');
const cors = require('cors')({ origin: true });
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

const db = admin.firestore();

module.exports = async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ success: false, message: 'Method Not Allowed' });
    }

    try {
      // 1. Authenticate Admin
      await authenticateAdmin(req);

      const { providerId, testData } = req.body;
      
      let providerData;
      
      // If testing an existing provider
      if (providerId) {
        const doc = await db.collection('imagekit_providers').doc(providerId).get();
        if (!doc.exists) {
           return res.status(404).json({ success: false, message: 'Provider not found' });
        }
        providerData = doc.data();
      } 
      // If testing a new configuration before saving
      else if (testData) {
        providerData = testData;
      } else {
        return res.status(400).json({ success: false, message: 'Must provide providerId or testData' });
      }

      // 2. Test Connection
      const result = await ImageKitService.testConnection(providerData);

      // Never return the private key in the response
      return res.status(200).json(result);

    } catch (error) {
      console.error("Admin Test Connection Error:", error);
      
      if (error.message.startsWith('UNAUTHORIZED') || error.message.startsWith('FORBIDDEN')) {
        return res.status(403).json({ success: false, message: error.message });
      }

      return res.status(500).json({ success: false, message: 'Internal Server Error' });
    }
  });
};

const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

// Initialize Firebase Admin if it hasn't been already
if (!admin.apps.length) {
  try {
    let serviceAccount;
    if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
      const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
      serviceAccount = JSON.parse(decodedKey);
    } else {
      serviceAccount = require('../firebase-admin-key.json');
    }
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  } catch (error) {
    console.error("Firebase Admin Initialization Error:", error);
  }
}

module.exports = async (req, res) => {
  // Setup CORS
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ message: 'Method Not Allowed' });
    }

    try {
      const { resetToken, newPassword } = req.body;

      if (!resetToken || !newPassword) {
        return res.status(400).json({ message: 'Missing required fields' });
      }

      const db = admin.firestore();

      // 1. Fetch Reset Token from Firestore
      const docRef = db.collection('password_reset_tokens').doc(resetToken);
      const doc = await docRef.get();

      if (!doc.exists) {
        return res.status(400).json({ message: 'Invalid or missing reset token.' });
      }

      const data = doc.data();

      // 2. Validate Token
      if (data.used) {
        return res.status(400).json({ message: 'This reset token has already been used.' });
      }

      const expiresAt = data.expiresAt.toDate();
      if (new Date() > expiresAt) {
        return res.status(400).json({ message: 'Your reset token has expired.' });
      }

      // 3. Token is valid! Update the password using Firebase Admin
      const uid = data.uid;
      const identifier = data.identifier;

      await admin.auth().updateUser(uid, {
        password: newPassword
      });

      // 3.5 Update password in custom Firestore collections if it exists
      // If the identifier is an email, update collections
      if (identifier && identifier.includes('@')) {
        const normalizedEmail = identifier.trim().toLowerCase();
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
      } else {
        // If they reset via phone number, you would need logic to query by phone number here.
        // For now, we will handle phone number queries.
        const collections = ['users', 'workers', 'transports', 'healthcare', 'shops_businesses'];
        for (const collectionName of collections) {
          // Query by phone or phoneNumber
          const phoneQuery1 = db.collection(collectionName).where('phone', '==', identifier).get();
          const phoneQuery2 = db.collection(collectionName).where('phoneNumber', '==', identifier).get();
          
          const [snapshot1, snapshot2] = await Promise.all([phoneQuery1, phoneQuery2]);
          
          const docsToUpdate = [...snapshot1.docs, ...snapshot2.docs];
          if (docsToUpdate.length > 0) {
             const promises = docsToUpdate.map(userDoc => 
                userDoc.ref.update({
                  password: newPassword,
                  updated_at: admin.firestore.FieldValue.serverTimestamp()
                })
             );
             await Promise.all(promises);
          }
        }
      }

      // 4. Mark Reset Token as used
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

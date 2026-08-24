const admin = require('firebase-admin');
let serviceAccount;
if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
  const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
  serviceAccount = JSON.parse(decodedKey);
} else {
  serviceAccount = require('./firebase-admin-key.json');
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();

async function check() {
  const phone = '9207564536';
  console.log('=== SEARCHING FOR PHONE:', phone, '===');
  
  const collections = ['users', 'workers', 'transports', 'healthcare', 'shops_businesses'];
  for (const c of collections) {
    const q1 = await db.collection(c).where('phone', '==', phone).get();
    if (!q1.empty) {
      console.log('Found in', c, '-> UID:', q1.docs[0].id, 'Role:', q1.docs[0].data().role);
    }
    
    const q2 = await db.collection(c).where('phone', '==', '+91' + phone).get();
    if (!q2.empty) {
      console.log('Found in', c, '(with +91) -> UID:', q2.docs[0].id, 'Role:', q2.docs[0].data().role);
    }
  }
}
check();

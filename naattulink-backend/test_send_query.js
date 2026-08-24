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

async function testQuery(identifier) {
  const phoneWithPrefix = identifier.startsWith('+91') ? identifier : '+91' + identifier.replace(/^91/, '');
  const rawPhone = phoneWithPrefix.replace('+91', '');
  console.log('Searching for:', [rawPhone, phoneWithPrefix]);
  const querySnapshot = await db.collection('users')
      .where('phone', 'in', [rawPhone, phoneWithPrefix])
      .limit(1).get();
  console.log('Result empty?', querySnapshot.empty);
  if (!querySnapshot.empty) {
    console.log('Found UID:', querySnapshot.docs[0].id);
  }
}

testQuery('9207564536');

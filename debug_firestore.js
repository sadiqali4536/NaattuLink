const admin = require('firebase-admin');
let serviceAccount;
if (process.env.FIREBASE_ADMIN_KEY_BASE64) {
  const decodedKey = Buffer.from(process.env.FIREBASE_ADMIN_KEY_BASE64, 'base64').toString('utf8');
  serviceAccount = JSON.parse(decodedKey);
} else {
  serviceAccount = require('./naattulink-backend/firebase-admin-key.json');
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();

async function check() {
  const otps = await db.collection('otp_requests').orderBy('createdAt', 'desc').limit(5).get();
  console.log('=== LATEST 5 OTP REQUESTS ===');
  otps.forEach(doc => {
    console.log(doc.id, '->', doc.data().identifier, '| uid:', doc.data().uid);
  });
  
  if (!otps.empty) {
    const latestUid = otps.docs[0].data().uid;
    console.log('\n=== LOOKING UP UID:', latestUid, '===');
    const u = await db.collection('users').doc(latestUid).get();
    if (u.exists) console.log('Found in users:', u.data().phone, 'Role:', u.data().role);
    
    const w = await db.collection('workers').doc(latestUid).get();
    if (w.exists) console.log('Found in workers:', w.data().phone, 'Role:', w.data().role, 'isVerified:', w.data().isVerified);
  }
}
check();

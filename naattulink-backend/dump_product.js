const admin = require('firebase-admin');
try {
    const serviceAccount = require('./firebase-admin-key.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) { }

async function dump() {
    const db = admin.firestore();
    const snap = await db.collection('store_products').limit(1).get();
    if (!snap.empty) {
        console.log(snap.docs[0].data());
    } else {
        console.log("No products found.");
    }
}
dump();

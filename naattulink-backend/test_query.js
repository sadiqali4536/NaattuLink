const admin = require('firebase-admin');
try {
    const serviceAccount = require('./firebase-admin-key.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) { }

async function test() {
    const db = admin.firestore();
    try {
        await db.collection('imagekit_providers')
            .where('storageType', '==', 'seller_product')
            .where('enabled', '==', true)
            .orderBy('priority')
            .get();
        console.log("Query succeeded! (Index exists)");
    } catch (e) {
        console.error("ERROR: ", e.message);
    }
}
test();

const admin = require('firebase-admin');

try {
    const serviceAccount = require('./firebase-admin-key.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) {
    console.error(e);
}

async function dump() {
    try {
        const db = admin.firestore();
        const snapshot = await db.collection('imagekit_providers').get();
        if (snapshot.empty) {
            console.log("No providers found in imagekit_providers collection.");
        } else {
            snapshot.docs.forEach(doc => {
                console.log(doc.id, "=>", doc.data());
            });
        }
    } catch (e) {
        console.error(e);
    }
}
dump();

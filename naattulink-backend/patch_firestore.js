const admin = require('firebase-admin');

try {
    const serviceAccount = require('./firebase-admin-key.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
} catch (e) {
    console.error("Firebase init error:", e);
}

async function patch() {
    const db = admin.firestore();
    const batch = db.batch();

    // Add storageType: 'seller_product' to seller accounts
    batch.update(db.collection('imagekit_providers').doc('imagekit_seller_account_1'), {
        storageType: 'seller_product'
    });
    batch.update(db.collection('imagekit_providers').doc('imagekit_seller_account_2'), {
        storageType: 'seller_product'
    });

    // Add storageType: 'workers' to workers account
    batch.update(db.collection('imagekit_providers').doc('imagekit_workers'), {
        storageType: 'workers'
    });

    // Add storageType: 'banners' to banners account
    batch.update(db.collection('imagekit_providers').doc('imagekit_banners'), {
        storageType: 'banners'
    });

    try {
        await batch.commit();
        console.log("Successfully patched Firestore documents with storageType fields!");
    } catch (e) {
        console.error("Error patching Firestore:", e);
    }
}
patch();

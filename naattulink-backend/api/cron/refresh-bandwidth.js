const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    try {
        const serviceAccount = require('../../firebase-admin-key.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (error) {
        if (process.env.FIREBASE_SERVICE_ACCOUNT) {
            admin.initializeApp({
                credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
            });
        }
    }
}

module.exports = async (req, res) => {
    // Vercel Cron Security: If you have a CRON_SECRET set in your Vercel Environment Variables, this verifies it.
    const authHeader = req.headers.authorization;
    if (process.env.CRON_SECRET && authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
        return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    try {
        const db = admin.firestore();
        const snapshot = await db.collection('imagekit_providers').get();

        if (snapshot.empty) {
            return res.status(200).json({ success: true, message: 'No providers found.' });
        }

        const batch = db.batch();
        let updatedCount = 0;

        snapshot.docs.forEach((doc) => {
            batch.update(doc.ref, {
                bandwidthUsed: 0,
                enabled: true
            });
            updatedCount++;
        });

        await batch.commit();

        console.log(`Successfully reset bandwidth and enabled ${updatedCount} providers.`);
        
        return res.status(200).json({
            success: true,
            message: `Successfully reset bandwidth and enabled ${updatedCount} providers.`
        });
    } catch (error) {
        console.error('Error refreshing bandwidth:', error);
        return res.status(500).json({ success: false, error: error.message });
    }
};

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
const COLLECTION_NAME = 'imagekit_providers';

// Configurable threshold for marking a provider UNHEALTHY
const FAILURE_THRESHOLD = 5;

// Cooldown period in milliseconds (e.g., 5 minutes)
const COOLDOWN_PERIOD_MS = 5 * 60 * 1000;

class HealthManager {
  /**
   * Reports a failure for a specific provider.
   * Increments consecutiveFailures. If threshold is reached, marks as UNHEALTHY.
   * @param {string} providerId
   * @param {string} errorMessage
   */
  static async reportProviderFailure(providerId, errorMessage) {
    try {
      const docRef = db.collection(COLLECTION_NAME).doc(providerId);
      
      await db.runTransaction(async (transaction) => {
        const doc = await transaction.get(docRef);
        if (!doc.exists) return;
        
        const data = doc.data();
        let newConsecutiveFailures = (data.consecutiveFailures || 0) + 1;
        let newStatus = data.status;

        if (newConsecutiveFailures >= FAILURE_THRESHOLD && data.status === 'HEALTHY') {
          newStatus = 'UNHEALTHY';
        }

        transaction.update(docRef, {
          consecutiveFailures: newConsecutiveFailures,
          status: newStatus,
          lastError: errorMessage,
          lastErrorAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });
    } catch (error) {
      console.error(`Error reporting failure for provider ${providerId}:`, error);
    }
  }

  /**
   * Reports a successful operation for a provider.
   * Resets consecutiveFailures to 0 and restores HEALTHY status if it was UNHEALTHY.
   * @param {string} providerId
   */
  static async reportProviderSuccess(providerId) {
    try {
      const docRef = db.collection(COLLECTION_NAME).doc(providerId);
      
      await docRef.update({
        consecutiveFailures: 0,
        status: 'HEALTHY',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      console.error(`Error reporting success for provider ${providerId}:`, error);
    }
  }

  /**
   * Checks if an UNHEALTHY provider is ready for a recovery check based on the cooldown period.
   * @param {Object} providerData
   * @returns {boolean}
   */
  static isReadyForRecovery(providerData) {
    if (providerData.status !== 'UNHEALTHY' || !providerData.lastErrorAt) {
      return false;
    }
    
    const lastErrorTime = providerData.lastErrorAt.toDate().getTime();
    const now = Date.now();
    
    return (now - lastErrorTime) >= COOLDOWN_PERIOD_MS;
  }
}

module.exports = HealthManager;

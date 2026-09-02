const admin = require('firebase-admin');
const HealthManager = require('./healthManager');
const UsageTracker = require('./usageTracker');

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

class ProviderSelector {
  /**
   * Retrieves all enabled and healthy providers, resetting usage months if needed,
   * filtering out providers that have reached their monthly limit, and sorting by priority.
   * Also includes UNHEALTHY providers that are ready for recovery.
   * @returns {Promise<Array>}
   */
  static async getAvailableProviders() {
    try {
      const snapshot = await db.collection(COLLECTION_NAME).where('enabled', '==', true).get();
      
      if (snapshot.empty) {
        return [];
      }

      const providers = [];
      const currentMonth = UsageTracker.getCurrentMonth();

      for (const doc of snapshot.docs) {
        let data = doc.data();
        
        // 1. Reset monthly usage if needed
        const didReset = await UsageTracker._checkAndResetMonth(doc.ref, data, currentMonth);
        if (didReset) {
          // Re-fetch data if it was reset
          const updatedDoc = await doc.ref.get();
          data = updatedDoc.data();
        }

        // 2. Check limits
        const isLimitReached = data.usedThisMonth >= data.monthlyLimit;

        // 3. Check health
        let isHealthy = data.status === 'HEALTHY';
        if (!isHealthy) {
          // If unhealthy but ready for recovery, allow it to be tried
          if (HealthManager.isReadyForRecovery(data)) {
            isHealthy = true;
          }
        }

        if (!isLimitReached && isHealthy) {
          providers.push({
            id: doc.id,
            ...data
          });
        }
      }

      // Sort by priority ASC (lower number = higher priority)
      providers.sort((a, b) => a.priority - b.priority);

      return providers;
    } catch (error) {
      console.error("Error getting available providers:", error);
      return [];
    }
  }

  /**
   * Selects the highest priority provider.
   * @returns {Promise<Object|null>} The selected provider document data, or null if none available.
   */
  static async selectProvider() {
    const providers = await this.getAvailableProviders();
    
    if (providers.length === 0) {
      return null;
    }

    // Return the highest priority provider (first in the sorted list)
    return providers[0];
  }
}

module.exports = ProviderSelector;

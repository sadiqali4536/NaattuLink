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

class UsageTracker {
  /**
   * Generates the current month string in YYYY-MM format.
   * @returns {string}
   */
  static getCurrentMonth() {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
  }

  /**
   * Resets usage for a provider if the month has changed.
   * @param {admin.firestore.DocumentReference} docRef
   * @param {Object} data
   * @param {string} currentMonth
   * @returns {Promise<boolean>} True if it was reset, false otherwise
   */
  static async _checkAndResetMonth(docRef, data, currentMonth) {
    if (data.usageMonth !== currentMonth) {
      await docRef.update({
        usageMonth: currentMonth,
        usedThisMonth: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      return true;
    }
    return false;
  }

  /**
   * Ensures the provider's month is correct and gets current data.
   * @param {string} providerId
   */
  static async ensureCurrentMonth(providerId) {
    const docRef = db.collection(COLLECTION_NAME).doc(providerId);
    const doc = await docRef.get();
    
    if (!doc.exists) return null;
    
    const data = doc.data();
    const currentMonth = this.getCurrentMonth();
    
    const didReset = await this._checkAndResetMonth(docRef, data, currentMonth);
    
    if (didReset) {
      const updatedDoc = await docRef.get();
      return updatedDoc.data();
    }
    
    return data;
  }

  /**
   * Safely increments successful uploads.
   * @param {string} providerId
   */
  static async recordSuccess(providerId) {
    const docRef = db.collection(COLLECTION_NAME).doc(providerId);
    
    // Check if month needs reset before incrementing to avoid adding to old month
    await this.ensureCurrentMonth(providerId);

    await docRef.update({
      usedThisMonth: admin.firestore.FieldValue.increment(1),
      successfulUploads: admin.firestore.FieldValue.increment(1),
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  /**
   * Safely increments failed uploads.
   * @param {string} providerId
   * @param {string} errorMessage
   */
  static async recordFailure(providerId, errorMessage) {
    const docRef = db.collection(COLLECTION_NAME).doc(providerId);
    
    await docRef.update({
      failedUploads: admin.firestore.FieldValue.increment(1),
      lastError: errorMessage,
      lastErrorAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
}

module.exports = UsageTracker;

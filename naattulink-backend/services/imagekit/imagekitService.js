const ImageKit = require('imagekit');
const ProviderSelector = require('./providerSelector');
const HealthManager = require('./healthManager');
const UsageTracker = require('./usageTracker');
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

class ImageKitService {
  /**
   * Initializes an ImageKit instance for a given provider configuration.
   * Resolves the secretName to an environment variable.
   * @param {Object} providerData 
   * @returns {ImageKit|null}
   */
  static _initImageKit(providerData) {
    // 1. Try to get privateKey directly from Firestore document (if stored securely in Firebase)
    // 2. Fallback to getting it from Vercel environment variables using secretName
    const privateKey = providerData.privateKey || process.env[providerData.secretName];

    if (!privateKey) {
      console.error(`Missing private key for provider: ${providerData.name}`);
      return null;
    }

    return new ImageKit({
      publicKey: providerData.publicKey,
      privateKey: privateKey,
      urlEndpoint: providerData.urlEndpoint
    });
  }

  /**
   * Identifies if an error is a provider/API error (affects health) or a client error.
   * @param {Object} error 
   * @returns {boolean} true if provider-level error
   */
  static _isProviderError(error) {
    // Determine based on HTTP status code or error message from ImageKit
    if (error && error.statusCode) {
      const status = error.statusCode;
      // 401 Unauthorized, 403 Forbidden, 5xx Server Errors
      if (status === 401 || status === 403 || status >= 500) {
        return true;
      }
      // 400 Bad Request, 404 Not Found usually means client error
      return false;
    }
    // Network errors (no status code) are provider-level (e.g. timeout)
    return true;
  }

  /**
   * Attempts to upload a file, automatically falling back to other providers if needed.
   * @param {Buffer|String} file 
   * @param {String} fileName 
   * @param {String} folder 
   * @returns {Promise<Object>} The upload result
   */
  static async uploadWithFallback(file, fileName, folder) {
    let providers = await ProviderSelector.getAvailableProviders();

    if (providers.length === 0) {
      throw new Error("ALL_PROVIDERS_UNAVAILABLE");
    }

    for (let i = 0; i < providers.length; i++) {
      const provider = providers[i];
      const imagekit = this._initImageKit(provider);

      if (!imagekit) {
        // Misconfigured provider (missing private key) -> mark failure and try next
        await HealthManager.reportProviderFailure(provider.id, "Missing private key in environment variables");
        continue;
      }

      try {
        const response = await imagekit.upload({
          file: file,
          fileName: fileName,
          folder: folder
        });

        // Upload successful
        await UsageTracker.recordSuccess(provider.id);
        await HealthManager.reportProviderSuccess(provider.id);

        return {
          success: true,
          url: response.url,
          fileId: response.fileId,
          filePath: response.filePath,
          providerId: provider.id,
          storageType: 'imagekit'
        };

      } catch (error) {
        console.error(`Upload failed for provider ${provider.id}:`, error.message);

        if (this._isProviderError(error)) {
          // Provider-level error, report failure and try next provider
          await HealthManager.reportProviderFailure(provider.id, error.message || JSON.stringify(error));
          await UsageTracker.recordFailure(provider.id, error.message || JSON.stringify(error));
        } else {
          // Client-level error (e.g. invalid image format). Do not fallback.
          throw new Error(`CLIENT_ERROR: ${error.message || JSON.stringify(error)}`);
        }
      }
    }

    throw new Error("ALL_PROVIDERS_UNAVAILABLE");
  }

  /**
   * Deletes a file using the original provider it was uploaded to.
   * @param {String} fileId 
   * @param {String} providerId 
   */
  static async deleteFile(fileId, providerId) {
    if (!providerId) {
      throw new Error("providerId is required for deletion");
    }

    const doc = await db.collection('imagekit_providers').doc(providerId).get();
    if (!doc.exists) {
      throw new Error("Provider not found");
    }

    const providerData = doc.data();
    const imagekit = this._initImageKit(providerData);

    if (!imagekit) {
      throw new Error("PROVIDER_MISCONFIGURED: Missing private key");
    }

    try {
      await imagekit.deleteFile(fileId);
      return { success: true };
    } catch (error) {
      console.error(`Delete failed for provider ${providerId}:`, error);
      throw new Error(error.message || "Delete failed");
    }
  }

  /**
   * Tests a provider's connection and credentials.
   * @param {Object} providerData 
   * @returns {Promise<Object>}
   */
  static async testConnection(providerData) {
    const imagekit = this._initImageKit(providerData);
    if (!imagekit) {
      return { success: false, message: "Missing private key in environment variables." };
    }

    try {
      // Test by making a simple request, like listing files with limit 1
      await imagekit.listFiles({
        skip: 0,
        limit: 1
      });
      return { success: true, message: "Connection successful." };
    } catch (error) {
      return { success: false, message: error.message || "Connection failed." };
    }
  }
}

module.exports = ImageKitService;

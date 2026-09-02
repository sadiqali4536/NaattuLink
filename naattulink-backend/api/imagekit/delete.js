const ImageKitService = require('../../services/imagekit/imagekitService');
const { authenticateUser } = require('./utils');
const cors = require('cors')({ origin: true });

const runMiddleware = (req, res, fn) => {
  return new Promise((resolve, reject) => {
    fn(req, res, (result) => {
      if (result instanceof Error) return reject(result);
      return resolve(result);
    });
  });
};

module.exports = async (req, res) => {
  await runMiddleware(req, res, cors);

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method Not Allowed' });
  }

  try {
    // 1. Authenticate user
    await authenticateUser(req);

    const { fileId, providerId, storageType } = req.body;

    if (!fileId) {
      return res.status(400).json({ success: false, message: 'Missing fileId' });
    }

    let finalProviderId = providerId;

    if (!finalProviderId) {
      if (!storageType) {
        return res.status(400).json({ success: false, message: 'Missing providerId and storageType' });
      }
      // Dynamically map legacy storageTypes (e.g., 'banners') to provider IDs (e.g., 'imagekit_banners')
      // This allows creating new types in the future without modifying this file.
      finalProviderId = `imagekit_${storageType}`;
    }

    // If they passed something other than imagekit (e.g. firebase_storage) and it's not our internal prefix
    // we allow it to pass through to the provider check. The ImageKitService will validate existence.
    if (storageType === 'firebase_storage') {
      return res.status(400).json({ success: false, message: 'Unsupported storageType for this endpoint' });
    }

    // 2. Delete file using the EXACT provider it was uploaded to
    const result = await ImageKitService.deleteFile(fileId, finalProviderId);

    return res.status(200).json(result);

  } catch (error) {
    console.error("ImageKit Delete Error:", error);

    if (error.message.startsWith('UNAUTHORIZED')) {
      return res.status(401).json({ success: false, message: error.message });
    }

    if (error.message.startsWith('PROVIDER_MISCONFIGURED')) {
      return res.status(500).json({ success: false, message: error.message });
    }

    return res.status(500).json({ success: false, message: error.message || 'Internal Server Error' });
  }
};

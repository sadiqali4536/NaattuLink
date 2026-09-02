const ImageKitService = require('../../services/imagekit/imagekitService');
const { authenticateUser } = require('./utils');
const multer = require('multer');

// Configure multer to store file in memory
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10 MB limit
  }
});

// Middleware wrapper for Next.js/Vercel
const runMiddleware = (req, res, fn) => {
  return new Promise((resolve, reject) => {
    fn(req, res, (result) => {
      if (result instanceof Error) {
        return reject(result);
      }
      return resolve(result);
    });
  });
};

// We need to disable the default body parser in Vercel to allow multer to parse the multipart data
export const config = {
  api: {
    bodyParser: false,
  },
};

module.exports = async (req, res) => {
  // Setup CORS if needed here (assuming global config or similar, but adding basic headers just in case)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, message: 'Method Not Allowed' });
  }

  try {
    // 1. Authenticate the user
    await authenticateUser(req);

    // 2. Parse the multipart/form-data
    await runMiddleware(req, res, upload.single('image'));

    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No image file provided' });
    }

    const { fileName, folder, storageType } = req.body;
    const finalFileName = fileName || req.file.originalname;
    const finalFolder = folder || '/uploads';

    // 3. Upload with fallback
    const result = await ImageKitService.uploadWithFallback(
      req.file.buffer,
      finalFileName,
      finalFolder
    );

    // 4. Return standard result
    return res.status(200).json(result);

  } catch (error) {
    console.error("ImageKit Upload Error:", error);
    
    // Check if it's our custom ALL_PROVIDERS_UNAVAILABLE error
    if (error.message === 'ALL_PROVIDERS_UNAVAILABLE') {
      return res.status(503).json({
        success: false,
        errorCode: 'ALL_PROVIDERS_UNAVAILABLE',
        message: 'Image upload is temporarily unavailable. All storage providers are exhausted or down.'
      });
    }

    if (error.message.startsWith('UNAUTHORIZED')) {
      return res.status(401).json({ success: false, message: error.message });
    }
    
    if (error.message.startsWith('CLIENT_ERROR')) {
      return res.status(400).json({ success: false, message: error.message });
    }

    return res.status(500).json({
      success: false,
      message: 'Internal Server Error'
    });
  }
};

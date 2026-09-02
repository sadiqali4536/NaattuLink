class ImageKitConstants {
  // Point to the live Vercel backend
  static const String backendBaseUrl = 'https://naattulink-backend.vercel.app';

  static const String uploadEndpoint = '$backendBaseUrl/api/imagekit/upload';
  static const String deleteEndpoint = '$backendBaseUrl/api/imagekit/delete';

  static const String storageType = 'imagekit';
}

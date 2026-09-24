class ImageKitConstants {
  // Point to the live Vercel backend
  static const String backendBaseUrl =
      'https://naattulink-backend-sadiqalis-projects.vercel.app';

  static const String authEndpoint = '$backendBaseUrl/api/imagekit/auth';
  static const String uploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  static const String deleteEndpoint =
      '$backendBaseUrl/api/imagekit/deleteImage';
}

class ImageKitUploadResult {
  final String imageUrl;
  final String imageFileId;
  final String providerId; // Added for the new backend system

  const ImageKitUploadResult({
    required this.imageUrl,
    required this.imageFileId,
    this.providerId = '',
  });

  factory ImageKitUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageKitUploadResult(
      imageUrl: json['url'] as String? ?? '',
      imageFileId: json['fileId'] as String? ?? '',
      providerId: json['providerId'] as String? ?? '',
    );
  }
}

class ImageKitConfig {
  final String storageType;
  final String publicKey;
  final String privateKey;
  final String urlEndpoint;
  final String defaultFolder;
  final String accountName;

  const ImageKitConfig({
    required this.storageType,
    required this.publicKey,
    this.privateKey = '',
    required this.urlEndpoint,
    required this.defaultFolder,
    required this.accountName,
  });
}

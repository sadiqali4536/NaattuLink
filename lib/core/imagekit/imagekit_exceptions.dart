class ImageKitException implements Exception {
  final String message;
  const ImageKitException(this.message);

  @override
  String toString() => 'ImageKitException: $message';
}

class ImageKitUploadException extends ImageKitException {
  const ImageKitUploadException(super.message);
  
  @override
  String toString() => 'ImageKitUploadException: $message';
}

class ImageKitDeleteException extends ImageKitException {
  const ImageKitDeleteException(super.message);
  
  @override
  String toString() => 'ImageKitDeleteException: $message';
}

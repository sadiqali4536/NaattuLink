import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImagePreprocessor {
  static Future<String?> compressAndPreprocess(
    String originalPath,
  ) async {
    try {
      final extension =
          originalPath.toLowerCase().split('.').last;

      // Screenshots are often PNG/WebP.
      // Keep them lossless for OCR.
      if (extension == 'png' ||
          extension == 'webp') {
        return originalPath;
      }

      final tempDir = await getTemporaryDirectory();

      final targetPath =
          '${tempDir.path}/ocr_prep_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        quality: 92,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );

      return compressedFile?.path ?? originalPath;
    } catch (e) {
      debugPrint('OCR preprocess error: $e');
      return originalPath;
    }
  }
}

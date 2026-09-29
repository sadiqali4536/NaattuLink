import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

import 'image_preprocessor.dart';
import '../parser/payment_parser.dart';
import '../models/payment_ocr_result.dart';

class PaymentOcrService {
  static Future<PaymentOcrResult?> extractPaymentReceipt({
    double? expectedAmount,
    String? expectedUpiId,
  }) async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return null;

    final processedPath =
        await ImagePreprocessor.compressAndPreprocess(image.path) ??
            image.path;

    final inputImage = InputImage.fromFilePath(processedPath);

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      debugPrint(
        '[OCR] Blocks detected: ${recognizedText.blocks.length}',
      );

      debugPrint(
        '[OCR] Raw text length: ${recognizedText.text.length}',
      );

      return PaymentParser.parse(
        recognizedText,
        expectedAmount: expectedAmount,
        expectedUpiId: expectedUpiId,
      );
    } catch (e) {
      debugPrint('[OCR] Error: $e');
      return null;
    } finally {
      await textRecognizer.close();
    }
  }
}

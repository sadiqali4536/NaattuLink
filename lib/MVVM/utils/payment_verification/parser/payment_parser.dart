import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/payment_ocr_result.dart';
import 'spatial_payment_extractor.dart';

class PaymentParser {
  static PaymentOcrResult parse(
    RecognizedText recognizedText, {
    double? expectedAmount,
    String? expectedUpiId,
  }) {
    final result = SpatialPaymentExtractor.extract(
      recognizedText,
      expectedAmount: expectedAmount,
      expectedUpiId: expectedUpiId,
    );

    return result;
  }
}

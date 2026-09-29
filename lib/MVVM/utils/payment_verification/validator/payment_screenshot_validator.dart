import 'package:flutter/foundation.dart';
import '../models/payment_ocr_result.dart';
import '../models/payment_validation_result.dart';

class PaymentScreenshotValidator {
  static PaymentValidationResult validate({
    required PaymentOcrResult ocrResult,
    required double expectedAmount,
    required DateTime qrGeneratedAt,
    required DateTime qrExpiresAt,
    required String? expectedUpiId,
  }) {
    List<PaymentValidationReason> reasons = [];

    debugPrint('\n=============================================');
    debugPrint('[VALIDATION] Expected Amount: $expectedAmount');
    debugPrint('[VALIDATION] Extracted Amount: ${ocrResult.amount}');
    debugPrint('[VALIDATION] OCR Raw Text Length: ${ocrResult.rawText.length}');
    debugPrint('=============================================\n');

    bool amountMatches = false;

    // --- 1. AMOUNT EVIDENCE (Only Strict Check) ---
    if (ocrResult.amount != null) {
      final amountDifference = (ocrResult.amount! - expectedAmount).abs();
      // Extremely permissive tolerance to allow for 0.99 vs 1.00, or minor OCR float issues.
      if (amountDifference <= 1.0) {
        amountMatches = true;
      }
    }

    // FALLBACK: If the spatial extractor missed it, let's just check the raw text for the expected amount.
    if (!amountMatches) {
      String expectedStr0 = expectedAmount.toStringAsFixed(0);
      String expectedStr2 = expectedAmount.toStringAsFixed(2);

      String rawText = ocrResult.rawText.toLowerCase();

      // Look for the exact number with loose boundaries or prefixed by common OCR errors (7, ?, I, l)
      if (rawText.contains('₹$expectedStr0') ||
          rawText.contains('₹$expectedStr2') ||
          rawText.contains('rs$expectedStr0') ||
          rawText.contains('7$expectedStr0') ||
          rawText.contains('7$expectedStr2') ||
          rawText.contains(' $expectedStr0 ') ||
          rawText.contains(' $expectedStr2 ')) {
        amountMatches = true;
        debugPrint('[VALIDATION] Amount matched using raw text fallback!');
      }
    }

    if (!amountMatches) {
      if (ocrResult.amount == null) {
        reasons.add(PaymentValidationReason.amountNotFound);
      } else {
        reasons.add(PaymentValidationReason.amountMismatch);
      }
    }

    // Optional fields (we log them in reasons for UI/debug but they do not fail validation)
    if (ocrResult.paymentDateTime == null) {
      reasons.add(PaymentValidationReason.timeNotFound);
    }

    if (ocrResult.transactionIds.isEmpty && ocrResult.referenceIds.isEmpty) {
      reasons.add(PaymentValidationReason.transactionIdNotFound);
    }

    if (!ocrResult.hasSuccessIndicator) {
      reasons.add(PaymentValidationReason.successEvidenceNotFound);
    }

    // --- FINAL VALIDATION DECISION ---

    if (!amountMatches) {
      return PaymentValidationResult(
          status: PaymentVerificationStatus.invalid, reasons: reasons);
    }

    // If the amount matches, we accept the screenshot and extract whatever other data is available.
    return PaymentValidationResult(
        status: PaymentVerificationStatus.valid, reasons: reasons);
  }
}

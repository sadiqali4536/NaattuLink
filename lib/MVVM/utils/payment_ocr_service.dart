import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class PaymentOcrService {
  /// Prompts the user to select an image from the gallery, performs OCR,
  /// and attempts to extract a Transaction ID based on common labels or a 12-digit numeric fallback.
  /// Returns the extracted Transaction ID or null if none could be found or if canceled.
  static Future<String?> extractTransactionId() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    // User canceled the picker
    if (image == null) return null;

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;

      // 1. Label-aware extraction
      final List<String> labels = [
        'Transaction ID',
        'Transaction Id',
        'Txn ID',
        'Txn Id',
        'UPI Ref No',
        'Reference Number',
        'UTR',
        'RRN',
      ];

      for (String label in labels) {
        // Regex looks for the label, followed by optional spaces, colons, or dashes,
        // then captures the next continuous alphanumeric string of 8 to 22 characters.
        final RegExp regex = RegExp(
          '${RegExp.escape(label)}[\\s:-]*([a-zA-Z0-9]{8,22})',
          caseSensitive: false,
        );
        
        final match = regex.firstMatch(fullText);
        if (match != null && match.groupCount >= 1) {
          String? extracted = match.group(1);
          if (extracted != null && extracted.trim().isNotEmpty) {
            return extracted.trim();
          }
        }
      }

      // 2. Fallback: Search for any 12-digit number (standard UPI format)
      final RegExp fallbackRegex = RegExp(r'\b\d{12}\b');
      final fallbackMatch = fallbackRegex.firstMatch(fullText);
      if (fallbackMatch != null) {
        return fallbackMatch.group(0)?.trim();
      }

      return null;
    } catch (e) {
      debugPrint("OCR Error: $e");
      return null;
    } finally {
      // Release resources
      textRecognizer.close();
      // The image file remains locally on the device or in temporary cache,
      // and is never uploaded to any remote server (Firebase, ImageKit, etc).
    }
  }
}

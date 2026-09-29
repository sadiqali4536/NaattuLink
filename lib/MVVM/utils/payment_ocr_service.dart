import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:naattulink/MVVM/utils/payment_verification/ocr/payment_ocr_service.dart'
    as modern_ocr;

class PaymentReceiptData {
  final String? payerName;
  final String? payerPhone;
  final String? payerBank;
  final String? payerUpi;
  final String? receiverName;
  final String? receiverBank;
  final String? receiverAccount;
  final String? receiverUpi;
  final double? amount;
  final String? paymentReference;
  final String? upiTransactionId;
  final String? googleTransactionId;
  final String? transactionDate;
  final String? transactionTime;
  final String? status;
  final String? qrNoteDate;
  final String? qrNoteTime;

  PaymentReceiptData({
    this.payerName,
    this.payerPhone,
    this.payerBank,
    this.payerUpi,
    this.receiverName,
    this.receiverBank,
    this.receiverAccount,
    this.receiverUpi,
    this.amount,
    this.paymentReference,
    this.upiTransactionId,
    this.googleTransactionId,
    this.transactionDate,
    this.transactionTime,
    this.status,
    this.qrNoteDate,
    this.qrNoteTime,
  });
}

class PaymentOcrService {
  static Future<PaymentReceiptData?> extractPaymentReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    String targetPath = image.path;
    try {
      final tempDir = await getTemporaryDirectory();
      final compressPath =
          '\${tempDir.path}/ocr3_\${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        compressPath,
        quality: 60,
        minWidth: 1000,
        minHeight: 1000,
      );
      if (compressedFile != null) targetPath = compressedFile.path;
    } catch (e) {
      debugPrint("OCR Compress Error: \$e");
    }

    final inputImage = InputImage.fromFilePath(targetPath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;

      debugPrint('========== RAW OCR TEXT START ==========');
      debugPrint(fullText);
      debugPrint('========== RAW OCR TEXT END ==========');

      String? upiTxnId;
      String? googleTxnId;
      String? amountStr;
      String? date;
      String? time;
      String? status;
      String? payerName;
      String? payerPhone;
      String? payerBank;
      String? payerUpi;
      String? receiverName;
      String? receiverBank;
      String? receiverUpi;
      String? paymentRef;
      String? qrNoteDate;
      String? qrNoteTime;

      String? extractTxnIdLocal() {
        final lines = fullText.split('\n');

        bool isUpiLabel(String line) {
          final l = line.toLowerCase();
          if (l.contains('upi') &&
              l.contains('transaction') &&
              l.contains('id')) return true;
          if (l.contains('upi') && l.contains('reference') && l.contains('id'))
            return true;
          if (l.contains('upi') && l.contains('ref') && l.contains('id'))
            return true;
          if (l.contains('utr')) return true;
          if (l.contains('upi ref no')) return true;
          if (l.contains('ref id') || l.contains('refid')) return true;
          if (l.contains('transaction id')) return true;
          return false;
        }

        for (int i = 0; i < lines.length; i++) {
          if (isUpiLabel(lines[i])) {
            final inlineMatch =
                RegExp(r'(T\d{22}|\d{12,20})', caseSensitive: false)
                    .firstMatch(lines[i]);
            if (inlineMatch != null &&
                isValidUpiTransactionId(inlineMatch.group(1)))
              return inlineMatch.group(1);
            for (int j = 1; j <= 4; j++) {
              if (i + j < lines.length) {
                final nextMatch =
                    RegExp(r'(T\d{22}|\d{12,20})', caseSensitive: false)
                        .firstMatch(lines[i + j]);
                if (nextMatch != null &&
                    isValidUpiTransactionId(nextMatch.group(1)))
                  return nextMatch.group(1);
              }
              if (i - j >= 0) {
                final prevMatch =
                    RegExp(r'(T\d{22}|\d{12,20})', caseSensitive: false)
                        .firstMatch(lines[i - j]);
                if (prevMatch != null &&
                    isValidUpiTransactionId(prevMatch.group(1)))
                  return prevMatch.group(1);
              }
            }
          }
        }

        // Final fallback: look for exactly 12 digits anywhere
        final fallback =
            RegExp(r'(?<!\d)(?:\d[\s\n]*){12}(?!\d)').firstMatch(fullText);
        if (fallback != null)
          return fallback.group(0)?.replaceAll(RegExp(r'\s+'), '');

        return null;
      }

      upiTxnId = extractTxnIdLocal();

      final lines = fullText
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final RegExp amountRegex = RegExp(
          r'(?:₹|rs\.?|inr|paid|sent|amount)\s*[^0-9a-zA-Z]*([0-9,]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false);
      for (final line in lines) {
        final match = amountRegex.firstMatch(line);
        if (match != null) {
          amountStr = match.group(1);
          break;
        }
      }

      if (amountStr == null) {
        // Fallback: look for a line that is primarily a number, ignoring non-alphanumeric prefixes
        final fallbackRegex =
            RegExp(r'^[^0-9a-zA-Z]*([0-9,]+(?:\.[0-9]{1,2})?)\s*$');
        for (final line in lines) {
          final match = fallbackRegex.firstMatch(line);
          if (match != null) {
            final val = match.group(1)!;
            // Ensure it's not a UPI ID length (usually 12 digits) or a year
            if (val.length < 8 &&
                val != '2023' &&
                val != '2024' &&
                val != '2025' &&
                val != '2026') {
              amountStr = val;
              break;
            }
          }
        }
      }

      // Second fallback: look for ANY number with a decimal point (very likely an amount)
      if (amountStr == null) {
        for (final line in lines) {
          if (!line.toLowerCase().contains('transaction') &&
              !line.toLowerCase().contains('id')) {
            final match =
                RegExp(r'(?:^|\s)([0-9,]+\.[0-9]{2})(?:\s|$)').firstMatch(line);
            if (match != null) {
              amountStr = match.group(1)!;
              break;
            }
          }
        }
      }

      final dateRegex = RegExp(
          r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})\b',
          caseSensitive: false);
      final timeRegex = RegExp(
          r'\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])(?::([0-5][0-9]))?\s*([aApP][mM])\b',
          caseSensitive: false);

      for (int i = 0; i < lines.length; i++) {
        final lineLower = lines[i].toLowerCase();

        if (lineLower.contains('completed') ||
            lineLower.contains('success') ||
            lineLower.contains('successful')) {
          status = 'Completed';
        }

        // Super.money app uses a green checkmark instead of text
        if (lineLower.contains('super') ||
            lineLower.contains('cashback') ||
            lineLower.contains('gifts') ||
            lineLower.contains('unlock rewards') ||
            lineLower.contains('view details')) {
          status = 'Completed';
        }
        if (lineLower.contains('google transaction id')) {
          if (i + 1 < lines.length && lines[i + 1].contains('-'))
            googleTxnId = lines[i + 1];
          else if (i - 1 >= 0 && lines[i - 1].contains('-'))
            googleTxnId = lines[i - 1];
        }
        if (lineLower.startsWith('from:')) {
          payerName = lines[i].substring(5).trim();
          if (payerName!.isEmpty && i + 1 < lines.length)
            payerName = lines[i + 1];
        } else if (lineLower.startsWith('from ') && payerName == null) {
          payerName = lines[i].substring(5).trim();
        }
        if (lines[i].contains('+91') && lines[i].contains('•'))
          payerPhone = lines[i];

        if ((lineLower.contains('bank of') || lineLower.contains('bank')) &&
            !lineLower.contains('to:') &&
            !lineLower.contains('from:')) {
          if (payerName != null && receiverBank == null) {
            payerBank ??= lines[i];
          } else {
            receiverBank = lines[i];
          }
        }
        if (lineLower.startsWith('to:')) {
          receiverName = lines[i].substring(3).trim();
          if (receiverName!.isEmpty && i + 1 < lines.length)
            receiverName = lines[i + 1];
        } else if (lineLower.startsWith('to ') && receiverName == null) {
          final possibleName = lines[i].substring(3).trim();
          if (possibleName != '0' &&
              possibleName.length > 1 &&
              !possibleName.contains('unlock')) {
            receiverName = possibleName;
          }
        }
        final upiMatch =
            RegExp(r'[a-zA-Z0-9.\-_]+@[a-zA-Z]+').firstMatch(lineLower);
        if (upiMatch != null) {
          // If we see 'to' or the receiver is null, put in receiverUpi.
          if (lineLower.contains('to') || receiverUpi == null) {
            if (receiverUpi == null) {
              receiverUpi = upiMatch.group(0);
            } else {
              payerUpi = upiMatch.group(0);
            }
          } else {
            payerUpi = upiMatch.group(0);
          }
        }

        final noteRegex = RegExp(
            r'naattulink_[a-z_]*\s*\|\s*(\d{2}-\d{2}-\d{4})\s*(\d{1,2}:\d{2}:\d{2})(?:\s*(am|pm))?',
            caseSensitive: false);
        final noteMatch = noteRegex.firstMatch(fullText);
        if (noteMatch != null) {
          paymentRef = 'NaattuLink_Order';
          qrNoteDate = noteMatch.group(1);
          final timePart = noteMatch.group(2);
          final amPmPart = noteMatch.group(3);
          qrNoteTime = amPmPart != null
              ? '$timePart ${amPmPart.toUpperCase()}'
              : timePart;
        } else if (lineLower.contains('naattulink_')) {
          paymentRef = 'NaattuLink_Order';
        }

        final dateMatch = dateRegex.firstMatch(lines[i]);
        if (dateMatch != null) {
          date =
              '${dateMatch.group(1)} ${dateMatch.group(2)} ${dateMatch.group(3)}';
        }
        final timeMatch = timeRegex.firstMatch(lines[i]);
        if (timeMatch != null &&
            !lines[i].toLowerCase().contains('naattulink_')) {
          time = timeMatch.group(0);
        }
      }

      return PaymentReceiptData(
        payerName: payerName,
        payerPhone: payerPhone,
        payerBank: payerBank,
        payerUpi: payerUpi,
        receiverName: receiverName,
        receiverBank: receiverBank,
        receiverUpi: receiverUpi,
        amount: amountStr != null
            ? double.tryParse(amountStr.replaceAll(',', ''))
            : null,
        paymentReference: paymentRef,
        upiTransactionId: upiTxnId,
        googleTransactionId: googleTxnId,
        transactionDate: date,
        transactionTime: time,
        status: status,
        qrNoteDate: qrNoteDate,
        qrNoteTime: qrNoteTime,
      );
    } catch (e) {
      debugPrint("OCR Error: \$e");
      return null;
    } finally {
      await textRecognizer.close();
    }
  }

  static bool isValidUpiTransactionId(String? id) {
    if (id == null) return false;
    // Standard UPI transaction ID is usually 12 digits, but we accept 8-20 numeric digits as requested.
    // We also accept PhonePe transaction IDs which start with 'T' and have 22 digits.
    if (RegExp(r'^T\d{22}$', caseSensitive: false).hasMatch(id)) return true;
    return RegExp(r'^\d{8,20}$').hasMatch(id);
  }

  /// Prompts the user to select an image from the gallery, performs OCR,
  /// and attempts to extract a Transaction ID based on common labels or a 12-digit numeric fallback.
  /// Returns the extracted Transaction ID or null if none could be found or if canceled.
  static Future<String?> extractTransactionId() async {
    // We now route this legacy method to our new, powerful spatial engine.
    // This ensures that the full text data is properly extracted and analyzed spatially!

    final result = await modern_ocr.PaymentOcrService.extractPaymentReceipt();

    if (result == null) return null;

    if (result.transactionIds.isNotEmpty) {
      return result.transactionIds.first;
    }

    if (result.referenceIds.isNotEmpty) {
      return result.referenceIds.first;
    }

    // Fallback: Just return the first 12-digit number found in raw text if the spatial engine missed it
    final RegExp fallbackRegex = RegExp(r'(?<!\d)(?:\d[\s\n]*){12}(?!\d)');
    final fallbackMatch = fallbackRegex.firstMatch(result.rawText);
    if (fallbackMatch != null) {
      return fallbackMatch.group(0)?.replaceAll(RegExp(r'\s+'), '');
    }

    return null;
  }

  /// Prompts the user to select an image from the gallery, performs OCR,
  /// and attempts to extract a Transaction ID and payment time.
  static Future<Map<String, dynamic>?> extractPaymentDetails() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    // User canceled the picker
    if (image == null) return null;

    String targetPath = image.path;
    debugPrint('========== OCR IMAGE START ==========');
    debugPrint('ORIGINAL IMAGE PATH: ${image.path}');
    try {
      final tempDir = await getTemporaryDirectory();
      final compressPath =
          '${tempDir.path}/ocr2_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        compressPath,
        quality: 60,
        minWidth: 1000,
        minHeight: 1000,
      );
      if (compressedFile != null) {
        targetPath = compressedFile.path;
        debugPrint('COMPRESSED IMAGE PATH: $targetPath');
      }
    } catch (e) {
      debugPrint("OCR Compress Error: $e");
    }

    debugPrint('IMAGE ACTUALLY SENT TO ML KIT: $targetPath');
    debugPrint('================================');

    final inputImage = InputImage.fromFilePath(targetPath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    String? extractedTxnId;
    DateTime? extractedTime;
    double? extractedAmount;
    DateTime? fileTime;

    try {
      fileTime = await image.lastModified();
    } catch (e) {
      debugPrint("Could not get lastModified: $e");
    }

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;

      debugPrint('========== FULL OCR RESULT ==========');
      debugPrint(fullText);
      debugPrint('=====================================');

      // Helper function to extract ID based on line-by-line fallback
      String? fallbackLineByLineSearch(String text) {
        final lines = text.split('\n');
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].toLowerCase();
          if (line.contains('upi') &&
              line.contains('transaction') &&
              line.contains('id')) {
            final inlineMatch =
                RegExp(r'(T\d{22}|\d{8,20})', caseSensitive: false)
                    .firstMatch(line);
            if (inlineMatch != null &&
                isValidUpiTransactionId(inlineMatch.group(1))) {
              return inlineMatch.group(1);
            }
            for (int j = 1; j <= 3; j++) {
              if (i - j >= 0) {
                final prevLineMatch =
                    RegExp(r'(\d{8,20})').firstMatch(lines[i - j]);
                if (prevLineMatch != null &&
                    isValidUpiTransactionId(prevLineMatch.group(1))) {
                  return prevLineMatch.group(1);
                }
              }
              if (i + j < lines.length) {
                final nextLineMatch =
                    RegExp(r'(\d{8,20})').firstMatch(lines[i + j]);
                if (nextLineMatch != null &&
                    isValidUpiTransactionId(nextLineMatch.group(1))) {
                  return nextLineMatch.group(1);
                }
              }
            }
          }
        }
        return null;
      }

      // 1. Extract Transaction ID
      final List<String> labels = [
        'UPI transaction ID',
        'UPI Reference ID',
        'UPI Ref ID',
        'PhonePe Transaction ID',
        'Transaction ID',
        'Transaction Id',
        'Transaction No.',
        'Transaction No',
        'Txn ID',
        'Txn Id',
        'Txn No.',
        'Txn No',
        'UPI Ref No',
        'Ref ID',
        'RefID',
        'Ref No.',
        'Ref No',
        'Reference Number',
        'Reference No.',
        'Reference No',
        'Journal No.',
        'Journal No',
        'Journal Number',
        'UTR',
        'RRN',
      ];

      for (String label in labels) {
        final RegExp regex = RegExp(
          '${RegExp.escape(label)}[^a-zA-Z0-9]*([a-zA-Z0-9\\-]{8,35})',
          caseSensitive: false,
        );
        final match = regex.firstMatch(fullText);
        if (match != null && match.groupCount >= 1) {
          String? extracted = match.group(1);
          if (extracted != null && extracted.trim().isNotEmpty) {
            String cleaned = extracted.trim();
            // Enforce that it MUST contain at least one digit
            if (RegExp(r'\d').hasMatch(cleaned)) {
              if (label.toLowerCase().contains('upi') ||
                  RegExp(r'^\d+$').hasMatch(cleaned)) {
                if (isValidUpiTransactionId(cleaned)) {
                  extractedTxnId = cleaned;
                  break;
                }
              } else {
                extractedTxnId = cleaned;
                break;
              }
            }
          }
        }
      }

      if (extractedTxnId == null) {
        extractedTxnId = fallbackLineByLineSearch(fullText);
      }

      if (extractedTxnId == null) {
        final RegExp phonePeRegex = RegExp(r'\bT\d{22}\b');
        final match = phonePeRegex.firstMatch(fullText);
        if (match != null) {
          extractedTxnId = match.group(0)?.trim();
        }
      }

      if (extractedTxnId == null) {
        final RegExp fallbackRegex = RegExp(r'(?<!\d)(?:\d[\s\n]*){12}(?!\d)');
        final fallbackMatch = fallbackRegex.firstMatch(fullText);
        if (fallbackMatch != null) {
          extractedTxnId =
              fallbackMatch.group(0)?.replaceAll(RegExp(r'\s+'), '');
        }
      }

      // 2. Extract Amount
      final RegExp amountRegex = RegExp(
          r'(?:₹|Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false);
      final Iterable<RegExpMatch> amountMatches =
          amountRegex.allMatches(fullText);
      for (final match in amountMatches) {
        String? amtStr = match.group(1)?.replaceAll(',', '');
        if (amtStr != null) {
          extractedAmount = double.tryParse(amtStr);
          if (extractedAmount != null) break;
        }
      }

      // 3. Extract Time (Prefer time with a date context to avoid status bar time)
      // This regex looks for a time format near a month name.
      final RegExp contextTimeRegex = RegExp(
          r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*.*?\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\s*([aApP][mM])?\b|\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\s*([aApP][mM])?\b.*?(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*',
          caseSensitive: false);

      Iterable<RegExpMatch> timeMatches = contextTimeRegex.allMatches(fullText);

      // If no context time is found, fallback to any time (but skip the first one if there are multiple, as it's likely the status bar)
      if (timeMatches.isEmpty) {
        final RegExp timeRegex =
            RegExp(r'\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\s*([aApP][mM])?\b');
        final allMatches = timeRegex.allMatches(fullText).toList();
        if (allMatches.length > 1) {
          timeMatches = [allMatches[1]]; // Skip status bar at index 0
        } else if (allMatches.isNotEmpty) {
          timeMatches = [allMatches[0]];
        }
      }

      for (final match in timeMatches) {
        try {
          // Depending on which part of the OR regex matched, the groups will be 1,2,3 or 4,5,6
          // If we used the fallback timeRegex, it only has 3 groups.
          String? hStr =
              match.group(1) ?? (match.groupCount >= 4 ? match.group(4) : null);
          String? mStr =
              match.group(2) ?? (match.groupCount >= 5 ? match.group(5) : null);
          String? amPmStr =
              match.group(3) ?? (match.groupCount >= 6 ? match.group(6) : null);

          if (hStr != null && mStr != null) {
            int hour = int.parse(hStr);
            int minute = int.parse(mStr);
            String? amPm = amPmStr?.toLowerCase();

            if (amPm != null) {
              if (amPm == 'pm' && hour < 12) hour += 12;
              if (amPm == 'am' && hour == 12) hour = 0;
            }

            final now = DateTime.now();
            extractedTime =
                DateTime(now.year, now.month, now.day, hour, minute);
            break; // Use the first valid contextual time found
          }
        } catch (e) {
          debugPrint("Failed to parse OCR time: $e");
        }
      }

      return {
        'transactionId': extractedTxnId,
        'paymentTime': extractedTime ?? fileTime,
        'amount': extractedAmount,
      };
    } catch (e) {
      debugPrint("OCR Error: $e");
      return null;
    } finally {
      await textRecognizer.close();
    }
  }
}

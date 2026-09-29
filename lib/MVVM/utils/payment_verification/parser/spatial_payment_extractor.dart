import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/payment_ocr_result.dart';
import '../ocr/ocr_text_node.dart';

class SpatialPaymentExtractor {
  static PaymentOcrResult extract(
    RecognizedText recognizedText, {
    double? expectedAmount,
    String? expectedUpiId,
  }) {
    final nodes = _flatten(recognizedText);

    final rawText = recognizedText.text;

    final amount = _extractAmount(
      nodes,
      expectedAmount: expectedAmount,
    );

    final transactionIds = _extractTransactionIds(nodes);

    final referenceIds = _extractReferenceIds(nodes);

    final dateTime = _extractDateTime(nodes);

    final receiverUpi = _extractReceiverUpi(
      nodes,
      expectedUpiId: expectedUpiId,
    );

    final hasUpi = _hasUpiEvidence(
      nodes,
      receiverUpi,
    );

    final hasSuccess = _detectSuccessEvidence(nodes);

    final confidence = _calculateConfidence(
      amount: amount,
      transactionIds: transactionIds,
      referenceIds: referenceIds,
      dateTime: dateTime,
      receiverUpi: receiverUpi,
      hasSuccess: hasSuccess,
    );

    return PaymentOcrResult(
      rawText: rawText,
      transactionIds: transactionIds,
      referenceIds: referenceIds,
      amount: amount,
      paymentDateTime: dateTime,
      hasSuccessIndicator: hasSuccess,
      hasUpiIndicator: hasUpi,
      receiverUpi: receiverUpi,
      confidence: confidence,
    );
  }

  // ---------------------------------------------------------------------------
  // OCR hierarchy -> spatial nodes
  // ---------------------------------------------------------------------------

  static List<OcrTextNode> _flatten(
    RecognizedText recognizedText,
  ) {
    final result = <OcrTextNode>[];

    for (int blockIndex = 0;
        blockIndex < recognizedText.blocks.length;
        blockIndex++) {
      final block = recognizedText.blocks[blockIndex];

      for (int lineIndex = 0; lineIndex < block.lines.length; lineIndex++) {
        final line = block.lines[lineIndex];

        if (line.text.trim().isEmpty) continue;

        result.add(
          OcrTextNode(
            text: line.text.trim(),
            boundingBox: line.boundingBox,
            blockIndex: blockIndex,
            lineIndex: lineIndex,
            confidence: line.confidence,
          ),
        );
      }
    }

    result.sort(
      (a, b) {
        final vertical = a.top.compareTo(b.top);
        if (vertical != 0) return vertical;

        return a.left.compareTo(b.left);
      },
    );

    return result;
  }

  // ---------------------------------------------------------------------------
  // AMOUNT
  // ---------------------------------------------------------------------------

  static double? _extractAmount(
    List<OcrTextNode> nodes, {
    double? expectedAmount,
  }) {
    final candidates = <_ScoredDouble>[];

    const labels = [
      'amount',
      'amount paid',
      'paid',
      'you paid',
      'sent',
      'debited',
      'total',
      'payment',
      'pay',
      '₹',
      'rs',
      'inr',
    ];

    for (final node in nodes) {
      final lower = node.text.toLowerCase();

      // Skip nodes that are clearly UPI IDs
      if (lower.contains('@')) continue;

      final labelScore = _containsAny(lower, labels);

      final values = _numbersFromText(node.text);

      // Aggressive fallback: If the exact amount string is found in the text, force it as a candidate.
      if (expectedAmount != null) {
        final amtStr1 = expectedAmount.toStringAsFixed(0);
        final amtStr2 = expectedAmount.toStringAsFixed(2);
        if (node.text.contains(amtStr1) || node.text.contains(amtStr2)) {
          if (!values.contains(expectedAmount)) {
            values.add(expectedAmount);
          }
        }
      }

      for (double value in values) {
        if (!_isPlausibleAmount(value)) continue;

        double score = labelScore * 10;

        // Prominent text is often the actual amount.
        if (node.height >= 25) {
          score += 10;
        }

        // Currency marker on the same line is strong evidence.
        if (RegExp(
          r'(₹|rs\.?|inr)',
          caseSensitive: false,
        ).hasMatch(node.text)) {
          score += 30;
        }

        if (expectedAmount != null) {
          // Handle the OCR bug where '₹' is read as '7' (e.g. ₹1 -> 71)
          if (value.toString() == '7${expectedAmount.toStringAsFixed(0)}' ||
              value.toString() == '7${expectedAmount.toStringAsFixed(2)}' ||
              value.toString() == '7${expectedAmount.toStringAsFixed(0)}.0') {
            value = expectedAmount;
          }

          final difference = (value - expectedAmount).abs();

          if (difference < 0.01) {
            score += 200; // Massive boost for exact match
          } else if (difference <= 1) {
            score += 50;
          } else {
            score -= min(difference, 100);
          }
        }

        candidates.add(
          _ScoredDouble(
            value: value,
            score: score,
          ),
        );
      }

      // Look at nearby lines when the amount is on the next line.
      if (labelScore > 0) {
        for (final nearby in _nearbyNodes(node, nodes)) {
          if (nearby.text.contains('@')) continue;

          final nearbyValues = _numbersFromText(nearby.text);

          if (expectedAmount != null) {
            final amtStr1 = expectedAmount.toStringAsFixed(0);
            final amtStr2 = expectedAmount.toStringAsFixed(2);
            if (nearby.text.contains(amtStr1) ||
                nearby.text.contains(amtStr2)) {
              if (!nearbyValues.contains(expectedAmount)) {
                nearbyValues.add(expectedAmount);
              }
            }
          }

          for (double value in nearbyValues) {
            if (!_isPlausibleAmount(value)) continue;

            double score = labelScore * 10;

            score += _spatialScore(node, nearby);

            if (RegExp(
              r'(₹|rs\.?|inr)',
              caseSensitive: false,
            ).hasMatch(nearby.text)) {
              score += 35;
            }

            if (expectedAmount != null) {
              // Handle the OCR bug where '₹' is read as '7'
              if (value.toString() == '7${expectedAmount.toStringAsFixed(0)}' ||
                  value.toString() == '7${expectedAmount.toStringAsFixed(2)}' ||
                  value.toString() ==
                      '7${expectedAmount.toStringAsFixed(0)}.0') {
                value = expectedAmount;
              }

              final difference = (value - expectedAmount).abs();

              if (difference < 0.01) {
                score += 220; // Massive boost
              } else if (difference <= 1) {
                score += 60;
              }
            }

            candidates.add(
              _ScoredDouble(
                value: value,
                score: score,
              ),
            );
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return candidates.first.value;
  }

  // ---------------------------------------------------------------------------
  // TRANSACTION ID
  // ---------------------------------------------------------------------------

  static List<String> _extractTransactionIds(
    List<OcrTextNode> nodes,
  ) {
    final candidates = <_ScoredString>[];

    const labels = [
      'transaction id',
      'transaction id',
      'txn id',
      'upi transaction',
      'payment id',
      'transaction no',
      'transaction number',
    ];

    for (final node in nodes) {
      final lower = node.text.toLowerCase();

      if (!_containsAnyBool(lower, labels)) continue;

      final values = _alphanumericCandidates(node.text);

      for (final value in values) {
        if (!_isPlausibleTransactionId(value)) continue;

        candidates.add(
          _ScoredString(
            value: value,
            score: 100,
          ),
        );
      }

      for (final nearby in _nearbyNodes(node, nodes)) {
        final values = _alphanumericCandidates(nearby.text);

        for (final value in values) {
          if (!_isPlausibleTransactionId(value)) continue;

          candidates.add(
            _ScoredString(
              value: value,
              score: 70 + _spatialScore(node, nearby),
            ),
          );
        }
      }
    }

    return _uniqueSorted(candidates);
  }

  // ---------------------------------------------------------------------------
  // UTR / REFERENCE
  // ---------------------------------------------------------------------------

  static List<String> _extractReferenceIds(
    List<OcrTextNode> nodes,
  ) {
    final candidates = <_ScoredString>[];

    const labels = [
      'utr',
      'upi ref',
      'upi reference',
      'reference id',
      'reference no',
      'reference number',
      'ref id',
      'ref no',
      'ref number',
    ];

    for (final node in nodes) {
      final lower = node.text.toLowerCase();

      if (!_containsAnyBool(lower, labels)) continue;

      for (final value in _numericCandidates(node.text)) {
        if (!_isPlausibleReference(value)) continue;

        candidates.add(
          _ScoredString(
            value: value,
            score: 100,
          ),
        );
      }

      for (final nearby in _nearbyNodes(node, nodes)) {
        for (final value in _numericCandidates(nearby.text)) {
          if (!_isPlausibleReference(value)) continue;

          candidates.add(
            _ScoredString(
              value: value,
              score: 70 + _spatialScore(node, nearby),
            ),
          );
        }
      }
    }

    return _uniqueSorted(candidates);
  }

  // ---------------------------------------------------------------------------
  // DATE + TIME
  // ---------------------------------------------------------------------------

  static DateTime? _extractDateTime(
    List<OcrTextNode> nodes,
  ) {
    DateTime? best;

    for (final node in nodes) {
      final value = _parseDateTime(node.text);

      if (value != null) {
        best = value;
      }
    }

    // Try combining a date line and a time line.
    for (final dateNode in nodes) {
      final date = _parseDateOnly(dateNode.text);

      if (date == null) continue;

      for (final timeNode in _nearbyNodes(dateNode, nodes)) {
        final time = _parseTimeOnly(timeNode.text);

        if (time == null) continue;

        best = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        return best;
      }
    }

    return best;
  }

  static DateTime? _parseDateTime(String text) {
    final date = _parseDateOnly(text);

    if (date == null) return null;

    final time = _parseTimeOnly(text);

    if (time == null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static DateTime? _parseDateOnly(String text) {
    final numeric = RegExp(
      r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})\b',
    ).firstMatch(text);

    if (numeric != null) {
      final day = int.parse(numeric.group(1)!);
      final month = int.parse(numeric.group(2)!);
      final year = int.parse(numeric.group(3)!);

      return _safeDate(year, month, day);
    }

    final iso = RegExp(
      r'\b(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})\b',
    ).firstMatch(text);

    if (iso != null) {
      final year = int.parse(iso.group(1)!);
      final month = int.parse(iso.group(2)!);
      final day = int.parse(iso.group(3)!);

      return _safeDate(year, month, day);
    }

    final monthNames = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final named = RegExp(
      r'\b(?:(\d{1,2})\s+)?'
      r'(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|'
      r'Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember|t)?|'
      r'Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
      r'(?:\s+(\d{1,2}))?'
      r'(?:(?:,|\s)+(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (named != null) {
      final dayStr = named.group(1) ?? named.group(3);
      if (dayStr != null) {
        final day = int.parse(dayStr);
        final monthNameStr = named.group(2)!.toLowerCase();
        final monthKey = monthNameStr.startsWith('sept')
            ? 'sept'
            : monthNameStr.substring(0, 3);
        final yearStr = named.group(4);
        final year = yearStr != null ? int.parse(yearStr) : DateTime.now().year;

        final month = monthNames[monthKey];

        if (month != null) {
          return _safeDate(year, month, day);
        }
      }
    }

    return null;
  }

  static DateTime? _parseTimeOnly(String text) {
    final match = RegExp(
      r'\b([0-1]?\d|2[0-3]):([0-5]\d)(?::[0-5]\d)?\s*([aApP][mM])?\b',
    ).firstMatch(text);

    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);

    final suffix = match.group(3)?.toLowerCase();

    if (suffix == 'pm' && hour < 12) {
      hour += 12;
    }

    if (suffix == 'am' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      2000,
      1,
      1,
      hour,
      minute,
    );
  }

  // ---------------------------------------------------------------------------
  // RECEIVER UPI
  // ---------------------------------------------------------------------------

  static String? _extractReceiverUpi(
    List<OcrTextNode> nodes, {
    String? expectedUpiId,
  }) {
    final candidates = <_ScoredString>[];

    final upiRegex = RegExp(
      r'[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}',
    );

    for (final node in nodes) {
      final matches = upiRegex.allMatches(node.text);

      for (final match in matches) {
        final value = match.group(0)!.toLowerCase();

        double score = 40;

        final lower = node.text.toLowerCase();

        if (lower.contains('paid to') ||
            lower.contains('receiver') ||
            lower.contains('recipient') ||
            lower.contains('upi id') ||
            lower.contains('sent to')) {
          score += 50;
        }

        if (expectedUpiId != null && value == expectedUpiId.toLowerCase()) {
          score += 100;
        }

        candidates.add(
          _ScoredString(
            value: value,
            score: score,
          ),
        );
      }
    }

    if (candidates.isEmpty) return null;

    candidates.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    return candidates.first.value;
  }

  // ---------------------------------------------------------------------------
  // SUCCESS EVIDENCE
  // ---------------------------------------------------------------------------

  static bool _detectSuccessEvidence(
    List<OcrTextNode> nodes,
  ) {
    final positive = [
      'successful',
      'success',
      'completed',
      'payment complete',
      'payment successful',
      'paid successfully',
      'payment done',
      'transaction successful',
      'transaction completed',
      'sent successfully',
    ];

    final negative = [
      'failed',
      'failure',
      'declined',
      'cancelled',
      'canceled',
      'pending',
      'processing',
      'reversed',
      'refunded',
    ];

    bool hasPositive = false;

    for (final node in nodes) {
      final lower = node.text.toLowerCase();

      if (_containsAnyBool(lower, negative)) {
        return false;
      }

      if (_containsAnyBool(lower, positive)) {
        hasPositive = true;
      }
    }

    return hasPositive;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static List<OcrTextNode> _nearbyNodes(
    OcrTextNode source,
    List<OcrTextNode> nodes,
  ) {
    return nodes.where((node) {
      if (identical(node, source)) return false;

      final verticalDistance = (node.centerY - source.centerY).abs();

      final maxDistance = max(source.height * 4, 180);

      if (verticalDistance > maxDistance) {
        return false;
      }

      return true;
    }).toList();
  }

  static double _spatialScore(
    OcrTextNode label,
    OcrTextNode value,
  ) {
    double score = 0;

    final verticalDistance = (value.centerY - label.centerY).abs();

    final horizontalDistance = (value.centerX - label.centerX).abs();

    if (verticalDistance < label.height * 1.5) {
      score += 30;
    } else if (verticalDistance < label.height * 3) {
      score += 15;
    }

    if (horizontalDistance < label.width * 3) {
      score += 10;
    }

    if (value.top >= label.bottom) {
      score += 15;
    }

    return score;
  }

  static List<double> _numbersFromText(String text) {
    final cleanText = text.replaceAll(',', '');
    final matches = RegExp(r'\d+(?:\.\d+)?').allMatches(cleanText);

    return matches
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
  }

  static List<String> _numericCandidates(String text) {
    return RegExp(
      r'(?<!\d)\d{8,22}(?!\d)',
    ).allMatches(text).map((m) => m.group(0)!).toList();
  }

  static List<String> _alphanumericCandidates(String text) {
    return RegExp(
      r'\b[A-Z0-9][A-Z0-9\-]{7,39}\b',
      caseSensitive: false,
    ).allMatches(text).map((m) => m.group(0)!).toList();
  }

  static bool _isPlausibleAmount(double value) {
    if (value <= 0) return false;

    if (value > 100000000) return false;

    final rounded = value.round().toString();

    if (rounded.length >= 8) {
      return false;
    }

    return true;
  }

  static bool _isPlausibleReference(String value) {
    if (value.length < 8 || value.length > 22) {
      return false;
    }

    return true;
  }

  static bool _isPlausibleTransactionId(String value) {
    if (value.length < 8 || value.length > 40) {
      return false;
    }

    // Reject obvious dates.
    if (RegExp(
      r'^\d{1,2}[\/\-.]\d{1,2}[\/\-.]\d{4}$',
    ).hasMatch(value)) {
      return false;
    }

    return true;
  }

  static int _containsAny(
    String text,
    List<String> values,
  ) {
    int score = 0;

    for (final value in values) {
      if (text.contains(value)) {
        score += 1;
      }
    }

    return score;
  }

  static bool _containsAnyBool(
    String text,
    List<String> values,
  ) {
    return values.any(text.toLowerCase().contains);
  }

  static DateTime? _safeDate(
    int year,
    int month,
    int day,
  ) {
    try {
      final result = DateTime(year, month, day);

      if (result.year != year || result.month != month || result.day != day) {
        return null;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  static bool _hasUpiEvidence(
    List<OcrTextNode> nodes,
    String? receiverUpi,
  ) {
    if (receiverUpi != null) return true;

    return nodes.any(
      (node) =>
          node.text.toLowerCase().contains('upi') || node.text.contains('@'),
    );
  }

  static double _calculateConfidence({
    required double? amount,
    required List<String> transactionIds,
    required List<String> referenceIds,
    required DateTime? dateTime,
    required String? receiverUpi,
    required bool hasSuccess,
  }) {
    double score = 0;

    if (amount != null) score += 0.25;

    if (transactionIds.isNotEmpty) {
      score += 0.25;
    } else if (referenceIds.isNotEmpty) {
      score += 0.20;
    }

    if (dateTime != null) score += 0.15;

    if (receiverUpi != null) score += 0.15;

    if (hasSuccess) score += 0.20;

    return min(score, 1.0);
  }

  static List<String> _uniqueSorted(
    List<_ScoredString> candidates,
  ) {
    candidates.sort(
      (a, b) => b.score.compareTo(a.score),
    );

    final result = <String>{};

    for (final candidate in candidates) {
      result.add(candidate.value);
    }

    return result.toList();
  }
}

class _ScoredDouble {
  final double value;
  final double score;

  const _ScoredDouble({
    required this.value,
    required this.score,
  });
}

class _ScoredString {
  final String value;
  final double score;

  const _ScoredString({
    required this.value,
    required this.score,
  });
}

class TransactionIdExtractor {
  static List<String> extractTransactionIds(String text) {
    final List<String> ids = [];

    // GPay and similar transaction IDs
    // T + 22 digits is very specific and inherently strong evidence
    final RegExp tRegex = RegExp(r'T\d{22}', caseSensitive: false);
    for (final match in tRegex.allMatches(text)) {
      if (match.group(0) != null) ids.add(match.group(0)!);
    }

    // Label-aware transaction ID extraction (e.g., Transaction ID: 123456789012)
    final RegExp labeledRegex = RegExp(
      r'(?:txn\s*id|transaction\s*id|gpay\s*id)[\s\S]{0,30}?([A-Z0-9]{10,22})',
      caseSensitive: false,
    );
    for (final match in labeledRegex.allMatches(text)) {
      if (match.group(1) != null) ids.add(match.group(1)!);
    }

    return ids.toSet().toList();
  }

  static List<String> extractReferenceIds(String text) {
    final List<String> ids = [];

    // Label-aware UTR/Reference extraction
    // Looks for utr, upi ref, ref id, reference no, followed by a 12-digit number
    final RegExp labeledRegex = RegExp(
        r'(?:utr|upi\s*ref|ref\s*id|reference\s*no|ref\.\s*no|reference\s*number)[\s\S]{0,30}?(?<!\d)(\d{12})(?!\d)',
        caseSensitive: false);

    final labeledMatches = labeledRegex.allMatches(text);
    for (final match in labeledMatches) {
      final id = match.group(1);
      if (id != null) ids.add(id);
    }

    // If strong labeled evidence is found, use it exclusively.
    if (ids.isNotEmpty) {
      return ids.toSet().toList();
    }

    // Fallback: If no label is found, extract any standalone 12-digit number as a candidate
    final RegExp fallbackRegex = RegExp(r'(?<!\d)\d{12}(?!\d)');
    final fallbackMatches = fallbackRegex.allMatches(text);
    for (final match in fallbackMatches) {
      final id = match.group(0);
      if (id != null) ids.add(id);
    }

    return ids.toSet().toList();
  }
}

class SuccessDetector {
  static bool detect(String text) {
    final lower = text.toLowerCase();
    
    // Explicit negatives override any positive wording that might appear in ads
    if (lower.contains('failed') || 
        lower.contains('unsuccessful') || 
        lower.contains('pending') ||
        lower.contains('processing')) {
      return false;
    }

    // Must have explicit positive status with word boundaries to avoid matching "unsuccessful" as "successful"
    final RegExp successRegex = RegExp(r'\b(completed|success|successful|paid successfully)\b', caseSensitive: false);
    return successRegex.hasMatch(text);
  }
}

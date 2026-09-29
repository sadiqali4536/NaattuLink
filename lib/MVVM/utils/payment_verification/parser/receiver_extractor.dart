class ReceiverExtractor {
  static String? extractUpi(String text) {
    final lower = text.toLowerCase();
    final upiMatch = RegExp(r'[a-zA-Z0-9.\-_]+@[a-zA-Z]+').firstMatch(lower);
    return upiMatch?.group(0);
  }
  
  static bool hasUpiIndicator(String text) {
    final lower = text.toLowerCase();
    return lower.contains('upi') || lower.contains('@');
  }
}

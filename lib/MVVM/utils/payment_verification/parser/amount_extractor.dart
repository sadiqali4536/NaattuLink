class AmountExtractor {
  static double? extract(String text) {
    final RegExp amountRegex = RegExp(
        r'(?:₹|rs\.?|inr|paid|sent|amount)\s*[^0-9a-zA-Z]*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false);
    final match = amountRegex.firstMatch(text);
    if (match != null) {
       return double.tryParse(match.group(1)!.replaceAll(',', ''));
    }
    
    final fallbackRegex = RegExp(r'^[^0-9a-zA-Z]*([0-9,]+(?:\.[0-9]{1,2})?)\s*$', multiLine: true);
    final fallbacks = fallbackRegex.allMatches(text);
    for(final fb in fallbacks) {
       final val = fb.group(1)!;
       if (val.length < 8 && !['2023','2024','2025','2026'].contains(val)) {
          return double.tryParse(val.replaceAll(',', ''));
       }
    }
    return null;
  }
}

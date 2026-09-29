class DatetimeExtractor {
  static DateTime? extract(String text) {
    final RegExp timeRegex = RegExp(r'\b([0-1]?[0-9]|2[0-3]):([0-5][0-9])\s*([aApP][mM])?\b');
    final timeMatches = timeRegex.allMatches(text).toList();
    
    DateTime? extractedTime;
    for (final match in timeMatches.reversed) { 
        try {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          String? amPm = match.group(3)?.toLowerCase();
          
          if (amPm != null) {
            if (amPm == 'pm' && hour < 12) hour += 12;
            if (amPm == 'am' && hour == 12) hour = 0;
          }
          
          final RegExp dateRegex = RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})\b', caseSensitive: false);
          final dateMatch = dateRegex.firstMatch(text);
          
          int year = DateTime.now().year;
          int month = DateTime.now().month;
          int day = DateTime.now().day;
          
          if (dateMatch != null) {
             day = int.parse(dateMatch.group(1)!);
             year = int.parse(dateMatch.group(3)!);
             const months = {'jan':1, 'feb':2, 'mar':3, 'apr':4, 'may':5, 'jun':6, 'jul':7, 'aug':8, 'sep':9, 'oct':10, 'nov':11, 'dec':12};
             month = months[dateMatch.group(2)!.toLowerCase().substring(0,3)] ?? month;
          }
          
          extractedTime = DateTime(year, month, day, hour, minute);
          break; 
        } catch (_) {}
    }
    return extractedTime;
  }
}

class SubscriptionDateUtils {
  // IST is UTC+5:30
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Converts a DateTime into India Standard Time (UTC+5:30)
  static DateTime toIST(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return utc.add(istOffset);
  }

  /// Returns start of calendar day (00:00:00.000) in IST
  static DateTime startOfDayIST(DateTime dateTime) {
    final ist = toIST(dateTime);
    return DateTime.utc(ist.year, ist.month, ist.day, 0, 0, 0, 0);
  }

  /// Returns end of calendar day (23:59:59.999) in IST
  static DateTime endOfDayIST(DateTime dateTime) {
    final ist = toIST(dateTime);
    return DateTime.utc(ist.year, ist.month, ist.day, 23, 59, 59, 999);
  }

  /// Calculates dynamic remaining calendar days against an expiry date.
  /// If today is Nov 20 and expiry is Nov 20 end of day -> 1 day remaining (today).
  /// If today is Nov 20 and expiry is Nov 21 end of day -> 2 days remaining.
  /// If expired, returns 0.
  static int calculateRemainingDays(DateTime? expiryDate, {DateTime? currentTime}) {
    if (expiryDate == null) return 0;

    final now = currentTime ?? DateTime.now();
    final nowUtc = now.toUtc();
    final expiryUtc = expiryDate.isUtc ? expiryDate : expiryDate.toUtc();

    // If current time has already passed expiry, remaining is 0
    if (nowUtc.isAfter(expiryUtc)) {
      return 0;
    }

    // Convert both to IST calendar days
    final nowIst = nowUtc.add(istOffset);
    final expiryIst = expiryUtc.add(istOffset);

    final nowDateOnly = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final expiryDateOnly = DateTime(expiryIst.year, expiryIst.month, expiryIst.day);

    final diffDays = expiryDateOnly.difference(nowDateOnly).inDays;

    // If it expires on the same calendar day (diffDays == 0) but now < expiry:
    // It is day 1 of the last day, or 1 day remaining until midnight.
    final remaining = diffDays >= 0 ? diffDays + 1 : 0;
    return remaining > 0 ? remaining : 0;
  }

  /// Checks if subscription is actively valid (now < expiryDate)
  static bool isSubscriptionActive(DateTime? expiryDate, {DateTime? currentTime}) {
    if (expiryDate == null) return false;
    final now = (currentTime ?? DateTime.now()).toUtc();
    final expiry = expiryDate.isUtc ? expiryDate : expiryDate.toUtc();
    return now.isBefore(expiry);
  }

  /// Returns formatted string of date in DD MMM YYYY (e.g. 20 Nov 2026)
  static String formatDisplayDate(DateTime? dateTime) {
    if (dateTime == null) return "N/A";
    final ist = toIST(dateTime);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = ist.day.toString().padLeft(2, '0');
    final month = months[ist.month - 1];
    final year = ist.year;
    return "$day $month $year";
  }

  /// Calculates new start and expiry dates according to the required policy:
  /// - If renewed before expiry: new expiry = existing expiry + duration
  /// - If renewed after expiry: new start = renewal activation date, new expiry = start + duration
  static ({DateTime startDate, DateTime expiryDate}) calculateRenewalDates({
    required DateTime? currentExpiryDate,
    required int durationDays,
    DateTime? renewalDate,
  }) {
    final now = renewalDate ?? DateTime.now();
    final nowUtc = now.toUtc();
    final nowIst = nowUtc.add(istOffset);

    final bool isBeforeExpiry = currentExpiryDate != null &&
        currentExpiryDate.toUtc().isAfter(nowUtc);

    if (isBeforeExpiry) {
      final existingExpiryIst = currentExpiryDate!.toUtc().add(istOffset);
      final newExpiryIst = existingExpiryIst.add(Duration(days: durationDays));
      
      // Keep existing start date or align to start of day
      final newExpiryEnd = DateTime.utc(
        newExpiryIst.year,
        newExpiryIst.month,
        newExpiryIst.day,
        23, 59, 59, 999,
      ).subtract(istOffset);

      return (
        startDate: currentExpiryDate, // preserves lineage
        expiryDate: newExpiryEnd,
      );
    } else {
      // Renewed after expiry
      final newStartIst = DateTime(nowIst.year, nowIst.month, nowIst.day, 0, 0, 0);
      final newExpiryIst = newStartIst.add(Duration(days: durationDays - 1));

      final startUtc = DateTime.utc(
        newStartIst.year,
        newStartIst.month,
        newStartIst.day,
        0, 0, 0,
      ).subtract(istOffset);

      final expiryUtc = DateTime.utc(
        newExpiryIst.year,
        newExpiryIst.month,
        newExpiryIst.day,
        23, 59, 59, 999,
      ).subtract(istOffset);

      return (
        startDate: startUtc,
        expiryDate: expiryUtc,
      );
    }
  }
}


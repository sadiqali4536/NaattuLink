class DistanceFormatter {
  /// Formats a distance (given in kilometers) into a readable string.
  /// 
  /// Examples:
  /// 0.12 -> "120 m"
  /// 0.85 -> "850 m"
  /// 1.2  -> "1.2 km"
  /// 3.8  -> "3.8 km"
  static String format(double distanceInKm) {
    if (distanceInKm < 1.0) {
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }
}

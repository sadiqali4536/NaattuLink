import 'package:geolocator/geolocator.dart';

class DistanceService {
  /// Calculates the straight-line distance between two coordinates in kilometers.
  /// 
  /// In Phase 2, this can be swapped out to call the Google Routes API 
  /// for road distance and travel time.
  static double calculateDistanceInKm(
      double startLat, double startLng, double endLat, double endLng) {
    // Geolocator.distanceBetween returns meters. We convert to kilometers.
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000.0;
  }
}

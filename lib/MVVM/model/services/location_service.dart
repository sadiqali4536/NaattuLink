import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  final bool isCached;

  LocationResult({
    this.latitude,
    this.longitude,
    this.error,
    this.isCached = false,
  });

  bool get isSuccess => latitude != null && longitude != null;
}

class LocationService {
  static const String _latKey = 'cached_lat';
  static const String _lngKey = 'cached_lng';
  static const String _timeKey = 'cached_time';

  /// Tries to load the cached location first.
  /// If it exists, returns it immediately.
  Future<LocationResult> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final time = prefs.getInt(_timeKey);

    if (lat != null && lng != null) {
      return LocationResult(
        latitude: lat,
        longitude: lng,
        isCached: true,
      );
    }
    return LocationResult(error: 'No cached location available.');
  }

  /// Fetches exact GPS location, handling permissions and services.
  /// If successful, caches it.
  Future<LocationResult> fetchCurrentLocation({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await getCachedLocation();
      if (cached.isSuccess) {
        // Optionally fetch in background here, but we'll just return cached
        return cached;
      }
    }

    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(error: 'Location services are disabled.');
    }

    // 2. Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(error: 'Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
        error: 'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    try {
      // 3. Fetch position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Cache it
      await _cacheLocation(position.latitude, position.longitude);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return LocationResult(error: 'Failed to get location: $e');
    }
  }

  Future<void> _cacheLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
    await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
  }
}

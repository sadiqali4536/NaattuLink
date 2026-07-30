import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastAcceptedPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _locationStreamController =
      StreamController<Position>.broadcast();

  // Expose the current stable position
  Position? get currentPosition => _lastAcceptedPosition;

  // Expose the stream for UI to listen if needed
  Stream<Position> get locationStream => _locationStreamController.stream;

  bool _isListening = false;
  
  // Configuration for drift filtering
  static const double _minimumDistanceThresholdMeters = 25.0; // Ignore moves smaller than this
  static const double _maximumAcceptableAccuracy = 30.0; // Ignore readings worse than this

  /// Starts listening to location updates
  Future<void> startListening() async {
    if (_isListening) return;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Fetch the initial location immediately
      Position? initialPos = await _getAccurateCurrentPosition();
      if (initialPos != null) {
        _lastAcceptedPosition = initialPos;
        _locationStreamController.add(initialPos);
      }

      // Start the stream to listen for changes
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Fetch when device thinks it moved 10m, but we'll manually filter it strictly
        ),
      ).listen((Position newPosition) {
        _processNewLocation(newPosition);
      }, onError: (error) {
        debugPrint('Location stream error: $error');
      });

      _isListening = true;
    } catch (e) {
      debugPrint('Error starting location service: $e');
    }
  }

  void _processNewLocation(Position newPosition) {
    // 1. Ignore updates with poor accuracy (GPS drift)
    if (newPosition.accuracy > _maximumAcceptableAccuracy) {
      return;
    }

    if (_lastAcceptedPosition == null) {
      _lastAcceptedPosition = newPosition;
      _locationStreamController.add(newPosition);
      return;
    }

    // 2. Filter GPS Drift: Compare with last accepted location
    final distanceMoved = Geolocator.distanceBetween(
      _lastAcceptedPosition!.latitude,
      _lastAcceptedPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    // 3. Keep stable location: Only update if moved beyond threshold
    if (distanceMoved >= _minimumDistanceThresholdMeters) {
      _lastAcceptedPosition = newPosition;
      _locationStreamController.add(newPosition);
    }
  }

  /// Stop listening to location updates
  void stopListening() {
    _positionStreamSubscription?.cancel();
    _isListening = false;
  }

  /// Forces a fresh location fetch and applies stabilization
  Future<Position?> fetchCurrentLocation() async {
    try {
      final pos = await _getAccurateCurrentPosition();
      if (pos != null) {
        _processNewLocation(pos);
      }
      return _lastAcceptedPosition;
    } catch (e) {
      debugPrint('Error fetching fresh location: $e');
      return _lastAcceptedPosition;
    }
  }

  Future<Position?> _getAccurateCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
    } catch (e) {
      return null;
    }
  }
}

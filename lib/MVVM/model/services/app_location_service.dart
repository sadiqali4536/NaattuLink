import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'dart:math' as math;

class AppLocationService {
  /// Check permissions and get the current GPS location.
  Future<AppLocationModel?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return await getLocationDetailsFromCoordinates(
          position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Get placemark details for given coordinates
  Future<AppLocationModel> getLocationDetailsFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;

        String subLocalityPart =
            (pm.subLocality != null && pm.subLocality!.isNotEmpty)
                ? pm.subLocality!
                : (pm.name ?? '');

        String localityPart = (pm.locality != null && pm.locality!.isNotEmpty)
            ? pm.locality!
            : (pm.subAdministrativeArea ?? '');

        String distStr =
            pm.subAdministrativeArea ?? pm.administrativeArea ?? "";
        if (distStr.toLowerCase().endsWith(" district")) {
          distStr = distStr.substring(0, distStr.length - 9).trim();
        }

        String formattedAddress = '';
        if (subLocalityPart.toLowerCase() == localityPart.toLowerCase()) {
          formattedAddress = localityPart;
        } else {
          formattedAddress = [subLocalityPart, localityPart]
              .where((e) => e.isNotEmpty)
              .join(', ');
        }

        return AppLocationModel(
          latitude: latitude,
          longitude: longitude,
          formattedAddress: formattedAddress.isNotEmpty
              ? formattedAddress
              : 'Unknown Location',
          district: distStr,
          city: pm.locality,
          state: pm.administrativeArea,
          pincode: pm.postalCode,
        );
      }
    } catch (e) {
      // Ignored
    }

    // Fallback if reverse geocoding fails
    return AppLocationModel(
      latitude: latitude,
      longitude: longitude,
      formattedAddress: 'Selected Location',
      district: 'Unknown',
    );
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Format distance for UI display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      double kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(1)} km away';
    }
  }

  /// Helper to get a formatted distance string directly from coordinates
  String getFormattedDistance(
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
  ) {
    if (startLat == null || startLng == null) {
      return 'Enable location to see nearby services';
    }
    if (endLat == null || endLng == null) {
      return 'Distance unavailable';
    }

    double meters =
        calculateDistanceInMeters(startLat, startLng, endLat, endLng);
    return formatDistance(meters);
  }
}

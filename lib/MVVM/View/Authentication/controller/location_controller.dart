import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

/// Global GetX controller that fetches and caches the user's current GPS location.
class LocationController extends GetxController {
  static LocationController get to => Get.find();

  final latitude = Rxn<double>();
  final longitude = Rxn<double>();
  final locationName = ''.obs;
  final district = ''.obs;

  // To keep backward compatibility with existing codebase that reads currentLocation
  final currentLocation = ''.obs;

  final isLoading = false.obs;

  Future<void> fetchLocation({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    if (!forceRefresh &&
        latitude.value != null &&
        longitude.value != null &&
        locationName.value.isNotEmpty) {
      return; // Already fetched
    }

    isLoading.value = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Location denied forever
        _setFallbackLocation();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        latitude.value = position.latitude;
        longitude.value = position.longitude;

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;

          // Construct placeName as "subLocality, locality"
          String subLocalityPart =
              (pm.subLocality != null && pm.subLocality!.isNotEmpty)
                  ? pm.subLocality!
                  : (pm.name ?? '----');

          String localityPart = (pm.locality != null && pm.locality!.isNotEmpty)
              ? pm.locality!
              : (pm.subAdministrativeArea ?? '----');

          String distStr =
              pm.subAdministrativeArea ?? pm.administrativeArea ?? "-----";
          if (distStr.toLowerCase().endsWith(" district")) {
            distStr = distStr.substring(0, distStr.length - 9).trim();
          }
          district.value = distStr;

          if (subLocalityPart.toLowerCase() == localityPart.toLowerCase()) {
            locationName.value = localityPart;
          } else {
            locationName.value = '$subLocalityPart, $localityPart';
          }

          currentLocation.value = locationName.value;
        } else {
          locationName.value = 'Kallai, Kozhikode';
          currentLocation.value = locationName.value;
          district.value = 'Unknown';
        }
      } else {
        _setFallbackLocation();
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      _setFallbackLocation();
    } finally {
      isLoading.value = false;
    }
  }

  void _setFallbackLocation() {
    latitude.value = 11.2588;
    longitude.value = 75.7804;
    locationName.value = 'Kallai, Kozhikode';
    currentLocation.value = 'Kallai, Kozhikode';
    district.value = 'Unknown';
  }
}

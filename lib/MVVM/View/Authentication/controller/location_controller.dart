import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/model/services/app_location_service.dart';

/// Global GetX controller that manages the user's current GPS location and generic distance calculations.
class LocationController extends GetxController {
  static LocationController get to => Get.find();

  final AppLocationService _locationService = AppLocationService();

  // Current location model
  final currentLocationModel = Rxn<AppLocationModel>();

  // Backwards compatibility fields
  final latitude = Rxn<double>();
  final longitude = Rxn<double>();
  final locationName = ''.obs;
  final district = ''.obs;
  final currentLocation = ''.obs;

  final isLoading = false.obs;

  Future<void> fetchLocation({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    if (!forceRefresh && currentLocationModel.value != null) {
      return; // Already fetched
    }

    isLoading.value = true;

    try {
      final loc = await _locationService.getCurrentLocation();
      if (loc != null) {
        currentLocationModel.value = loc;
        _updateLegacyFields(loc);
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

  void updateLocationManually(AppLocationModel loc) {
    currentLocationModel.value = loc;
    _updateLegacyFields(loc);
  }

  void _updateLegacyFields(AppLocationModel loc) {
    latitude.value = loc.latitude;
    longitude.value = loc.longitude;
    district.value = loc.district;
    locationName.value = loc.formattedAddress;
    currentLocation.value = loc.formattedAddress;
  }

  void _setFallbackLocation() {
    latitude.value = 11.2588;
    longitude.value = 75.7804;
    locationName.value = 'Kallai, Kozhikode';
    currentLocation.value = 'Kallai, Kozhikode';
    district.value = 'Unknown';
    currentLocationModel.value = AppLocationModel(
      latitude: 11.2588,
      longitude: 75.7804,
      formattedAddress: 'Kallai, Kozhikode',
      district: 'Unknown',
    );
  }

  /// Expose generic distance string formatter
  String getFormattedDistanceTo(double? targetLat, double? targetLng) {
    return _locationService.getFormattedDistance(
      latitude.value,
      longitude.value,
      targetLat,
      targetLng,
    );
  }

  /// Expose raw distance calculation
  double getDistanceInMetersTo(double? targetLat, double? targetLng) {
    if (latitude.value == null || longitude.value == null || targetLat == null || targetLng == null) {
      return double.infinity;
    }
    return _locationService.calculateDistanceInMeters(
      latitude.value!,
      longitude.value!,
      targetLat,
      targetLng,
    );
  }
}

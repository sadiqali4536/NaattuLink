import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        _saveLocationToFirebase(loc, 'gps');
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

  Future<void> updateLocationManually(AppLocationModel loc,
      {bool saveToFirebase = false}) async {
    currentLocationModel.value = loc;
    _updateLegacyFields(loc);
    if (saveToFirebase) {
      await _saveLocationToFirebase(loc, 'manual');
    }
  }

  Future<bool> hasPrimaryAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null &&
              data.containsKey('primaryAddress') &&
              data['primaryAddress'] != null) {
            return true;
          }
        }
      } catch (e) {
        debugPrint("Error checking primary address: $e");
      }
    }
    return false;
  }

  Future<void> _saveLocationToFirebase(
      AppLocationModel loc, String source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final updateData = <String, dynamic>{
          'currentLocation': {
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'formattedAddress': loc.formattedAddress,
            'locality': loc.city ?? '',
            'district': loc.district,
            'state': loc.state ?? '',
            'postalCode': loc.pincode ?? '',
            'zoneId': loc.zoneId,
            'zoneName': loc.zoneName,
            'country': 'India',
            'source': source,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        };

        if (loc.isPrimary == true) {
          updateData['primaryAddress'] = {
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'formattedAddress': loc.formattedAddress,
            'locality': loc.city ?? '',
            'district': loc.district,
            'state': loc.state ?? '',
            'postalCode': loc.pincode ?? '',
            'country': 'India',
            'receiverName': loc.receiverName ?? user.displayName ?? '',
            'receiverPhone': loc.receiverPhone ?? user.phoneNumber ?? '',
            'alternatePhone': loc.alternatePhone ?? '',
            'landmark': loc.landmark ?? '',
            'addressType': loc.addressType ?? 'Home',
            'isPrimary': true,
            'zoneId': loc.zoneId,
            'zoneName': loc.zoneName,
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));

        // --- Add to delivery_addresses subcollection across all role collections ---
        final roleCollections = [
          'users',
          'workers',
          'healthcare',
          'transports',
          'shops_businesses'
        ];

        // Generate a new ID if it's a create, otherwise use the existing ID
        final String addressId =
            loc.id ?? FirebaseFirestore.instance.collection('users').doc().id;

        for (String collectionName in roleCollections) {
          final docRef = FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid);
          final docSnap = await docRef.get();

          if (docSnap.exists) {
            final deliveryRef = docRef.collection('delivery_addresses');

            if (loc.isPrimary == true) {
              // Reset all existing default addresses to 0
              final existingDefaults =
                  await deliveryRef.where('isDefault', isEqualTo: 1).get();
              for (var d in existingDefaults.docs) {
                await d.reference.update({'isDefault': 0});
              }
            }

            if (loc.id != null) {
              // EDIT: Update existing address using its exact document ID
              try {
                await deliveryRef.doc(addressId).update({
                  'buildingName': loc.landmark ?? '',
                  'address': loc.formattedAddress,
                  'phone': loc.receiverPhone ?? user.phoneNumber ?? '',
                  'name': loc.receiverName ?? user.displayName ?? '',
                  'alternativeNumber': loc.alternatePhone ?? '',
                  'isDefault': loc.isPrimary == true ? 1 : 0,
                  'addressType': loc.addressType ?? 'Home',
                  'latitude': loc.latitude,
                  'longitude': loc.longitude,
                  'district': loc.district,
                  'city': loc.city ?? '',
                  'state': loc.state ?? '',
                  'pincode': loc.pincode ?? '',
                  'zoneId': loc.zoneId,
                  'zoneName': loc.zoneName,
                });
              } catch (e) {
                // If it doesn't exist in this specific role collection, fallback to set
                await deliveryRef.doc(addressId).set({
                  'buildingName': loc.landmark ?? '',
                  'address': loc.formattedAddress,
                  'phone': loc.receiverPhone ?? user.phoneNumber ?? '',
                  'name': loc.receiverName ?? user.displayName ?? '',
                  'alternativeNumber': loc.alternatePhone ?? '',
                  'isDefault': loc.isPrimary == true ? 1 : 0,
                  'addressType': loc.addressType ?? 'Home',
                  'latitude': loc.latitude,
                  'longitude': loc.longitude,
                  'district': loc.district,
                  'city': loc.city ?? '',
                  'state': loc.state ?? '',
                  'pincode': loc.pincode ?? '',
                  'zoneId': loc.zoneId,
                  'zoneName': loc.zoneName,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            } else {
              // CREATE: Save new address using the generated ID
              await deliveryRef.doc(addressId).set({
                'buildingName': loc.landmark ?? '',
                'address': loc.formattedAddress,
                'phone': loc.receiverPhone ?? user.phoneNumber ?? '',
                'name': loc.receiverName ?? user.displayName ?? '',
                'alternativeNumber': loc.alternatePhone ?? '',
                'isDefault': loc.isPrimary == true ? 1 : 0,
                'addressType': loc.addressType ?? 'Home',
                'latitude': loc.latitude,
                'longitude': loc.longitude,
                'district': loc.district,
                'city': loc.city ?? '',
                'state': loc.state ?? '',
                'pincode': loc.pincode ?? '',
                'zoneId': loc.zoneId,
                'zoneName': loc.zoneName,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error saving location to Firebase: $e");
      }
    }
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
    if (latitude.value == null ||
        longitude.value == null ||
        targetLat == null ||
        targetLng == null) {
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

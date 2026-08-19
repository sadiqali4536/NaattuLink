import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:naattulink/MVVM/model/nearby_service_model.dart';
import 'package:naattulink/MVVM/utils/service_functions/distance_utils.dart';

class NearbyServicesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches nearby services for a specific collection using a broad 20km geohash search.
  /// Then precisely calculates distance using DistanceUtils, filters by serviceRadiusKm, and sorts.
  Future<List<NearbyServiceModel>> getNearbyServices({
    required String collectionName,
    required double userLat,
    required double userLng,
    double maxSearchRadiusKm = 10.0,
    String searchQuery = "",
  }) async {
    final collectionRef = _firestore.collection(collectionName);

    List<DocumentSnapshot> snapshots = [];

    if (searchQuery.trim().isEmpty) {
      final geoCollectionRef = GeoCollectionReference(collectionRef);
      final center = GeoFirePoint(GeoPoint(userLat, userLng));

      // Execute the broad geohash query using geoflutterfire_plus
      snapshots = await geoCollectionRef.fetchWithin(
        center: center,
        radiusInKm: maxSearchRadiusKm,
        field: 'position',
        geopointFrom: (data) {
          final position = data['position'] as Map<String, dynamic>?;
          return position?['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);
        },
        strictMode: true,
      );
    } else {
      // Global search: fetch all documents in the collection
      final querySnapshot = await collectionRef.get();
      snapshots = querySnapshot.docs;
    }

    List<NearbyServiceModel> validServices = [];
    final lowerQuery = searchQuery.trim().toLowerCase();

    for (final docSnap in snapshots) {
      if (!docSnap.exists) continue;

      final data = docSnap.data() as Map<String, dynamic>? ?? {};

      // Ensure the service is active
      final status = (data['status'] ?? '').toString().trim().toLowerCase();
      if (status != 'active') {
        continue;
      }

      // Parse coordinates from the document
      double? docLat;
      double? docLng;

      if (data.containsKey('position') && data['position'] is Map) {
        final geopoint = data['position']['geopoint'] as GeoPoint?;
        if (geopoint != null) {
          docLat = geopoint.latitude;
          docLng = geopoint.longitude;
        }
      }

      // Fallback to flat lat/lng for backward compatibility
      docLat ??= (data['lat'] as num?)?.toDouble();
      docLng ??= (data['lng'] as num?)?.toDouble();

      double exactDistance = double.infinity;
      if (docLat != null && docLng != null) {
        exactDistance = DistanceUtils.calculateDistanceKm(
          userLat,
          userLng,
          docLat,
          docLng,
        );
      }

      if (searchQuery.trim().isEmpty) {
        // Normal Flow: Must have valid coordinates and be within maxSearchRadiusKm (10km)
        if (docLat == null || docLng == null) continue;
        if (exactDistance <= maxSearchRadiusKm) {
          validServices
              .add(NearbyServiceModel.fromFirestore(docSnap, exactDistance));
        }
      } else {
        // Search Flow: Check names, ignore serviceRadius limitation
        final name1 = (data['facility_name'] ?? '').toString().toLowerCase();
        final name2 = (data['username'] ?? '').toString().toLowerCase();
        final name3 = (data['name'] ?? '').toString().toLowerCase();
        final name4 = (data['business_name'] ?? '').toString().toLowerCase();

        if (name1.contains(lowerQuery) ||
            name2.contains(lowerQuery) ||
            name3.contains(lowerQuery) ||
            name4.contains(lowerQuery)) {
          validServices
              .add(NearbyServiceModel.fromFirestore(docSnap, exactDistance));
        }
      }
    }

    // Sort from nearest to farthest, fallback to alphabetical if distance is missing/infinity
    validServices.sort((a, b) {
      if (a.distanceKm == b.distanceKm ||
          (a.distanceKm == double.infinity &&
              b.distanceKm == double.infinity)) {
        final nameA = (a.rawData['facility_name'] ??
                a.rawData['username'] ??
                a.rawData['name'] ??
                '')
            .toString();
        final nameB = (b.rawData['facility_name'] ??
                b.rawData['username'] ??
                b.rawData['name'] ??
                '')
            .toString();
        return nameA.compareTo(nameB);
      }
      return a.distanceKm.compareTo(b.distanceKm);
    });

    return validServices;
  }
}

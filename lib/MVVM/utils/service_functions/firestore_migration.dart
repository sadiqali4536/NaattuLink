import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class FirestoreMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> targetCollections = [
    'transports',
    'healthcare',
    'shops',
    'education',
    'public_services',
  ];

  /// Run a one-time migration to add geohash and geopoint to documents
  Future<void> runMigration({bool isDryRun = true}) async {
    int totalMigrated = 0;
    int totalSkipped = 0;
    int totalMissingCoords = 0;
    int totalErrors = 0;

    debugPrint('--- Starting Firestore Migration (Dry Run: $isDryRun) ---');

    for (String collection in targetCollections) {
      debugPrint('Scanning collection: $collection...');
      try {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          final data = doc.data();

          // Check for existing position object
          if (data.containsKey('position') && data['position'] is Map && data['position']['geohash'] != null) {
            totalSkipped++;
            continue;
          }

          // Read flat lat/lng. Some docs might use 'latitude'/'longitude', but let's check standard
          double? lat = (data['lat'] as num?)?.toDouble() ?? (data['latitude'] as num?)?.toDouble();
          double? lng = (data['lng'] as num?)?.toDouble() ?? (data['longitude'] as num?)?.toDouble();

          if (lat == null || lng == null) {
            // Note: Many existing Taxis and Healthcare records might not have flat lat/lng in DB
            // because they rely on geocoding address strings. Those will be skipped here.
            totalMissingCoords++;
            continue;
          }

          // We have coordinates, generate geoflutterfire_plus position
          final geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));

          final updateData = <String, dynamic>{
            'position': {
              'geohash': geoFirePoint.geohash,
              'geopoint': geoFirePoint.geopoint,
            },
          };

          if (!data.containsKey('serviceRadiusKm')) {
            updateData['serviceRadiusKm'] = 7.0;
          }

          if (isDryRun) {
            debugPrint('[DRY RUN] Would update doc ${doc.id} in $collection with $updateData');
            totalMigrated++;
          } else {
            try {
              await doc.reference.update(updateData);
              debugPrint('Successfully migrated doc ${doc.id} in $collection');
              totalMigrated++;
            } catch (e) {
              debugPrint('Failed to update doc ${doc.id} in $collection: $e');
              totalErrors++;
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning collection $collection: $e');
      }
    }

    debugPrint('--- Migration Complete ---');
    debugPrint('Total Migrated/Would Migrate: $totalMigrated');
    debugPrint('Total Skipped (already has position): $totalSkipped');
    debugPrint('Total Skipped (missing coordinates): $totalMissingCoords');
    debugPrint('Total Errors: $totalErrors');
  }
}

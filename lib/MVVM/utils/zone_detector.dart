import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LatLngPoint {
  final double latitude;
  final double longitude;

  LatLngPoint(this.latitude, this.longitude);
}

class ZoneData {
  final String id;
  final String name;
  final String districtId;
  final List<LatLngPoint> polygon;
  final int priority;

  ZoneData({
    required this.id,
    required this.name,
    this.districtId = '',
    required this.polygon,
    this.priority = 0,
  });
}

class ZoneDetector {
  /// Ray-casting algorithm to determine if a point is inside a polygon.
  static bool isPointInsidePolygon(
      double latitude, double longitude, List<LatLngPoint> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(latitude, longitude, polygon[j], polygon[j + 1])) {
        intersectCount++;
      }
    }
    // Also check the edge between the last and the first point to close the polygon
    if (polygon.isNotEmpty) {
      if (_rayCastIntersect(latitude, longitude, polygon.last, polygon.first)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2 == 1); // odd means inside
  }

  static bool _rayCastIntersect(
      double lat, double lng, LatLngPoint vertA, LatLngPoint vertB) {
    final double aY = vertA.latitude;
    final double bY = vertB.latitude;
    final double aX = vertA.longitude;
    final double bX = vertB.longitude;

    if (aY > lat && bY > lat) return false;
    if (aY < lat && bY < lat) return false;
    if (aX < lng && bX < lng) return false;

    if (aY == lat && bY == lat) {
      // Point is on the horizontal edge
      return (aX <= lng && lng <= bX) || (bX <= lng && lng <= aX);
    }

    if (aY == bY) return false;

    final double xIntersection = aX + ((lat - aY) / (bY - aY)) * (bX - aX);
    return xIntersection > lng;
  }

  static ZoneData? findMatchingZone(
      double latitude, double longitude, List<ZoneData> zones) {
    List<ZoneData> matches = [];

    for (final zone in zones) {
      if (zone.polygon.length < 3) continue;

      debugPrint('CHECKING LOCATION: $latitude, $longitude');
      debugPrint('ZONE BOUNDARY TEST: lat=$latitude, lng=$longitude');

      final isInside = isPointInsidePolygon(latitude, longitude, zone.polygon);
      debugPrint('ZONE ${zone.id} (${zone.name}) CONTAINS LOCATION: $isInside');

      if (isInside) {
        matches.add(zone);
      }
    }

    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    // If overlapping zones exist, pick the one with the smallest priority value
    matches.sort((a, b) => a.priority.compareTo(b.priority));
    print(
        'Zone overlap detected. Choosing highest priority: ${matches.first.name}');
    return matches.first;
  }

  /// Helper to fetch active zones from Firestore for a specific district.
  static Future<List<ZoneData>> getActiveZonesForDistrict(
      String districtName) async {
    try {
      // Normalize the district name (e.g., "Kozhikode" -> "kozhikode")
      final String districtId = districtName.trim().toLowerCase();

      // We'll fetch all active zones and optionally filter by districtId
      // in memory, just in case the Firestore data doesn't match perfectly.
      // But for efficiency, we try to query by districtId if it matches exactly.
      // For now, we fetch all active zones.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('zones')
          .where('active', isEqualTo: true)
          .get();

      debugPrint('ACTIVE ZONES FOUND: ${querySnapshot.docs.length}');

      List<ZoneData> loadedZones = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        debugPrint('ZONE ID: ${doc.id}');
        debugPrint('ZONE DATA: $data');

        // (Temporarily removed districtId filtering for debugging)

        final rawPolygon = data['polygon'];
        if (rawPolygon is! List) {
          debugPrint('Invalid polygon type for zone ${doc.id}');
          continue;
        }

        List<LatLngPoint> polygon = [];
        for (var point in rawPolygon) {
          if (point is Map) {
            final lat = point['lat'];
            final lng = point['lng'];
            if (lat is num && lng is num) {
              polygon.add(LatLngPoint(lat.toDouble(), lng.toDouble()));
            }
          } else if (point is String) {
            final RegExp regex = RegExp(
              r'lat.*?([\d\.]+).*?lng.*?([\d\.]+)',
              dotAll: true,
              caseSensitive: false,
            );
            final match = regex.firstMatch(point);
            if (match != null && match.groupCount >= 2) {
              final lat = double.tryParse(match.group(1)!);
              final lng = double.tryParse(match.group(2)!);
              if (lat != null && lng != null) {
                polygon.add(LatLngPoint(lat, lng));
              }
            }
          }
        }

        debugPrint('ZONE ${doc.id} POLYGON POINTS: ${polygon.length}');

        if (polygon.length < 3) {
          debugPrint('Zone ${doc.id} has an invalid polygon.');
          continue;
        }

        final priority = (data['priority'] as num?)?.toInt() ?? 0;

        // Securely find the 'name' key even if the user accidentally added a space in Firebase Console
        String? extractedName;
        for (final key in data.keys) {
          if (key.trim().toLowerCase() == 'name') {
            extractedName = data[key]?.toString().trim();
            break;
          }
        }

        final districtIdStr = data['districtId']?.toString() ?? '';

        loadedZones.add(ZoneData(
          id: doc.id,
          name: extractedName ?? 'Unknown Zone',
          districtId: districtIdStr,
          polygon: polygon,
          priority: priority,
        ));
      }
      return loadedZones;
    } catch (e) {
      print('Error fetching zones: $e');
      return [];
    }
  }
}

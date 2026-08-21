import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:naattulink/MVVM/utils/Constants/constants.dart';

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

  /// Fetches road distances and ETAs for a single destination using Google Directions API
  static Future<Map<String, dynamic>?> fetchRoadDistanceAndEta(double originLat,
      double originLng, double destLat, double destLng) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=driving&key=$googleMapApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final distanceMeters = leg['distance']['value']; // in meters
          final durationSeconds = leg['duration']['value']; // in seconds

          return {
            'distanceKm': distanceMeters / 1000.0,
            'etaMinutes': (durationSeconds / 60.0).round(),
          };
        }
      }
    } catch (e) {
      debugPrint("Error fetching road distance: $e");
    }
    return null;
  }

  /// Fetches road distances in bulk using Google Distance Matrix API
  static Future<List<Map<String, dynamic>?>> fetchBulkRoadDistances(
      double originLat,
      double originLng,
      List<Map<String, double>> destinations) async {
    List<Map<String, dynamic>?> results =
        List.filled(destinations.length, null);

    // Process in chunks of 25 (Distance Matrix API limit)
    for (int i = 0; i < destinations.length; i += 25) {
      final chunk = destinations.sublist(
          i, i + 25 > destinations.length ? destinations.length : i + 25);

      final destString = chunk.map((d) => '${d['lat']},${d['lng']}').join('|');
      final String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$originLat,$originLng&destinations=$destString&mode=driving&key=$googleMapApiKey';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final elements = data['rows'][0]['elements'] as List;
            final destinationAddresses = data['destination_addresses'] as List?;
            for (int j = 0; j < elements.length; j++) {
              final element = elements[j];
              if (element['status'] == 'OK') {
                final distanceMeters = element['distance']['value'];
                final durationSeconds = element['duration']['value'];

                String? address;
                if (destinationAddresses != null &&
                    j < destinationAddresses.length) {
                  address = destinationAddresses[j];
                }

                results[i + j] = {
                  'distanceKm': distanceMeters / 1000.0,
                  'etaMinutes': (durationSeconds / 60.0).round(),
                  'address': address,
                };
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching bulk road distance: $e");
      }
    }

    return results;
  }
}

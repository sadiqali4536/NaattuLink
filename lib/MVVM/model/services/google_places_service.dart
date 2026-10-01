import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GooglePlacesService {
  static String? _cachedApiKey;
  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Fetch API key from Firestore
  static Future<String?> _getApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('api_keys')
          .get();
      if (doc.exists) {
        _cachedApiKey = doc.data()?['google_maps_key'];
      }
    } catch (e) {
      debugPrint('Error fetching Google Maps API key from config: $e');
    }
    return _cachedApiKey;
  }

  /// Fetch suggestions for the given text
  static Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Google Places API key is missing from config');
      return [];
    }

    try {
      final uri = Uri.parse(
        '$_autocompleteUrl?input=$query&key=$apiKey&components=country:in',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) {
            return {
              'placeId': p['place_id'],
              'description': p['description'],
              'mainText':
                  p['structured_formatting']?['main_text'] ?? p['description'],
              'secondaryText':
                  p['structured_formatting']?['secondary_text'] ?? '',
            };
          }).toList();
        } else {
          debugPrint(
              'Google Places Autocomplete error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      } else {
        debugPrint('Google Places HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Google Places API Error: $e');
      return [];
    }
  }

  /// Fetch details (lat, lng, address, name) for a selected place
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Google Places API key is missing from config');
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_detailsUrl?place_id=$placeId&key=$apiKey&fields=name,formatted_address,geometry',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          return {
            'placeId': placeId,
            'name': result['name'],
            'formattedAddress': result['formatted_address'],
            'latitude': result['geometry']?['location']?['lat'],
            'longitude': result['geometry']?['location']?['lng'],
          };
        } else {
          debugPrint(
              'Google Places Details error: ${data['status']} - ${data['error_message']}');
          return null;
        }
      } else {
        debugPrint('Google Places Details HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Google Places Details API Error: $e');
      return null;
    }
  }
}

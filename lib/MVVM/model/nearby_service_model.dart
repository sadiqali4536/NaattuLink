import 'package:cloud_firestore/cloud_firestore.dart';

class NearbyServiceModel {
  final String id;
  final String category;
  final String? profession; // Healthcare profession etc.
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final double distanceKm;
  final Map<String, dynamic> rawData;

  NearbyServiceModel({
    required this.id,
    required this.category,
    this.profession,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
    required this.distanceKm,
    required this.rawData,
  });

  factory NearbyServiceModel.fromFirestore(
    DocumentSnapshot doc,
    double calculatedDistance,
  ) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return NearbyServiceModel(
      id: doc.id,
      category: data['category']?.toString() ?? data['transport_category']?.toString() ?? '',
      profession: data['profession']?.toString() ?? data['healthcare_type']?.toString(),
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      serviceRadiusKm: (data['serviceRadiusKm'] as num?)?.toDouble() ?? 7.0, // Default to 7km if missing
      distanceKm: calculatedDistance,
      rawData: data,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  final String planId;
  final String name;
  final double price;
  final String currency;
  final String billingPeriod; // monthly, yearly, etc.
  final int durationDays;
  final int maxProducts;
  final bool isActive;
  final int sortOrder;
  final List<String> features;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlanModel({
    required this.planId,
    required this.name,
    required this.price,
    this.currency = 'INR',
    this.billingPeriod = 'monthly',
    this.durationDays = 30,
    required this.maxProducts,
    this.isActive = true,
    this.sortOrder = 0,
    required this.features,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionPlanModel(
      planId: map['planId'] ?? id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'INR',
      billingPeriod: map['billingPeriod'] ?? 'monthly',
      durationDays: map['durationDays'] ?? 30,
      maxProducts: map['maxProducts'] ?? 50,
      isActive: map['isActive'] ?? true,
      sortOrder: map['sortOrder'] ?? 0,
      features: List<String>.from(map['features'] ?? []),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'name': name,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'durationDays': durationDays,
      'maxProducts': maxProducts,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'features': features,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

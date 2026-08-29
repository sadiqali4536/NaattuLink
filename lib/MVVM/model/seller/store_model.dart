import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String storeId;
  final String ownerId;
  final String sellerId;
  final String name;
  final String slug;
  final String description;
  final String? logoUrl;
  final String? logoFileId;
  final String? bannerUrl;
  final String? bannerFileId;
  final String primaryCategoryId;
  final List<String> shippingMethods;
  final Map<String, dynamic>? pickupAddress;
  final String status; // draft, active, inactive, suspended
  final bool isAcceptingOrders;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreModel({
    required this.storeId,
    required this.ownerId,
    required this.sellerId,
    required this.name,
    required this.slug,
    required this.description,
    this.logoUrl,
    this.logoFileId,
    this.bannerUrl,
    this.bannerFileId,
    required this.primaryCategoryId,
    required this.shippingMethods,
    this.pickupAddress,
    this.status = 'active',
    this.isAcceptingOrders = true,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreModel.fromMap(Map<String, dynamic> map, String id) {
    return StoreModel(
      storeId: map['storeId'] ?? id,
      ownerId: map['ownerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      logoFileId: map['logoFileId'],
      bannerUrl: map['bannerUrl'],
      bannerFileId: map['bannerFileId'],
      primaryCategoryId: map['primaryCategoryId'] ?? '',
      shippingMethods: List<String>.from(map['shippingMethods'] ?? []),
      pickupAddress: map['pickupAddress'] as Map<String, dynamic>?,
      status: map['status'] ?? 'active',
      isAcceptingOrders: map['isAcceptingOrders'] ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'ownerId': ownerId,
      'sellerId': sellerId,
      'name': name,
      'slug': slug,
      'description': description,
      'logoUrl': logoUrl,
      'logoFileId': logoFileId,
      'bannerUrl': bannerUrl,
      'bannerFileId': bannerFileId,
      'primaryCategoryId': primaryCategoryId,
      'shippingMethods': shippingMethods,
      'pickupAddress': pickupAddress,
      'status': status,
      'isAcceptingOrders': isAcceptingOrders,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

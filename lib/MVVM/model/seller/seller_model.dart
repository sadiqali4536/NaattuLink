import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String userId;
  final String sellerId;
  final String? storeId;
  final String status; // active, suspended, blocked
  final String registrationStatus; // not_started, in_progress, completed
  final String subscriptionStatus; // trial, active, expired, cancelled

  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  final String fullName;
  final String phoneNumber;
  final String email;
  final String? whatsappNumber;

  final String? aboutBusiness;
  final String? category;
  final String? location;
  final String? storeName;
  final String? sellerName;
  final String? phone;

  final DateTime? storeOpenedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerModel({
    required this.userId,
    required this.sellerId,
    this.storeId,
    this.status = 'active',
    this.registrationStatus = 'not_started',
    this.subscriptionStatus = 'trial',
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.whatsappNumber,
    this.aboutBusiness,
    this.category,
    this.location,
    this.storeName,
    this.sellerName,
    this.phone,
    this.storeOpenedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerModel.fromMap(Map<String, dynamic> map, String id) {
    return SellerModel(
      userId: map['userId'] ?? map['uid'] ?? id,
      sellerId: map['sellerId'] ?? map['uid'] ?? id,
      storeId: map['storeId'],
      status: map['status'] ?? 'active',
      registrationStatus: map['registrationStatus'] ?? 'not_started',
      subscriptionStatus: map['subscriptionStatus'] ?? 'trial',
      trialStartDate: _parseTimestamp(map['trialStartDate']),
      trialEndDate: _parseTimestamp(map['trialEndDate']),
      subscriptionStartDate: _parseTimestamp(map['subscriptionStartDate']),
      subscriptionEndDate: _parseTimestamp(map['subscriptionEndDate']),
      fullName: map['fullName'] ?? map['sellerName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['phone'] ?? '',
      email: map['email'] ?? '',
      whatsappNumber: map['whatsappNumber'],
      aboutBusiness: map['aboutBusiness'],
      category: map['category'],
      location: map['location'],
      storeName: map['storeName'],
      sellerName: map['sellerName'],
      phone: map['phone'],
      storeOpenedAt: _parseTimestamp(map['storeOpenedAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sellerId': sellerId,
      'storeId': storeId,
      'status': status,
      'registrationStatus': registrationStatus,
      'subscriptionStatus': subscriptionStatus,
      'trialStartDate':
          trialStartDate != null ? Timestamp.fromDate(trialStartDate!) : null,
      'trialEndDate':
          trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'subscriptionStartDate': subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'aboutBusiness': aboutBusiness,
      'category': category,
      'location': location,
      'storeName': storeName,
      'sellerName': sellerName,
      'phone': phone,
      'storeOpenedAt':
          storeOpenedAt != null ? Timestamp.fromDate(storeOpenedAt!) : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

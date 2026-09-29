import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String userId;
  final String sellerId;
  final String? storeId;
  final String? sellerPublicId;
  final String? userPublicId;
  final String status; // active, suspended, blocked
  final String registrationStatus; // pending_verification, approved, rejected
  final String subscriptionStatus; // pending, active, expired, cancelled
  
  final bool adminVerified;
  final bool storeAccess;
  
  final String? selectedPlanId;
  final String? selectedPlanName;
  final int? planDurationDays;
  final double? planPrice;

  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? verifiedAt;
  final String? verifiedBy;

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
  final String? upiId;

  final DateTime? storeOpenedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerModel({
    required this.userId,
    required this.sellerId,
    this.storeId,
    this.sellerPublicId,
    this.userPublicId,
    this.status = 'active',
    this.registrationStatus = 'pending_verification',
    this.subscriptionStatus = 'pending',
    this.adminVerified = false,
    this.storeAccess = false,
    this.selectedPlanId,
    this.selectedPlanName,
    this.planDurationDays,
    this.planPrice,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.verifiedAt,
    this.verifiedBy,
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
    this.upiId,
    this.storeOpenedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerModel.fromMap(Map<String, dynamic> map, String id) {
    return SellerModel(
      userId: map['userId'] ?? map['uid'] ?? id,
      sellerId: map['sellerId'] ?? map['uid'] ?? id,
      storeId: map['storeId'],
      sellerPublicId: map['sellerPublicId'],
      userPublicId: map['userPublicId'],
      status: map['status'] ?? 'active',
      registrationStatus: map['registrationStatus'] ?? 'pending_verification',
      subscriptionStatus: map['subscriptionStatus'] ?? 'pending',
      adminVerified: map['adminVerified'] ?? false,
      storeAccess: map['storeAccess'] ?? false,
      selectedPlanId: map['selectedPlanId'],
      selectedPlanName: map['selectedPlanName'],
      planDurationDays: map['planDurationDays'],
      planPrice: (map['planPrice'] ?? 0).toDouble(),
      trialStartDate: _parseTimestamp(map['trialStartDate']),
      trialEndDate: _parseTimestamp(map['trialEndDate']),
      subscriptionStartDate: _parseTimestamp(map['subscriptionStartDate']),
      subscriptionEndDate: _parseTimestamp(map['subscriptionEndDate']),
      verifiedAt: _parseTimestamp(map['verifiedAt']),
      verifiedBy: map['verifiedBy'],
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
      upiId: map['upiId'],
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
      'sellerPublicId': sellerPublicId,
      'userPublicId': userPublicId,
      'status': status,
      'registrationStatus': registrationStatus,
      'subscriptionStatus': subscriptionStatus,
      'adminVerified': adminVerified,
      'storeAccess': storeAccess,
      'selectedPlanId': selectedPlanId,
      'selectedPlanName': selectedPlanName,
      'planDurationDays': planDurationDays,
      'planPrice': planPrice,
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
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
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
      'upiId': upiId,
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

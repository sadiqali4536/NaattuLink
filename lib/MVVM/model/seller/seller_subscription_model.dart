import 'package:cloud_firestore/cloud_firestore.dart';

class SellerSubscriptionModel {
  final String subscriptionId;
  final String sellerId;
  final String userId;
  final String storeId;
  
  final String planId;
  final String planName;
  
  final double amount;
  final String currency;
  
  final String status; // pending, active, expired, cancelled
  final String paymentStatus; // pending, paid, failed
  
  final DateTime? startDate;
  final DateTime? endDate;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerSubscriptionModel({
    required this.subscriptionId,
    required this.sellerId,
    required this.userId,
    required this.storeId,
    required this.planId,
    required this.planName,
    required this.amount,
    this.currency = 'INR',
    this.status = 'active',
    this.paymentStatus = 'paid',
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerSubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SellerSubscriptionModel(
      subscriptionId: map['subscriptionId'] ?? id,
      sellerId: map['sellerId'] ?? '',
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      planId: map['planId'] ?? '',
      planName: map['planName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'INR',
      status: map['status'] ?? 'active',
      paymentStatus: map['paymentStatus'] ?? 'paid',
      startDate: _parseTimestamp(map['startDate']),
      endDate: _parseTimestamp(map['endDate']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'sellerId': sellerId,
      'userId': userId,
      'storeId': storeId,
      'planId': planId,
      'planName': planName,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentStatus': paymentStatus,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

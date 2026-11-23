import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionState {
  active,
  expiringSoon,
  expired,
  renewalPending,
  suspended,
  notStarted,
}

class SellerSubscriptionDetails {
  final String sellerId;
  final String? planId;
  final String planName;
  final int durationDays;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final DateTime? lastRenewedAt;
  final String renewalStatus; // 'none', 'pending', 'approved', 'rejected'
  final String? lastTransactionId;
  final String? lastPaymentMethod;
  final double? lastAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellerSubscriptionDetails({
    required this.sellerId,
    this.planId,
    required this.planName,
    required this.durationDays,
    this.startDate,
    this.expiryDate,
    this.lastRenewedAt,
    this.renewalStatus = 'none',
    this.lastTransactionId,
    this.lastPaymentMethod,
    this.lastAmount,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerSubscriptionDetails.fromMap(
      Map<String, dynamic> map, String sellerId) {
    return SellerSubscriptionDetails(
      sellerId: map['sellerId'] ?? sellerId,
      planId: map['planId'] ?? map['selectedPlanId'],
      planName: map['planName'] ?? map['selectedPlanName'] ?? 'Standard Store Plan',
      durationDays: (map['durationDays'] ?? map['planDurationDays'] ?? 30) as int,
      startDate: _parseTimestamp(map['startDate'] ?? map['subscriptionStartDate']),
      expiryDate: _parseTimestamp(map['expiryDate'] ?? map['subscriptionEndDate']),
      lastRenewedAt: _parseTimestamp(map['lastRenewedAt'] ?? map['approvedAt']),
      renewalStatus: map['renewalStatus'] ?? 'none',
      lastTransactionId: map['lastTransactionId'] ?? map['transactionId'],
      lastPaymentMethod: map['lastPaymentMethod'] ?? map['paymentMethod'],
      lastAmount: (map['lastAmount'] ?? map['planPrice'] ?? map['amount'] ?? 0)?.toDouble(),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'planId': planId,
      'planName': planName,
      'durationDays': durationDays,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'lastRenewedAt':
          lastRenewedAt != null ? Timestamp.fromDate(lastRenewedAt!) : null,
      'renewalStatus': renewalStatus,
      'lastTransactionId': lastTransactionId,
      'lastPaymentMethod': lastPaymentMethod,
      'lastAmount': lastAmount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}


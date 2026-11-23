import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionHistoryModel {
  final String historyId;
  final String sellerId;
  final String planId;
  final String planName;
  final int durationDays;
  final double amount;
  final String actionType; // 'new_subscription', 'renewal', 'admin_extension', 'cancellation'
  final String paymentMethod;
  final String transactionId;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String performedBy; // 'seller', 'admin', 'system'
  final String? adminNotes;
  final DateTime timestamp;

  SubscriptionHistoryModel({
    required this.historyId,
    required this.sellerId,
    required this.planId,
    required this.planName,
    required this.durationDays,
    required this.amount,
    required this.actionType,
    required this.paymentMethod,
    required this.transactionId,
    this.startDate,
    this.expiryDate,
    required this.performedBy,
    this.adminNotes,
    required this.timestamp,
  });

  factory SubscriptionHistoryModel.fromMap(
      Map<String, dynamic> map, String id) {
    return SubscriptionHistoryModel(
      historyId: map['historyId'] ?? id,
      sellerId: map['sellerId'] ?? '',
      planId: map['planId'] ?? '',
      planName: map['planName'] ?? '',
      durationDays: (map['durationDays'] ?? 30) as int,
      amount: (map['amount'] ?? 0)?.toDouble() ?? 0.0,
      actionType: map['actionType'] ?? 'renewal',
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      transactionId: map['transactionId'] ?? '',
      startDate: _parseTimestamp(map['startDate']),
      expiryDate: _parseTimestamp(map['expiryDate']),
      performedBy: map['performedBy'] ?? 'admin',
      adminNotes: map['adminNotes'],
      timestamp: _parseTimestamp(map['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'historyId': historyId,
      'sellerId': sellerId,
      'planId': planId,
      'planName': planName,
      'durationDays': durationDays,
      'amount': amount,
      'actionType': actionType,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'performedBy': performedBy,
      'adminNotes': adminNotes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }
}


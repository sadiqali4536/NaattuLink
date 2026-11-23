import 'package:cloud_firestore/cloud_firestore.dart';

class QueueTokenModel {
  String? id;
  int tokenNumber;
  String userId;
  String userPublicId;
  String? customerName;
  String businessId;
  String businessPublicId;
  String? serviceId;
  String? serviceName;
  String status;
  Timestamp? joinedAt;
  Timestamp? calledAt;
  Timestamp? completedAt;
  Timestamp? cancelledAt;
  int estimatedWaitMinutes;
  String? queueDate;
  String? participantType;
  String? participantCollection;
  String? participantDocumentId;
  String? participantPhone;
  String? participantImage;

  QueueTokenModel({
    this.id,
    required this.tokenNumber,
    required this.userId,
    required this.userPublicId,
    this.customerName,
    this.participantType,
    this.participantCollection,
    this.participantDocumentId,
    this.participantPhone,
    this.participantImage,
    required this.businessId,
    required this.businessPublicId,
    this.serviceId,
    this.serviceName,
    this.status = 'waiting',
    this.joinedAt,
    this.calledAt,
    this.completedAt,
    this.cancelledAt,
    this.estimatedWaitMinutes = 0,
    this.queueDate,
  });

  factory QueueTokenModel.fromJson(String id, Map<String, dynamic> json) {
    return QueueTokenModel(
      id: id,
      tokenNumber: json['tokenNumber'] ?? 0,
      userId: json['userId'] ?? '',
      userPublicId: json['userPublicId'] ?? '',
      customerName: json['customerName'],
      participantType: json['participantType'],
      participantCollection: json['participantCollection'],
      participantDocumentId: json['participantDocumentId'],
      participantPhone: json['participantPhone'],
      participantImage: json['participantImage'],
      businessId: json['businessId'] ?? '',
      businessPublicId: json['businessPublicId'] ?? '',
      serviceId: json['serviceId'],
      serviceName: json['serviceName'],
      status: json['status'] ?? 'waiting',
      joinedAt: json['joinedAt'],
      calledAt: json['calledAt'],
      completedAt: json['completedAt'],
      cancelledAt: json['cancelledAt'],
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
      queueDate: json['queueDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenNumber': tokenNumber,
      'userId': userId,
      'userPublicId': userPublicId,
      if (customerName != null) 'customerName': customerName,
      if (participantType != null) 'participantType': participantType,
      if (participantCollection != null)
        'participantCollection': participantCollection,
      if (participantDocumentId != null)
        'participantDocumentId': participantDocumentId,
      if (participantPhone != null) 'participantPhone': participantPhone,
      if (participantImage != null) 'participantImage': participantImage,
      'businessId': businessId,
      'businessPublicId': businessPublicId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'status': status,
      'joinedAt': joinedAt ?? FieldValue.serverTimestamp(),
      'calledAt': calledAt,
      'completedAt': completedAt,
      'cancelledAt': cancelledAt,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      if (queueDate != null) 'queueDate': queueDate,
    };
  }
}

class QueueStateModel {
  String queueDate;
  int currentToken;
  int nextToken;
  int waitingCount;
  bool isOpen;

  QueueStateModel({
    required this.queueDate,
    required this.currentToken,
    required this.nextToken,
    required this.waitingCount,
    required this.isOpen,
  });

  factory QueueStateModel.fromJson(Map<String, dynamic> json) {
    return QueueStateModel(
      queueDate: json['queueDate'] ?? '',
      currentToken: json['currentToken'] ?? 0,
      nextToken: json['nextToken'] ?? 1,
      waitingCount: json['waitingCount'] ?? 0,
      isOpen: json['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queueDate': queueDate,
      'currentToken': currentToken,
      'nextToken': nextToken,
      'waitingCount': waitingCount,
      'isOpen': isOpen,
    };
  }
}

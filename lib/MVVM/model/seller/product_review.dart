import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReview {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final double rating;
  final String title;
  final String description;
  final String? purchasedVariant;
  final List<String> reviewImages;
  final bool isVerifiedPurchase;
  final DateTime? createdAt;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage = '',
    required this.rating,
    required this.title,
    required this.description,
    this.purchasedVariant,
    this.reviewImages = const [],
    this.isVerifiedPurchase = false,
    this.createdAt,
  });

  factory ProductReview.fromMap(Map<String, dynamic> map, String id) {
    return ProductReview(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userProfileImage: map['userProfileImage'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      purchasedVariant: map['purchasedVariant'],
      reviewImages: List<String>.from(map['reviewImages'] ?? []),
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'rating': rating,
      'title': title,
      'description': description,
      'purchasedVariant': purchasedVariant,
      'reviewImages': reviewImages,
      'isVerifiedPurchase': isVerifiedPurchase,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    return null;
  }
}

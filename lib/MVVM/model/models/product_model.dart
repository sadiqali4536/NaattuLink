import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String title;
  final String description;
  final String category;
  final String subCategory;
  final double price;
  final String image;
  final String sellerId;
  final double rating;
  final bool isTrending;
  final bool isBestSeller;
  final Timestamp createdAt;

  ProductModel({
    required this.productId,
    required this.title,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.price,
    required this.image,
    required this.sellerId,
    required this.rating,
    required this.isTrending,
    required this.isBestSeller,
    required this.createdAt,
  });

  // Factory constructor to create a ProductModel from a Firestore document map
  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductModel(
      productId: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      image: data['image'] ?? '',
      sellerId: data['sellerId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      isTrending: data['isTrending'] ?? false,
      isBestSeller: data['isBestSeller'] ?? false,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert ProductModel to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'price': price,
      'image': image,
      'sellerId': sellerId,
      'rating': rating,
      'isTrending': isTrending,
      'isBestSeller': isBestSeller,
      'createdAt': createdAt,
    };
  }
}

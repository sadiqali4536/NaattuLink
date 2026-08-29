import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final double offerPrice;
  final int quantity;
  final String? variantId;
  final String? variantName;
  final String? sellerId;
  final DateTime addedAt;
  final DateTime updatedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.offerPrice,
    required this.quantity,
    this.variantId,
    this.variantName,
    this.sellerId,
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return CartItemModel(
      id: docId,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      offerPrice: (map['offerPrice'] ?? map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      variantId: map['variantId'],
      variantName: map['variantName'],
      sellerId: map['sellerId'],
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'offerPrice': offerPrice,
      'quantity': quantity,
      'variantId': variantId,
      'variantName': variantName,
      'sellerId': sellerId,
      'addedAt': Timestamp.fromDate(addedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    double? offerPrice,
    int? quantity,
    String? variantId,
    String? variantName,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      quantity: quantity ?? this.quantity,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

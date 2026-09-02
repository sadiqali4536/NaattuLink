import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_variant.dart';

class StoreProductModel {
  final String id;
  final String? sellerId;
  final String? storeId;
  final String? ownerId;
  final String productName;

  final String categoryId;
  final String categoryName;
  final String subcategoryId;
  final String subcategoryName;
  final String productTypeId;
  final String productTypeName;

  final String brand;
  final String description;
  final double price;
  final double discountPrice;

  bool get hasDiscount => discountPrice > 0 && discountPrice < price;
  double get sellingPrice => hasDiscount ? discountPrice : price;
  double get originalPrice => price;
  int get discountPercentage => hasDiscount
      ? ((originalPrice - sellingPrice) / originalPrice * 100).round()
      : 0;

  final List<String> images;
  final List<Map<String, dynamic>> imageMetadata;
  final String coverImage;

  final String sku;
  final int stockQuantity;
  final String unit;

  final String status;

  // New Dynamic Specifications
  final Map<String, dynamic> specifications;

  // Variants
  final bool hasVariants;
  final List<String> variantAttributes;
  final List<ProductVariant> variants;

  // Delivery Information
  final double? weight; // in kg
  final String? dimensions; // e.g. "10x10x5 cm"
  final double? deliveryCharge;
  final String? estimatedDeliveryTime;
  final String? returnPolicy;

  // Rating & Review Aggregates
  final Map<String, dynamic> rating;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreProductModel({
    required this.id,
    this.sellerId,
    this.storeId,
    this.ownerId,
    required this.productName,
    this.categoryId = '',
    this.categoryName = '',
    this.subcategoryId = '',
    this.subcategoryName = '',
    this.productTypeId = '',
    this.productTypeName = '',
    this.brand = '',
    required this.description,
    required this.price,
    required this.discountPrice,
    this.images = const [],
    this.imageMetadata = const [],
    this.coverImage = '',
    this.sku = '',
    this.stockQuantity = 0,
    this.unit = 'Piece',
    this.status = 'active',
    this.specifications = const {},
    this.hasVariants = false,
    this.variantAttributes = const [],
    this.variants = const [],
    this.weight,
    this.dimensions,
    this.deliveryCharge,
    this.estimatedDeliveryTime,
    this.returnPolicy,
    this.rating = const {
      'average': 0.0,
      'totalRatings': 0,
      'totalReviews': 0,
      'breakdown': {}
    },
    this.createdAt,
    this.updatedAt,
  });

  // legacy helpers
  String get category => categoryName;
  String get subcategory => subcategoryName;
  double get averageRating => (rating['average'] ?? 0.0).toDouble();
  int get totalRatings => rating['totalRatings'] ?? 0;
  int get totalReviews => rating['totalReviews'] ?? 0;

  factory StoreProductModel.fromMap(Map<String, dynamic> map, String docId) {
    List<String> parsedImages = [];
    if (map['images'] != null && (map['images'] as List).isNotEmpty) {
      parsedImages = List<String>.from(map['images']);
    } else if (map['imageUrl'] != null &&
        map['imageUrl'].toString().isNotEmpty) {
      parsedImages = [map['imageUrl']];
    }

    // backward compatibility for category/subcategory
    String cId = map['categoryId'] ?? map['category'] ?? '';
    String cName = map['categoryName'] ?? map['category'] ?? '';
    String scId = map['subcategoryId'] ?? map['subcategory'] ?? '';
    String scName = map['subcategoryName'] ?? map['subcategory'] ?? '';

    return StoreProductModel(
      id: docId,
      sellerId: map['sellerId'] ?? map['ownerId'] ?? map['storeId'],
      storeId: map['storeId'],
      ownerId: map['ownerId'],
      productName: map['productName'] ?? '',
      categoryId: cId,
      categoryName: cName,
      subcategoryId: scId,
      subcategoryName: scName,
      productTypeId: map['productTypeId'] ?? '',
      productTypeName: map['productTypeName'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      price:
          (map['originalPrice'] ?? map['original_price'] ?? map['price'] ?? 0)
              .toDouble(),
      discountPrice:
          (map['discountPrice'] ?? map['discount_price'] ?? map['price'] ?? 0)
              .toDouble(),
      images: parsedImages,
      imageMetadata: (map['imageMetadata'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      coverImage: map['coverImage'] ??
          (parsedImages.isNotEmpty ? parsedImages.first : ''),
      sku: map['sku'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      unit: map['unit'] ?? 'Piece',
      status: map['status'] ?? 'active',
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      hasVariants: map['hasVariants'] ??
          (map['variants'] != null && (map['variants'] as List).isNotEmpty),
      variantAttributes: List<String>.from(map['variantAttributes'] ?? []),
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(
                  Map<String, dynamic>.from(v), v['id'] ?? ''))
              .toList() ??
          [],
      weight: map['weight'] != null ? (map['weight']).toDouble() : null,
      dimensions: map['dimensions'],
      deliveryCharge: map['deliveryCharge'] != null
          ? (map['deliveryCharge']).toDouble()
          : null,
      estimatedDeliveryTime: map['estimatedDeliveryTime'],
      returnPolicy: map['returnPolicy'],
      rating: Map<String, dynamic>.from(map['rating'] ??
          {
            'average': map['averageRating'] ?? 0.0,
            'totalRatings': map['totalRatings'] ?? 0,
            'totalReviews': map['totalReviews'] ?? 0,
            'breakdown': map['ratingBreakdown'] ?? {},
          }),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'storeId': storeId,
      'ownerId': ownerId,
      'productName': productName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subcategoryId': subcategoryId,
      'subcategoryName': subcategoryName,
      'productTypeId': productTypeId,
      'productTypeName': productTypeName,

      // legacy fields
      'category': categoryName,
      'subcategory': subcategoryName,

      'brand': brand,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'images': images,
      'imageMetadata': imageMetadata,
      'coverImage': coverImage.isNotEmpty
          ? coverImage
          : (images.isNotEmpty ? images.first : ''),
      'imageUrl': images.isNotEmpty ? images.first : '', // Legacy fallback
      'sku': sku,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'status': status,
      'specifications': specifications,
      'hasVariants': hasVariants,
      'variantAttributes': variantAttributes,
      'variants': variants.map((v) => v.toMap()).toList(),

      'delivery': {
        'weight': weight,
        'dimensions': dimensions,
        'deliveryCharge': deliveryCharge,
        'estimatedDeliveryTime': estimatedDeliveryTime,
        'returnPolicy': returnPolicy,
      },

      // flat delivery fields for backward compat
      'weight': weight,
      'dimensions': dimensions,
      'deliveryCharge': deliveryCharge,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'returnPolicy': returnPolicy,

      'rating': rating,

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

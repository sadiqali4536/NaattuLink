class ProductVariant {
  final String id;
  final String sku;
  final Map<String, dynamic> attributes; // e.g. {'Size': 'M', 'Color': 'Black'}
  final double price;
  final double discountPrice;
  final int stockQuantity;
  final bool isAvailable;
  final List<String> images;

  bool get hasDiscount => discountPrice > 0 && discountPrice < price;
  double get sellingPrice => hasDiscount ? discountPrice : price;
  double get originalPrice => price;
  int get discountPercentage => hasDiscount
      ? ((originalPrice - sellingPrice) / originalPrice * 100).round()
      : 0;

  String? get image => images.isNotEmpty ? images.first : null;

  ProductVariant({
    required this.id,
    this.sku = '',
    required this.attributes,
    required this.price,
    required this.discountPrice,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.images = const [],
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map, String id) {
    return ProductVariant(
      id: id,
      sku: map['sku'] ?? '',
      attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      price: (map['price'] ?? 0).toDouble(),
      discountPrice: (map['discountPrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      images: List<String>.from(map['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'attributes': attributes,
      'price': price,
      'discountPrice': discountPrice,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'images': images,
    };
  }
}

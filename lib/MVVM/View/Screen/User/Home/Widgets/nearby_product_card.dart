import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';

class NearbyProductCard extends StatelessWidget {
  final StoreProductModel product;

  const NearbyProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Math for discount percentage
    int discountPercentage = 0;
    if (product.price > 0 &&
        product.discountPrice < product.price &&
        product.discountPrice > 0) {
      discountPercentage =
          (((product.price - product.discountPrice) / product.price) * 100)
              .round();
    }

    // Fallback images
    String imageUrl = product.images.isNotEmpty ? product.images.first : '';
    if (imageUrl.isEmpty && product.coverImage.isNotEmpty) {
      imageUrl = product.coverImage;
    }

    int actualStock = product.stockQuantity;
    if (product.hasVariants && product.variants.isNotEmpty) {
      actualStock = product.variants.fold(0, (sum, v) => sum + v.stockQuantity);
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and wishlist icon
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey),
                      )
                    : const Icon(Icons.image_not_supported,
                        size: 50, color: Colors.grey),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand name
                  Text(
                    product.brand.isNotEmpty
                        ? product.brand.toUpperCase()
                        : product.productName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Description/Subtitle
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : product.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Rating Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.averageRating > 0
                              ? product.averageRating.toStringAsFixed(1)
                              : '4.5',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, color: Colors.green, size: 12),
                        const SizedBox(width: 4),
                        const Text('Seller',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Pricing Row
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        if (discountPercentage > 0) ...[
                          const Icon(Icons.arrow_downward,
                              color: Colors.green, size: 14),
                          Text(
                            '$discountPercentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${product.price.toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '₹${product.discountPrice > 0 ? product.discountPrice.toInt() : product.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scarcity text
                  if (actualStock <= 0) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Out of Stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ] else if (actualStock < 10) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Only few left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

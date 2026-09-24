import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import '../../product/product_details_page.dart';
import 'themed_product_section.dart';

class ThemedProductCard extends StatelessWidget {
  final StoreProductModel product;
  final SectionTheme theme;

  const ThemedProductCard({
    super.key,
    required this.product,
    required this.theme,
  });

  void _onTap(BuildContext context) {
    Get.to(() => ProductDetailsPage(product: product));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: switch (theme) {
        SectionTheme.treats => _buildTreatsCard(),
        SectionTheme.brands => _buildBrandsCard(),
        SectionTheme.valueDeals => _buildValueDealsCard(),
        SectionTheme.topPicks => _buildTopPicksCard(),
        SectionTheme.nearby => _buildNearbyCard(),
      },
    );
  }

  String get _imageUrl {
    if (product.coverImage.isNotEmpty) return product.coverImage;
    if (product.images.isNotEmpty) return product.images.first;
    return 'assets/image/add_image.png';
  }

  Widget _buildTreatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                if (product.hasDiscount)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        "↓${product.discountPercentage.round()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "AD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.hasDiscount
              ? "Min. ${product.discountPercentage.round()}% Off"
              : "From ₹${product.sellingPrice.round()}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          product.category.isNotEmpty ? product.category : product.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildValueDealsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildImage(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.category.isNotEmpty ? product.category : "Product",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(
          "Under ₹${(product.sellingPrice + 100).round()}",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPicksCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[100],
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildImage(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.productName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
        Text(
          product.hasDiscount
              ? "Min. ${product.discountPercentage.round()}% Off"
              : "From ₹${product.sellingPrice.round()}",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImage()),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Deals",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  product.hasDiscount
                      ? "Special offer"
                      : "Under ₹${(product.sellingPrice + 50).round()}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return (product.coverImage.startsWith('http') ||
            product.coverImage.startsWith('https'))
        ? Image.network(
            _imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/image/add_image.png', fit: BoxFit.cover),
          )
        : Image.asset(
            'assets/image/car_clean.png',
            fit: BoxFit.cover,
          );
  }
}

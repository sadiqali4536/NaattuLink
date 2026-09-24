import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'store_section_header.dart';
import 'store_product_card.dart';
import 'package:get/get.dart';
import '../../product/product_details_page.dart';

class HorizontalProductSection extends StatelessWidget {
  final String title;
  final List<StoreProductModel> products;
  final VoidCallback? onSeeAll;
  final bool isLoading;
  final String badgeType; // e.g. 'AD', 'BESTSELLER', 'TOP DEAL', 'NEARBY'

  const HorizontalProductSection({
    Key? key,
    required this.title,
    required this.products,
    this.onSeeAll,
    this.isLoading = false,
    this.badgeType = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading && products.isEmpty) {
      return const SizedBox.shrink(); // Hide if empty and not loading
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoreSectionHeader(
          title: title,
          onSeeAll: onSeeAll,
        ),
        SizedBox(
          height: 195, // Fixed height for horizontal list to avoid unbounded height issues
          child: isLoading
              ? _buildSkeleton()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return SizedBox(
                      width: 150, // Fixed width for horizontal cards
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() => ProductDetailsPage(product: product));
                        },
                        child: StoreProductCard(
                          product: product,
                          badgeOverride: _determineBadge(product),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String? _determineBadge(StoreProductModel product) {
    if (badgeType == 'AD' && product.isFeatured) {
      return 'AD';
    } else if (badgeType == 'BESTSELLER') {
      return 'BESTSELLER';
    } else if (badgeType == 'TOP DEAL') {
      return 'TOP DEAL';
    } else if (badgeType == 'NEARBY') {
      return 'NEARBY';
    }
    return null;
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return Container(
          width: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

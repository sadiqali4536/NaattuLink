import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'home_card_system.dart';

class SuggestedProductGrid extends StatelessWidget {
  final List<StoreProductModel> products;
  final bool isLoading;
  final String? searchQuery;

  const SuggestedProductGrid({
    super.key,
    required this.products,
    this.isLoading = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    final String subtitle = (searchQuery != null && searchQuery!.isNotEmpty)
        ? "Based on your search for '$searchQuery'"
        : 'Updated daily for you';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DynamicSectionHeader(
          title: 'Suggested For You',
          subtitle: subtitle,
        ),
        isLoading
            ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (_, __) => const ProductCardSkeleton(),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) => DynamicProductCard(
                  product: products[index],
                  showRating: true,
                  showBadge: true,
                ),
              ),
      ],
    );
  }
}

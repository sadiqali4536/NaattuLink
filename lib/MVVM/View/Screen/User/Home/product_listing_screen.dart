import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/user/product_listing_controller.dart';
import 'Widgets/store_product_card.dart';
import 'Widgets/horizontal_product_section.dart';
import 'Widgets/featured_product_banner_carousel.dart';
import '../product/product_details_page.dart';
import 'product_search_page.dart';

import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/viewmodel/cart_controller.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'popular_nearby_screen.dart';

class ProductListingScreen extends StatefulWidget {
  final String? initialCategory;
  final StoreProductModel? highlightedProduct;

  const ProductListingScreen({
    Key? key,
    this.initialCategory,
    this.highlightedProduct,
  }) : super(key: key);

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final ProductListingController controller =
      Get.put(ProductListingController());
  final ScrollController _scrollController = ScrollController();

  final List<String> categories = [
    'All',
    'Grocery',
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Footwear',
    'Toys',
    'Jewellery'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        controller.loadMoreProducts();
      }
    });
    if (widget.initialCategory != null || widget.highlightedProduct != null) {
      // Use microtask or addPostFrameCallback to ensure controller is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setInitialData(
            widget.initialCategory ?? 'All', widget.highlightedProduct);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2E5A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Color(0xFF0F2E5A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ProductSearchPage()),
            );
          },
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, color: Color(0xFF9AA5B4), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Search products, brands...",
                    style: TextStyle(color: Color(0xFF9AA5B4), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CartPage()));
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2E5A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 20),
                    Obx(() {
                      final cartController = Get.put(CartController());
                      if (cartController.totalItemCount > 0) {
                        return Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '${cartController.totalItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshProducts,
        child: Obx(() {
          final isSearching = controller.searchQuery.value.trim().isNotEmpty;
          final Set<String> displayedIds = {};

          List<Widget> buildGridSection(
              String title, List<StoreProductModel> items, bool isLoading) {
            final filtered =
                items.where((p) => !displayedIds.contains(p.id)).toList();
            if (filtered.isEmpty && !isLoading) return [];
            for (var p in filtered) {
              if (p.id != null) displayedIds.add(p.id!);
            }
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF082B63),
                    ),
                  ),
                ),
              ),
              if (isLoading && filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.90,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = filtered[index];
                        return StoreProductCard(
                          product: product,
                          onTap: () {
                            if (title == 'Popular Near You') {
                              String cat = product.categoryName.isNotEmpty
                                  ? product.categoryName
                                  : product.subcategoryName;
                              if (cat.isEmpty) cat = product.productName;
                              Get.to(() => PopularNearbyScreen(category: cat, clickedProduct: product));
                            } else {
                              Get.to(
                                  () => ProductDetailsPage(product: product));
                            }
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ];
          }

          final list = controller.displayProducts;
          final displayList = isSearching
              ? list
                  .where((p) =>
                      p.productName.toLowerCase().contains(
                          controller.searchQuery.value.toLowerCase()) ||
                      p.brand.toLowerCase().contains(
                          controller.searchQuery.value.toLowerCase()) ||
                      p.description
                          .toLowerCase()
                          .contains(controller.searchQuery.value.toLowerCase()))
                  .toList()
              : list;

          final bool isAllEmpty = displayList.isEmpty &&
              controller.featuredItems.isEmpty &&
              controller.topPickItems.isEmpty &&
              controller.similarItems.isEmpty &&
              controller.nearbyItems.isEmpty &&
              controller.suggestedItems.isEmpty;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Discount Filter Chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children:
                        ['All', '50% or more', '50% or less'].map((filter) {
                      final isSelected =
                          controller.selectedDiscountFilter.value == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              controller.setDiscountFilter(filter),
                          selectedColor: const Color(0xFF082B63),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF082B63)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (!isSearching)
                SliverToBoxAdapter(
                  child: FeaturedProductBannerCarousel(
                    products: controller.featuredItems,
                    isLoading: controller.isFeaturedLoading.value,
                  ),
                ),

              if (!controller.isLoading.value && isAllEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try another search or category.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!isSearching) ...[
                // Explore Similar Trends
                ...buildGridSection(
                  'Explore Similar Trends',
                  controller.similarItems,
                  controller.isSimilarLoading.value,
                ),
              ],

              // More From This Category (Search Results)
              ...buildGridSection(
                isSearching ? 'Search Results' : 'More From This Category',
                displayList,
                controller.isLoading.value,
              ),

              if (!isSearching) ...[
                // Popular Near You
                ...buildGridSection(
                  'Popular Near You',
                  controller.nearbyItems.where((p) {
                    final selectedCatLower = controller.selectedCategory.value.trim().toLowerCase();
                    if (selectedCatLower == 'all') return true;
                    final productCatLower = p.categoryName.trim().toLowerCase();
                    final productSubCatLower = p.subcategoryName.trim().toLowerCase();
                    return productCatLower != selectedCatLower && productSubCatLower != selectedCatLower;
                  }).toList(),
                  controller.isNearbyLoading.value,
                ),

                // You May Also Like
                ...buildGridSection(
                  'You May Also Like',
                  controller.suggestedItems,
                  controller.isSuggestedLoading.value,
                ),
              ],

              // Loading More Indicator
              SliverToBoxAdapter(
                child: () {
                  if (controller.isLoadingMore.value) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!controller.hasMore.value && displayList.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "You've reached the end",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 40);
                }(),
              ),
            ],
          );
        }),
      ),
    );
  }
}

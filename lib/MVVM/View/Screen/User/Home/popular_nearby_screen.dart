import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:naattulink/MVVM/controller/user/product_listing_controller.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/viewmodel/cart_controller.dart';
import 'Widgets/nearby_product_card.dart';
import '../product/product_details_page.dart';
import 'product_search_page.dart';

class PopularNearbyScreen extends StatelessWidget {
  final String? category;
  final StoreProductModel? clickedProduct;

  const PopularNearbyScreen({Key? key, this.category, this.clickedProduct})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Attempt to find the existing controller, or put a new one if somehow missing
    final ProductListingController controller =
        Get.put(ProductListingController());
    final CartController cartController = Get.put(CartController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 22, color: Color(0xFF0F2E5A)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: "Search products, brands...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onTap: () {
                        Get.to(() => const ProductSearchPage());
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartPage()));
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F2E5A),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined,
                            color: Colors.white, size: 20),
                        Obx(() {
                          final cartCtrl = Get.find<CartController>();
                          if (cartCtrl.totalItemCount > 0) {
                            return Positioned(
                              top: 6,
                              right: 6,
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
                                  '${cartCtrl.totalItemCount}',
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
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isNearbyLoading.value &&
            controller.nearbyItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        List<StoreProductModel> baseItems = controller.nearbyItems;
        if (baseItems.isEmpty) {
          baseItems = controller.displayProducts;
        }

        List<StoreProductModel> displayItems = [];

        if (category != null && category!.isNotEmpty) {
          final catLower = category!.trim().toLowerCase();

          var similarNearby = baseItems
              .where((p) =>
                  p.categoryName.toLowerCase() == catLower ||
                  p.subcategoryName.toLowerCase() == catLower ||
                  p.productName.toLowerCase().contains(catLower))
              .toList();

          if (similarNearby.isEmpty && baseItems == controller.nearbyItems) {
            // Fallback to all displayProducts if no nearby items match the category
            similarNearby = controller.displayProducts
                .where((p) =>
                    p.categoryName.toLowerCase() == catLower ||
                    p.subcategoryName.toLowerCase() == catLower ||
                    p.productName.toLowerCase().contains(catLower))
                .toList();
          }

          final Set<String> similarIds = similarNearby.map((e) => e.id).toSet();
          final otherNearby =
              baseItems.where((p) => !similarIds.contains(p.id)).toList();

          displayItems = [...similarNearby, ...otherNearby];
        } else {
          displayItems = baseItems;
        }

        if (clickedProduct != null) {
          displayItems.removeWhere((p) => p.id == clickedProduct!.id);
          displayItems.insert(0, clickedProduct!);
        }

        if (displayItems.isEmpty) {
          return const Center(child: Text('No nearby products found.'));
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65, // Adjusted to reduce bottom empty space
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final product = displayItems[index];
            return GestureDetector(
              onTap: () {
                Get.to(() => ProductDetailsPage(product: product));
              },
              child: NearbyProductCard(product: product),
            );
          },
        );
      }),
    );
  }
}

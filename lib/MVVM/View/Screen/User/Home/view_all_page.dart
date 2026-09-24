import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/product_search_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/viewmodel/cart_controller.dart';
import 'package:naattulink/MVVM/View/Screen/User/product/product_details_page.dart';

class ViewAllPage extends StatelessWidget {
  final String title;
  final List<DocumentSnapshot> products;

  const ViewAllPage({
    Key? key,
    required this.title,
    required this.products,
  }) : super(key: key);

  static const _primary = Color(0xFF0F2E5A);

  @override
  Widget build(BuildContext context) {
    // Ensure CartController is available
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: _primary, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductSearchPage(),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              // Navigate to bottom navigation bar cart section (index 1)
              Get.offAll(() => const user_Dashboard(initialIndex: 1));
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              alignment: Alignment.center,
              child: Obx(() {
                final cartCount = Get.find<CartController>().totalItemCount;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: _primary, size: 26),
                    if (cartCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(
              child: Text("No products found"),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final doc = products[index];
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return const SizedBox();
                final product = StoreProductModel.fromMap(data, doc.id);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(
                          product: product,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: product.coverImage.isNotEmpty
                                ? Image.network(
                                    product.coverImage,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/image/add_image.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/image/add_image.png',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "₹${product.sellingPrice.round()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (product.hasDiscount) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      "₹${product.originalPrice.round()}",
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (product.hasDiscount) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "${product.discountPercentage.round()}% OFF",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

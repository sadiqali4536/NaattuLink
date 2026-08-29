import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/model/seller/product_variant.dart';
import 'package:naattulink/MVVM/model/seller/product_review.dart';
import 'package:naattulink/MVVM/viewmodel/cart_controller.dart';
import 'package:naattulink/MVVM/View/Screen/location/location_selection_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/confirm_details_page.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';

class ProductDetailsPage extends StatefulWidget {
  final StoreProductModel product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartController cartController =
      Get.put(CartController(), permanent: true);
  ProductVariant? selectedVariant;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.product.hasVariants && widget.product.variants.isNotEmpty) {
      selectedVariant = widget.product.variants.first;
    }
  }

  bool get hasDiscount =>
      selectedVariant?.hasDiscount ?? widget.product.hasDiscount;
  double get displayPrice =>
      selectedVariant?.sellingPrice ?? widget.product.sellingPrice;
  double get displayOriginalPrice =>
      selectedVariant?.originalPrice ?? widget.product.originalPrice;
  int get displayDiscountPercentage =>
      selectedVariant?.discountPercentage ?? widget.product.discountPercentage;

  int get displayStock =>
      selectedVariant?.stockQuantity ?? widget.product.stockQuantity;
  List<String> get displayImages {
    if (selectedVariant != null && selectedVariant!.images.isNotEmpty) {
      return selectedVariant!.images;
    }
    if (widget.product.images.isNotEmpty) {
      return widget.product.images;
    }
    if (widget.product.coverImage.isNotEmpty) {
      return [widget.product.coverImage];
    }
    return []; // fallback
  }

  Future<bool> _showLocationBottomSheet() async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const LocationSelectionPage(),
        ),
      ),
    );
    return success == true;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final bgLight = const Color(0xFFF8FAFC);
    final textGrey = const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Header / Carousel
                  Stack(
                    children: [
                      Container(
                        height: 350,
                        width: double.infinity,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.white.withOpacity(0.9),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.9, 1.0],
                          ),
                        ),
                        child: displayImages.isNotEmpty
                            ? PageView.builder(
                                itemCount: displayImages.length,
                                onPageChanged: (index) =>
                                    setState(() => currentImageIndex = index),
                                itemBuilder: (context, index) {
                                  final img = displayImages[index];
                                  return (img.startsWith('http') ||
                                          img.startsWith('https'))
                                      ? Image.network(img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              _errorIcon(bgLight, primaryColor))
                                      : Image.asset(img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => _errorIcon(
                                              bgLight, primaryColor));
                                },
                              )
                            : _errorIcon(bgLight, primaryColor),
                      ),
                      if (displayImages.length > 1)
                        Positioned(
                          bottom: 70,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(displayImages.length, (index) {
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: currentImageIndex == index ? 10 : 8,
                                height: currentImageIndex == index ? 10 : 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentImageIndex == index
                                      ? primaryColor
                                      : Colors.grey.withOpacity(0.5),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  // Product Info Card
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Price Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.product.brand.isNotEmpty)
                                  Text(
                                    widget.product.brand.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.product.productName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B),
                                      height: 1.3),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "₹${displayPrice.toInt()}",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        "₹${displayOriginalPrice.toInt()}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "${displayDiscountPercentage}% OFF",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery details Section
                          const Text("Delivery details",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Address
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                        0xFFF0F5FF), // Light blue tint
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.home_outlined,
                                          size: 20, color: Color(0xFF1E293B)),
                                      const SizedBox(width: 8),
                                      const Text("HOME ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B))),
                                      Expanded(
                                        child: Obx(() {
                                          final loc = LocationController
                                              .to.currentLocationModel.value;
                                          final addr = loc?.formattedAddress ??
                                              "No saved address found.";
                                          return Text(addr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF64748B)));
                                        }),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          size: 20, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.white),
                                // Delivery status
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_shipping_outlined,
                                          size: 20,
                                          color: displayStock > 0
                                              ? Colors.green
                                              : const Color(0xFF1E293B)),
                                      const SizedBox(width: 8),
                                      Text(
                                        displayStock > 0
                                            ? "Deliverable at your location"
                                            : "Not deliverable at your location",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.white),
                                // Seller info
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.storefront_outlined,
                                          size: 20, color: Color(0xFF64748B)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Fulfilled by ${widget.product.brand.isNotEmpty ? widget.product.brand : 'Seller'}",
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF1E293B)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text("Verified Seller",
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600])),
                                            const SizedBox(height: 4),
                                            const Text("See other sellers",
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF2956D3),
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Features Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFeatureIcon(
                                  Icons.assignment_return_outlined,
                                  "10-Day\nReturn"),
                              _buildFeatureIcon(Icons.currency_rupee_outlined,
                                  "No cash\non delivery"),
                              _buildFeatureIcon(Icons.support_agent_outlined,
                                  "Customer\nsupport"),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Divider(color: Colors.grey[200], thickness: 1),
                          const SizedBox(height: 16),

                          // Variants
                          if (widget.product.hasVariants &&
                              widget.product.variants.isNotEmpty) ...[
                            const Text("Select Variant",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B))),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: widget.product.variants.map((variant) {
                                final isSelected = selectedVariant == variant;
                                final label =
                                    variant.attributes.values.join(' / ');
                                return ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedVariant = variant;
                                        currentImageIndex = 0; // reset carousel
                                      });
                                    }
                                  },
                                  selectedColor: primaryColor,
                                  labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Dynamic Specifications Table
                          // Dynamic Specifications Table
                          if (widget.product.specifications.isNotEmpty)
                            _buildExpandableSection(
                              title: "Product highlights",
                              initiallyExpanded: true,
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: widget.product.specifications.length,
                                itemBuilder: (context, index) {
                                  final entry = widget
                                      .product.specifications.entries
                                      .elementAt(index);
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.key,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.value is List
                                            ? (entry.value as List).join(', ')
                                            : entry.value.toString(),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1E293B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                          // Description
                          if (widget.product.description.isNotEmpty)
                            _buildExpandableSection(
                              title: "All details",
                              subtitle: "Features, description and more",
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.product.description,
                                    style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: textGrey)),
                              ),
                            ),

                          // Ratings & Reviews
                          _buildExpandableSection(
                            title: "Ratings and reviews",
                            subtitle: widget.product.totalReviews == 0
                                ? "No ratings for this product yet"
                                : null,
                            child: Column(
                              children: [
                                if (widget.product.totalReviews > 0)
                                  Row(
                                    children: [
                                      Text(
                                          widget.product.averageRating
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                              children: List.generate(
                                                  5,
                                                  (index) => Icon(Icons.star,
                                                      color: index <
                                                              widget.product
                                                                  .averageRating
                                                          ? Colors.amber
                                                          : Colors.grey[300],
                                                      size: 20))),
                                          const SizedBox(height: 4),
                                          Text(
                                              "${widget.product.totalRatings} Ratings, ${widget.product.totalReviews} Reviews",
                                              style:
                                                  TextStyle(color: textGrey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('store_products')
                                      .doc(widget.product.id)
                                      .collection('reviews')
                                      .orderBy('createdAt', descending: true)
                                      .limit(10)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    if (!snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      return const SizedBox(); // subtitle handles empty state
                                    }

                                    final reviews = snapshot.data!.docs
                                        .map((d) => ProductReview.fromMap(
                                            d.data() as Map<String, dynamic>,
                                            d.id))
                                        .toList();

                                    return Column(
                                      children: [
                                        ...reviews.map((r) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                          radius: 16,
                                                          backgroundImage: r
                                                                  .userProfileImage
                                                                  .isNotEmpty
                                                              ? NetworkImage(r
                                                                  .userProfileImage)
                                                              : null,
                                                          child:
                                                              r.userProfileImage
                                                                      .isEmpty
                                                                  ? const Icon(
                                                                      Icons
                                                                          .person,
                                                                      size: 16)
                                                                  : null),
                                                      const SizedBox(width: 8),
                                                      Text(r.userName,
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      if (r
                                                          .isVerifiedPurchase) ...[
                                                        const SizedBox(
                                                            width: 4),
                                                        const Icon(
                                                            Icons.verified,
                                                            color: Colors.green,
                                                            size: 14),
                                                      ]
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                      children: List.generate(
                                                          5,
                                                          (i) => Icon(
                                                              Icons.star,
                                                              color: i <
                                                                      r.rating
                                                                  ? Colors.amber
                                                                  : Colors.grey[
                                                                      300],
                                                              size: 14))),
                                                  const SizedBox(height: 4),
                                                  if (r.title.isNotEmpty)
                                                    Text(r.title,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13)),
                                                  Text(r.description,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[800],
                                                          fontSize: 13)),
                                                  const Divider(),
                                                ],
                                              ),
                                            )),
                                        if (widget.product.totalReviews > 10)
                                          TextButton(
                                            onPressed:
                                                () {}, // Pagination logic can be added here
                                            child:
                                                const Text("See All Reviews"),
                                          )
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 100), // padding for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(top: 40, left: 20, child: AppBackButton()),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
          child: Obx(() {
            final hasAddress =
                LocationController.to.currentLocationModel.value != null;
            final isInCart = cartController.cartItems
                .any((item) => item.productId == widget.product.id);

            return Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: displayStock > 0
                        ? () async {
                            if (isInCart) {
                              Get.offAll(
                                  () => const user_Dashboard(initialIndex: 1));
                            } else {
                              if (!hasAddress) {
                                final success =
                                    await _showLocationBottomSheet();
                                if (success) {
                                  cartController.addToCart(
                                    widget.product,
                                    variant: selectedVariant,
                                  );
                                }
                              } else {
                                cartController.addToCart(
                                  widget.product,
                                  variant: selectedVariant,
                                );
                              }
                            }
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(isInCart ? "Go to cart" : "Add to cart",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final tempItem = CartItemModel(
                        id: widget.product.id,
                        productId: widget.product.id,
                        productName: widget.product.productName,
                        productImage:
                            selectedVariant?.image ?? widget.product.coverImage,
                        price: selectedVariant?.price ?? widget.product.price,
                        offerPrice: selectedVariant?.discountPrice ??
                            widget.product.discountPrice,
                        quantity: 1,
                        variantId: selectedVariant?.id,
                        variantName: selectedVariant != null
                            ? selectedVariant!.attributes.values.join(' - ')
                            : null,
                        addedAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      if (!hasAddress) {
                        final success = await _showLocationBottomSheet();
                        if (success) {
                          Get.to(() => ConfirmDetailsPage(
                                cartItems: [tempItem],
                                isFromCart: false,
                              ));
                        }
                      } else {
                        Get.to(() => ConfirmDetailsPage(
                              cartItems: [tempItem],
                              isFromCart: false,
                            ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2956D3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: const Text("Buy Now",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _errorIcon(Color bg, Color primary) {
    return Container(
      color: bg,
      child: Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 80, color: primary.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    String? subtitle,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

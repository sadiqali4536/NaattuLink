import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

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
  String? selectedSimpleVariant;
  int currentImageIndex = 0;
  Map<String, String> selectedAttributes = {};

  DocumentSnapshot? latestProductDoc;
  StreamSubscription? _productSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.product.hasVariants) {
      if (widget.product.variants.isNotEmpty) {
        selectedVariant = widget.product.variants.first;
        if (selectedVariant!.attributes.isNotEmpty) {
          final firstAttrKey = selectedVariant!.attributes.keys.first;
          selectedAttributes[firstAttrKey] =
              selectedVariant!.attributes[firstAttrKey].toString();
        }
      } else if (widget.product.variantAttributes.isNotEmpty) {
        selectedSimpleVariant = widget.product.variantAttributes.first;
      }
    }

    _productSubscription = FirebaseFirestore.instance
        .collection('store_products')
        .doc(widget.product.id)
        .snapshots()
        .listen((doc) {
      if (mounted && doc.exists) {
        setState(() {
          latestProductDoc = doc;
        });
      }
    });
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }

  bool get hasDiscount =>
      selectedVariant?.hasDiscount ?? widget.product.hasDiscount;
  double get displayPrice =>
      selectedVariant?.sellingPrice ?? widget.product.sellingPrice;
  double get displayOriginalPrice =>
      selectedVariant?.originalPrice ?? widget.product.originalPrice;
  int get displayDiscountPercentage =>
      selectedVariant?.discountPercentage ?? widget.product.discountPercentage;

  int get displayStock {
    if (latestProductDoc != null) {
      final data = latestProductDoc!.data() as Map<String, dynamic>;
      if (selectedVariant != null) {
        final variantsList = data['variants'] as List<dynamic>?;
        if (variantsList != null) {
          for (var v in variantsList) {
            if (v['id'] == selectedVariant!.id) {
              return v['stockQuantity'] ?? 0;
            }
          }
        }
      }
      return data['stockQuantity'] ?? 0;
    }
    return selectedVariant?.stockQuantity ?? widget.product.stockQuantity;
  }

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
    // Fallback for Hot Reload: if state is uninitialized, initialize it here
    if (widget.product.hasVariants &&
        selectedVariant == null &&
        selectedSimpleVariant == null &&
        selectedAttributes.isEmpty) {
      if (widget.product.variants.isNotEmpty) {
        selectedVariant = widget.product.variants.first;
        if (selectedVariant!.attributes.isNotEmpty) {
          final firstAttrKey = selectedVariant!.attributes.keys.first;
          selectedAttributes[firstAttrKey] =
              selectedVariant!.attributes[firstAttrKey].toString();
        }
      } else if (widget.product.variantAttributes.isNotEmpty) {
        selectedSimpleVariant = widget.product.variantAttributes.first;
      }
    }

    final primaryColor = const Color(0xFF0F2E5A);
    final bgLight = const Color(0xFFF8FAFC);
    final textGrey = const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header / Carousel
              Column(
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    child: displayImages.isNotEmpty
                        ? PageView.builder(
                            itemCount: displayImages.length,
                            onPageChanged: (index) =>
                                setState(() => currentImageIndex = index),
                            itemBuilder: (context, index) {
                              final img = displayImages[index];
                              return (img.startsWith('http') ||
                                      img.startsWith('https'))
                                  ? CachedNetworkImage(
                                      imageUrl: img,
                                      fit: BoxFit.contain,
                                      errorWidget: (c, e, s) =>
                                          _errorIcon(bgLight, primaryColor),
                                    )
                                  : Image.asset(img,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) =>
                                          _errorIcon(bgLight, primaryColor));
                            },
                          )
                        : _errorIcon(bgLight, primaryColor),
                  ),
                  if (displayImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(displayImages.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
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
                offset: const Offset(0, -10),
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
                            if (widget.product.productName.isNotEmpty)
                              Text(
                                widget.product.productName,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F2E5A),
                                  height: 1.2,
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (widget.product.brand.isNotEmpty)
                              Text(
                                widget.product.brand,
                                style: TextStyle(
                                  fontSize:
                                      widget.product.brand.isNotEmpty ? 16 : 28,
                                  fontWeight: widget.product.brand.isNotEmpty
                                      ? FontWeight.w500
                                      : FontWeight.w900,
                                  color: widget.product.brand.isNotEmpty
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF0F2E5A),
                                  height: 1.3,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "₹${displayPrice.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 28,
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
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${displayDiscountPercentage}% OFF",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (displayStock > 0 && displayStock <= 5) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Only $displayStock left in stock",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else if (displayStock <= 0) ...[
                              const SizedBox(height: 8),
                              const Text(
                                "Out of Stock",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Variants
                      if (widget.product.hasVariants) ...[
                        if (widget.product.variants.isNotEmpty) ...[
                          const Text("Select Variant",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          Builder(builder: (context) {
                            // Extract all unique attribute values and map them back to their keys
                            final Map<String, String> valueToKeyMap = {};
                            final Set<String> uniqueValues = {};
                            for (var variant in widget.product.variants) {
                              variant.attributes.forEach((key, value) {
                                final valStr = value.toString();
                                uniqueValues.add(valStr);
                                valueToKeyMap[valStr] = key;
                              });
                            }

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: uniqueValues.map((val) {
                                final keyForVal = valueToKeyMap[val]!;
                                final isSelected =
                                    selectedAttributes[keyForVal] == val;

                                return ChoiceChip(
                                  label: Text(val),
                                  selected: isSelected,
                                  showCheckmark: true,
                                  checkmarkColor: Colors.white,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedAttributes
                                            .clear(); // Ensure only one variant selected at a time
                                        selectedAttributes[keyForVal] = val;

                                        // find matching variant
                                        ProductVariant? matchedVariant;
                                        for (var v in widget.product.variants) {
                                          bool matches = true;
                                          for (var k
                                              in selectedAttributes.keys) {
                                            if (v.attributes[k]?.toString() !=
                                                selectedAttributes[k]) {
                                              matches = false;
                                              break;
                                            }
                                          }
                                          if (matches) {
                                            matchedVariant = v;
                                            break;
                                          }
                                        }
                                        if (matchedVariant != null) {
                                          selectedVariant = matchedVariant;
                                          currentImageIndex = 0;
                                        }
                                      });
                                    }
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: Colors.blue.shade600,
                                  side: BorderSide(
                                      color: isSelected
                                          ? Colors.blue.shade600
                                          : Colors.grey.shade300,
                                      width: 1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            );
                          }),
                          const SizedBox(height: 24),
                        ] else if (widget
                            .product.variantAttributes.isNotEmpty) ...[
                          const Text("Select Option",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                widget.product.variantAttributes.map((attr) {
                              final isSelected = selectedSimpleVariant == attr;
                              return ChoiceChip(
                                label: Text(attr),
                                selected: isSelected,
                                showCheckmark: true,
                                checkmarkColor: Colors.blue.shade700,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      selectedSimpleVariant = attr;
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.blue.shade50,
                                side: BorderSide(
                                    color: isSelected
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade300,
                                    width: 1),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                labelStyle: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],

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
                          color: const Color(0xFFF4F8FF),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.1)),
                        ),
                        child: Obx(() {
                          final loc =
                              LocationController.to.currentLocationModel.value;
                          final hasAddress = loc != null &&
                              loc.formattedAddress.trim().isNotEmpty &&
                              loc.receiverName?.trim().isNotEmpty == true;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasAddress) ...[
                                // Address
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.home_outlined,
                                          size: 20, color: Color(0xFF2956D3)),
                                      const SizedBox(width: 8),
                                      const Text("HOME ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B))),
                                      Expanded(
                                        child: Text(loc.formattedAddress,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B))),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.local_shipping_outlined,
                                          size: 20,
                                          color: displayStock > 0
                                              ? Colors.green
                                              : const Color(0xFF1E293B)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayStock > 0
                                                  ? "Deliverable at your location"
                                                  : "Not deliverable at your location",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B)),
                                            ),
                                            if (widget
                                                    .product
                                                    .estimatedDeliveryTime
                                                    ?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                "Delivery by ${widget.product.estimatedDeliveryTime}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B)),
                                              ),
                                            ],
                                            if (widget.product.deliveryCharge !=
                                                    null &&
                                                widget.product.deliveryCharge! >
                                                    0) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                "Delivery Charge: ₹${widget.product.deliveryCharge!.toInt()}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.white),
                              ],
                              // Seller info
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Features Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureIcon(
                              Icons.inventory_2_outlined,
                              widget.product.returnPolicy?.isNotEmpty == true
                                  ? (RegExp(r'^\d+$').hasMatch(
                                          widget.product.returnPolicy!)
                                      ? "${widget.product.returnPolicy!} Days\nReturn"
                                      : widget.product.returnPolicy!)
                                  : "No\nReturn"),
                          if (widget.product.isCashOnDelivery ?? true)
                            _buildFeatureIcon(Icons.currency_rupee_outlined,
                                "Cash on\nDelivery"),
                          _buildFeatureIcon(
                              Icons.support_agent_outlined, "24/7\nSupport"),
                          if (widget.product.paymentOptions
                                  .contains('Online Payment') ||
                              widget.product.paymentOptions.contains('UPI') ||
                              widget.product.paymentOptions.contains('Card') ||
                              widget.product.isOnlinePayment)
                            _buildFeatureIcon(Icons.verified_user_outlined,
                                "Secure\nPayment"),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1),
                      const SizedBox(height: 16),

                      // Dynamic Specifications Table
                      Builder(builder: (context) {
                        final Map<String, dynamic> allSpecs = {
                          ...widget.product.specifications,
                        };
                        if (widget.product.sku.isNotEmpty)
                          allSpecs['SKU'] = widget.product.sku;
                        if (widget.product.unit.isNotEmpty &&
                            widget.product.unit != 'Piece')
                          allSpecs['Unit'] = widget.product.unit;
                        if (widget.product.weight != null)
                          allSpecs['Weight'] = '${widget.product.weight} kg';
                        if (widget.product.dimensions?.isNotEmpty == true)
                          allSpecs['Dimensions'] = widget.product.dimensions;

                        if (allSpecs.isEmpty) return const SizedBox();

                        return _buildExpandableSection(
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
                            itemCount: allSpecs.length,
                            itemBuilder: (context, index) {
                              final entry = allSpecs.entries.elementAt(index);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        fontSize: 14, color: Color(0xFF1E293B)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }),

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
                                          style: TextStyle(color: textGrey)),
                                    ],
                                  ),
                                ],
                              ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('store_products')
                                  .doc(widget.product.id)
                                  .collection('reviews')
                                  .orderBy('createdAt', descending: true)
                                  .limit(8)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final currentUserId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                bool hasReviewed = false;
                                List<ProductReview> reviews = [];

                                if (snapshot.hasData &&
                                    snapshot.data!.docs.isNotEmpty) {
                                  reviews = snapshot.data!.docs
                                      .map((d) => ProductReview.fromMap(
                                          d.data() as Map<String, dynamic>,
                                          d.id))
                                      .toList();
                                  hasReviewed = reviews
                                      .any((r) => r.userId == currentUserId);
                                }

                                return Column(
                                  children: [
                                    if (!hasReviewed) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _showAddReviewBottomSheet,
                                          icon: const Icon(
                                              Icons.edit_note_rounded,
                                              color: Color(0xFF2956D3),
                                              size: 22),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            side: const BorderSide(
                                                color: Color(0xFF2956D3),
                                                width: 1.5),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          label: const Text("Write a Review",
                                              style: TextStyle(
                                                  color: Color(0xFF2956D3),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (reviews.isEmpty)
                                      const SizedBox() // subtitle handles empty state
                                    else
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
                                                      const SizedBox(width: 4),
                                                      const Icon(Icons.verified,
                                                          color: Colors.green,
                                                          size: 14),
                                                    ]
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                    children: List.generate(
                                                        5,
                                                        (i) => Icon(Icons.star,
                                                            color: i < r.rating
                                                                ? Colors.amber
                                                                : Colors
                                                                    .grey[300],
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
                                                        color: Colors.grey[800],
                                                        fontSize: 13)),
                                                const Divider(),
                                              ],
                                            ),
                                          )),
                                    //   if (widget.product.totalReviews > 8)
                                    //     TextButton(
                                    //       onPressed:
                                    //           () {}, // Pagination logic can be added here
                                    //       child: const Text("See All Reviews"),
                                    //     )
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Similar Products
                      if (widget.product.categoryId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Similar Products",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<QuerySnapshot>(
                                future: widget.product.categoryId.isNotEmpty
                                    ? FirebaseFirestore.instance
                                        .collection('store_products')
                                        .where('categoryId',
                                            isEqualTo:
                                                widget.product.categoryId)
                                        .limit(30)
                                        .get()
                                    : FirebaseFirestore.instance
                                        .collection('store_products')
                                        .limit(30)
                                        .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  List<StoreProductModel> similarProducts = [];
                                  if (snapshot.hasData &&
                                      snapshot.data!.docs.isNotEmpty) {
                                    final candidates = snapshot.data!.docs
                                        .map((doc) => StoreProductModel.fromMap(
                                            doc.data() as Map<String, dynamic>,
                                            doc.id))
                                        .where((p) => p.id != widget.product.id)
                                        .toList();

                                    final sameSubcategory = candidates
                                        .where((p) =>
                                            p.subcategoryId ==
                                            widget.product.subcategoryId)
                                        .toList();
                                    final others = candidates
                                        .where((p) =>
                                            p.subcategoryId !=
                                            widget.product.subcategoryId)
                                        .toList();

                                    sameSubcategory.shuffle(Random());
                                    others.shuffle(Random());

                                    similarProducts = [
                                      ...sameSubcategory,
                                      ...others
                                    ].take(5).toList();
                                  }

                                  // Fallback if no similar products found in same category
                                  if (similarProducts.isEmpty) {
                                    return FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('store_products')
                                          .limit(30)
                                          .get(),
                                      builder: (ctx, snap) {
                                        if (!snap.hasData ||
                                            snap.data!.docs.isEmpty) {
                                          return const SizedBox();
                                        }
                                        final fallbackProducts = snap.data!.docs
                                            .map((doc) =>
                                                StoreProductModel.fromMap(
                                                    doc.data()
                                                        as Map<String, dynamic>,
                                                    doc.id))
                                            .where((p) =>
                                                p.id != widget.product.id)
                                            .toList();

                                        fallbackProducts.shuffle(Random());
                                        final displayProducts =
                                            fallbackProducts.take(5).toList();

                                        if (displayProducts.isEmpty)
                                          return const SizedBox();
                                        return _buildProductList(
                                            displayProducts);
                                      },
                                    );
                                  }

                                  return _buildProductList(similarProducts);
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
                                    selectedVariantName: selectedAttributes
                                            .isNotEmpty
                                        ? selectedAttributes.values.join(' - ')
                                        : selectedSimpleVariant,
                                  );
                                }
                              } else {
                                cartController.addToCart(
                                  widget.product,
                                  variant: selectedVariant,
                                  selectedVariantName: selectedAttributes
                                          .isNotEmpty
                                      ? selectedAttributes.values.join(' - ')
                                      : selectedSimpleVariant,
                                );
                              }
                            }
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color: displayStock > 0
                                ? const Color(0xFF2956D3)
                                : Colors.grey.shade400,
                            width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isInCart
                                ? Icons.shopping_cart
                                : Icons.add_shopping_cart,
                            color: displayStock > 0
                                ? const Color(0xFF2956D3)
                                : Colors.grey.shade600,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(isInCart ? "Go to cart" : "Add to cart",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: displayStock > 0
                                    ? const Color(0xFF2956D3)
                                    : Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: displayStock > 0
                        ? () async {
                            final tempItem = CartItemModel(
                              id: widget.product.id,
                              productId: widget.product.id,
                              productName: widget.product.productName,
                              productImage: selectedVariant?.image ??
                                  widget.product.coverImage,
                              price: selectedVariant?.price ??
                                  widget.product.price,
                              offerPrice: selectedVariant?.discountPrice ??
                                  widget.product.discountPrice,
                              quantity: 1,
                              variantId: selectedVariant?.id,
                              variantName: selectedAttributes.isNotEmpty
                                  ? selectedAttributes.values.join(' - ')
                                  : selectedSimpleVariant,
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
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: displayStock > 0
                            ? const Color(0xFF2956D3)
                            : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt,
                            color: displayStock > 0
                                ? Colors.white
                                : Colors.grey.shade200,
                            size: 20),
                        const SizedBox(width: 8),
                        Text("Buy Now",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: displayStock > 0
                                    ? Colors.white
                                    : Colors.grey.shade200)),
                      ],
                    ),
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
            border: Border.all(color: Colors.blue.withOpacity(0.15)),
          ),
          child: Icon(icon, color: const Color(0xFF2956D3)),
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

  Widget _buildProductList(List<StoreProductModel> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Get.to(() => ProductDetailsPage(product: product),
                preventDuplicates: false);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: (product.coverImage.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: product.coverImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade100,
                              child:
                                  const Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            "₹${product.sellingPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2956D3)),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "₹${product.originalPrice.toStringAsFixed(0)}",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(height: 2),
                        Text(
                          "${product.discountPercentage}% OFF",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddReviewBottomSheet() {
    double selectedRating = 0;
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: 50,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text("What do you think?",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    const Text("Please give your rating and write a review",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setModalState(() {
                              selectedRating = index + 1.0;
                            });
                          },
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 46,
                            color: index < selectedRating
                                ? Colors.amber
                                : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            "Would you like to write anything about this product?",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide:
                                const BorderSide(color: Color(0xFF2956D3))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2956D3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (selectedRating == 0) {
                            CherryToast.error(
                              title: const Text("info"),
                              description:
                                  const Text("Please provide a rating"),
                              toastPosition: Position.top,
                            ).show(context);
                            return;
                          }
                          try {
                            final reviewRef = FirebaseFirestore.instance
                                .collection('store_products')
                                .doc(widget.product.id)
                                .collection('reviews')
                                .doc();

                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final review = ProductReview(
                              id: reviewRef.id,
                              userId: currentUser?.uid ?? 'unknown',
                              userName: (currentUser?.displayName != null &&
                                      currentUser!.displayName!.isNotEmpty)
                                  ? currentUser.displayName!
                                  : 'Anonymous',
                              userProfileImage: currentUser?.photoURL ?? '',
                              rating: selectedRating,
                              title: '',
                              description: reviewController.text,
                            );

                            await reviewRef.set(review.toMap());
                            Get.back();
                            CherryToast.success(
                              title: const Text("Success"),
                              description:
                                  const Text("Review submitted successfully"),
                              toastPosition: Position.top,
                            ).show(context);
                          } catch (e) {
                            CherryToast.error(
                              title: const Text("Error"),
                              description:
                                  const Text("Failed to submit review"),
                              toastPosition: Position.top,
                            ).show(context);
                          }
                        },
                        child: const Text("Submit Review",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

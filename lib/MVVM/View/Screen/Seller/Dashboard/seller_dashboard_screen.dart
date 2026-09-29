import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/controller/seller/seller_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_orders_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_products_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Products/add_product_screen.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_notifications_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_store_profile_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_history_orders_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/order_details_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_all_recent_orders_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_refund_pending_orders_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SellerDashboardController>()) {
      Get.put(SellerDashboardController());
    }
    final controller = SellerDashboardController.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.bottomNavIndex.value == 1) {
          return const SellerOrdersScreen();
        }
        if (controller.bottomNavIndex.value == 2) {
          return const SellerProductsScreen();
        }
        if (controller.bottomNavIndex.value == 3) {
          return const SellerHistoryOrdersScreen();
        }
        return Stack(
          children: [
            Column(
              children: [
                _buildHeader(controller),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.only(bottom: 80), // for bottom nav
                    child: Column(
                      children: [
                        const SizedBox(
                            height: 70), // space for overlapping card
                        Obx(() {
                          final hasOutOfStock =
                              controller.outOfStockProducts.value > 0;
                          final hasRefundPending =
                              controller.refundPendingOrders.value > 0;

                          return Column(
                            children: [
                              if (hasOutOfStock)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 5),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: Colors.red),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Products count (${controller.outOfStockProducts.value}) are out of stock. Please update the stock.",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (hasRefundPending)
                                GestureDetector(
                                  onTap: () {
                                    Get.to(() =>
                                        const SellerRefundPendingOrdersScreen());
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 5),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                            Icons.currency_rupee,
                                            color: Colors.orange),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "You have ${controller.refundPendingOrders.value} online order(s) pending refund. Please process them within 2 days.",
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios,
                                            color: Colors.orange, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!hasOutOfStock && !hasRefundPending)
                                const SizedBox.shrink(),
                            ],
                          );
                        }),
                        //_buildQuickActions(),
                        _buildTodaysOverview(controller),
                        _buildPromotionalBanner(),
                        _buildRecentOrders(controller),
                        _buildBottomStats(controller),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 130, // adjust based on header height
              left: 20,
              right: 20,
              child: _buildStoreCard(controller),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => _buildBottomNavBar(controller)),
    );
  }

  Widget _buildHeader(SellerDashboardController controller) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F2E5A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Hi, ${controller.currentSeller?.fullName ?? 'Seller'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("👋", style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Welcome back to your store",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Get.offAll(() => const user_Dashboard());
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_outlined,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(SellerDashboardController controller) {
    final seller = controller.currentSeller;

    String subscriptionText = "Active Subscription";
    Color subscriptionColor = Colors.green;

    if (seller != null) {
      if (seller.subscriptionStatus == 'trial' && seller.trialEndDate != null) {
        final daysLeft = seller.trialEndDate!.difference(DateTime.now()).inDays;
        subscriptionText =
            daysLeft > 0 ? "$daysLeft days left trial" : "Trial expired";
        if (daysLeft <= 0) subscriptionColor = Colors.red;
      } else if (seller.subscriptionStatus == 'active' &&
          seller.subscriptionEndDate != null) {
        final daysLeft =
            seller.subscriptionEndDate!.difference(DateTime.now()).inDays;
        subscriptionText =
            daysLeft > 0 ? "$daysLeft days left" : "Subscription expired";
        if (daysLeft <= 0) subscriptionColor = Colors.red;
      } else {
        subscriptionText = seller.subscriptionStatus.toUpperCase();
      }
    }

    String openSince = "Open recently";
    if (seller?.storeOpenedAt != null) {
      openSince = "Open since ${seller!.storeOpenedAt!.year}";
    } else if (seller?.createdAt != null) {
      openSince = "Open since ${seller!.createdAt!.year}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront,
                    color: Color(0xFF0F2E5A), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentSeller?.storeName ?? "My Store",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.currentSeller?.category ?? "Category",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (controller.currentSeller?.sellerPublicId != null &&
                        controller
                            .currentSeller!.sellerPublicId!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "ID: ${controller.currentSeller!.sellerPublicId}",
                            style: const TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: controller
                                      .currentSeller!.sellerPublicId!));
                              Get.snackbar(
                                'Success',
                                'Seller ID copied',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            child: const Icon(Icons.copy,
                                size: 12, color: Color(0xFF0EA5E9)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(() => const SellerStoreProfileScreen());
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        "View",
                        style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          color: Color(0xFF0EA5E9), size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: subscriptionColor, size: 8),
                  const SizedBox(width: 6),
                  Text(
                    subscriptionText,
                    style: TextStyle(
                      color: subscriptionColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                openSince,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_box,
                  title: "Add Product",
                  iconColor: const Color(0xFF0F2E5A),
                  onTap: () {
                    Get.to(() => const AddProductScreen());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.inventory_2_outlined,
                  title: "My Products",
                  iconColor: const Color(0xFF0EA5E9),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.shopping_bag_outlined,
                  title: "Orders",
                  iconColor: const Color(0xFF0EA5E9),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysOverview(SellerDashboardController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Overview",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => _buildStatItem(
                            icon: Icons.receipt_long_outlined,
                            iconColor: Colors.orange,
                            title: "Orders",
                            value: controller.totalOrders.value.toString(),
                          )),
                    ),
                    Expanded(
                      child: Obx(() {
                        final sales = controller.totalSales.value;
                        final displaySales = sales == sales.toInt()
                            ? sales.toInt().toString()
                            : sales.toStringAsFixed(2);
                        return _buildStatItem(
                          icon: Icons.payments_outlined,
                          iconColor: Colors.green,
                          title: "Sales",
                          value: "₹$displaySales",
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => _buildStatItem(
                            icon: Icons.inventory_2_outlined,
                            iconColor: const Color(0xFF0EA5E9),
                            title: "Products",
                            value: controller.totalProducts.value.toString(),
                          )),
                    ),
                    Expanded(
                      child: Obx(() => _buildStatItem(
                            icon: Icons.people_outline,
                            iconColor: Colors.purple,
                            title: "Customers",
                            value: controller.totalCustomers.value.toString(),
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => _buildStatItem(
                            icon: Icons.local_shipping_outlined,
                            iconColor: Colors.teal,
                            title: "Dispatched",
                            value: controller.totalDispatchedOrders.value
                                .toString(),
                          )),
                    ),
                    Expanded(
                        child:
                            const SizedBox()), // Empty space to keep layout balanced
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F2E5A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromotionalBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('store_products')
          .where('sellerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasProducts = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          hasProducts = true;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasProducts ? "Grow your store " : "Your store is ready ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const Text("🎉", style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasProducts
                      ? "Add more products to reach more customers."
                      : "Add your first product and start building your store.",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => const AddProductScreen());
                    },
                    icon: const Icon(Icons.add_circle_outline,
                        size: 18, color: Colors.white),
                    label: Text(
                      hasProducts ? "Add Products" : "Add First Product",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentOrders(SellerDashboardController controller) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Orders",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(() => const SellerAllRecentOrdersScreen());
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (uid == null)
            const Center(
              child: Text(
                "No recent orders yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('sellerId', isEqualTo: uid)
                  .where('bookingType', isEqualTo: 'Product Order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "Error loading orders",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No recent orders yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                // Sort locally by createdAt descending to avoid composite index requirements
                final allDocs = snapshot.data!.docs.toList();
                allDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                // Take top 3
                final docs = allDocs.take(3).toList();

                return Column(
                  children: List.generate(docs.length, (index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final displayId = data['orderId'] != null
                        ? "#${data['orderId']}"
                        : "#${docId.toUpperCase()}";

                    // Handle cart array for items display
                    String itemsText = '1 Item';
                    final cart = data['cart'];
                    if (cart is List) {
                      int totalQty = 0;
                      for (var item in cart) {
                        if (item is Map) {
                          totalQty +=
                              num.tryParse(item['qty']?.toString() ?? '1')
                                      ?.toInt() ??
                                  1;
                        }
                      }
                      itemsText = '$totalQty Item${totalQty > 1 ? 's' : ''}';
                    }

                    // Format price
                    final rawPrice = data['totalAmount'] ??
                        data['price'] ??
                        data['discountPrice'] ??
                        0;
                    final parsedPrice = num.tryParse(rawPrice.toString()) ?? 0;
                    final priceText = '₹${parsedPrice.toInt()}';

                    // Parse status and assign color
                    final statusStr = (data['status'] ?? 'Pending').toString();
                    Color statusColor = Colors.orange;
                    if (statusStr.toLowerCase().contains('dispatch')) {
                      statusColor = Colors.green;
                    } else if (statusStr.toLowerCase().contains('deliver')) {
                      statusColor = Colors.green;
                    } else if (statusStr.toLowerCase().contains('cancel') ||
                        statusStr.toLowerCase().contains('reject')) {
                      statusColor = Colors.red;
                    }

                    // Build mapped data for order details
                    final customerName =
                        data['customerName']?.toString().isNotEmpty == true
                            ? data['customerName'].toString()
                            : (data['deliveryAddress']?['receiverName']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? data['deliveryAddress']['receiverName']
                                    .toString()
                                : 'Customer');
                    final mappedData = {
                      'docId': docId,
                      'orderId': data['orderId']?.toString() ?? docId,
                      'customerName': customerName,
                      'customerLocation': data['deliveryAddress']
                              ?['formattedAddress'] ??
                          'Unknown Location',
                      'customerPhone':
                          data['deliveryAddress']?['receiverPhone'] ?? '',
                      'customerAltPhone':
                          data['deliveryAddress']?['alternatePhone'] ?? '',
                      'status': (data['status'] ?? 'Pending').toString(),
                      'subtotal': rawPrice,
                      'deliveryFee': 0,
                      'paymentMethod': data['paymentMethod'] ?? 'Unknown',
                      'paymentStatus': data['paymentStatus'] ?? 'Pending',
                      'transactionId': data['transactionId'], 'Refuned': data['Refuned'],
                      'formattedReceipt': data['formattedReceipt'],
                      'ocrAmountExtracted': data['ocrAmountExtracted'],
                      'ocrReceiverUpi': data['ocrReceiverUpi'],
                      'ocrPaymentDateTime': data['ocrPaymentDateTime'],
                      'ocrHasSuccessIndicator': data['ocrHasSuccessIndicator'],
                      'cancellationReason': data['cancellationReason'],
                      'cancellationComment': data['cancellationComment'],
                      'items': cart is List && cart.isNotEmpty
                          ? cart
                          : [
                              {
                                'name': data['serviceTitle'] ?? 'Product',
                                'qty': data['quantity'] ?? 1,
                                'price': rawPrice,
                                'image': data['image'],
                              }
                            ],
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          Get.to(() =>
                              SellerOrderDetailsScreen(orderData: mappedData));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _buildOrderItem(
                          orderId: displayId,
                          items: itemsText,
                          price: priceText,
                          status: statusStr,
                          statusColor: statusColor,
                          paymentMethod:
                              mappedData['paymentMethod']?.toString(),
                          paymentStatus:
                              mappedData['paymentStatus']?.toString(),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderId,
    required String items,
    required String price,
    required String status,
    required Color statusColor,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (paymentMethod != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFB9D5FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod.toLowerCase() == 'upi'
                                ? Icons.currency_rupee
                                : Icons.money,
                            size: 10,
                            color: const Color(0xFF0857A0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentMethod.toLowerCase() == 'upi'
                                ? 'UPI'
                                : 'Cash on Delivery',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0857A0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (paymentMethod.toLowerCase() == 'upi' &&
                        (paymentStatus?.toLowerCase() == 'completed' ||
                            paymentStatus?.toLowerCase() == 'paid' ||
                            paymentStatus?.toLowerCase() == 'success')) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStats(SellerDashboardController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Existing "This Month Sales" card - full width

          Row(
            children: [
              Expanded(
                child: Obx(() => _buildBottomStatCard(
                      title: "This Month Sales",
                      value: "₹${controller.thisMonthSales.value.toInt()}",
                      trend: "  New",
                      trendColor: Colors.blue,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() => _buildBottomStatCard(
                      title: "Today's Customers",
                      value: "${controller.todayCustomers.value}",
                      trend: "  New",
                      trendColor: Colors.green,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. New "Today's Sales" Section
          _buildTodaySalesSection(controller),
        ],
      ),
    );
  }

  Widget _buildTodaySalesSection(SellerDashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Obx(() {
        final date = controller.selectedSalesDate.value;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        String dateText = isToday
            ? "Today"
            : "${date.day} ${_getMonthName(date.month)} ${date.year}";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Sales",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: Get.context!,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF0F2E5A),
                              onPrimary: Colors.white,
                              onSurface: Color(0xFF1E293B),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selected != null) {
                      controller.fetchSalesForDate(selected);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2E5A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_today,
                            size: 14, color: Color(0xFF0F2E5A)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (controller.isLoadingSales.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // Summary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Sales",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${controller.selectedDateSales.value.toInt()}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Orders",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${controller.selectedDateOrders.value}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Graph or Empty State
              if (controller.selectedDateOrders.value == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      "No sales for this date",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                _buildNativeBarChart(controller.hourlySales),
                const SizedBox(height: 32),
                _buildNativePieChart(controller.productSalesData),
              ]
            ],
          ],
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildNativeBarChart(List<double> hourlySales) {
    double maxSales = 0;
    for (var sales in hourlySales) {
      if (sales > maxSales) maxSales = sales;
    }
    if (maxSales == 0) maxSales = 1; // Prevent division by zero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bars
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(24, (index) {
              final val = hourlySales[index];
              final heightPercentage = val / maxSales;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Tooltip(
                    message:
                        '₹${val.toInt()} at ${index == 0 ? 12 : (index > 12 ? index - 12 : index)} ${index >= 12 ? 'PM' : 'AM'}',
                    child: Container(
                      height: 120 * heightPercentage,
                      decoration: BoxDecoration(
                        color: val > 0
                            ? const Color(0xFF0EA5E9)
                            : Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // X-Axis Labels (every 3 hours to avoid clutter)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("12A", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("3A", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("6A", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("9A", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("12P", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("3P", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("6P", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("9P", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("11P",
                style: TextStyle(
                    fontSize: 10, color: Colors.transparent)), // Spacing dummy
          ],
        ),
      ],
    );
  }

  Widget _buildBottomStatCard({
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0F2E5A),
              height: 1.5,
            ),
          ),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              trend,
              style: TextStyle(
                color: trendColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(SellerDashboardController controller) {
    final int currentIndex = controller.bottomNavIndex.value;

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag,
        'label': 'Orders'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'activeIcon': Icons.inventory_2,
        'label': 'Products'
      },
      {
        'icon': Icons.history_outlined,
        'activeIcon': Icons.history,
        'label': 'History'
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final bool isSelected = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.changeTabIndex(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0F2E5A).withOpacity(0.09)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected
                              ? items[index]['activeIcon'] as IconData
                              : items[index]['icon'] as IconData,
                          color: isSelected
                              ? const Color(0xFF0F2E5A)
                              : const Color(0xFFADB5BD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.0,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? const Color(0xFF0F2E5A)
                              : const Color(0xFFADB5BD),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNativePieChart(Map<String, double> productSalesData) {
    if (productSalesData.isEmpty) return const SizedBox.shrink();

    double totalSales = 0;
    productSalesData.forEach((_, val) => totalSales += val);

    final List<Color> colors = [
      const Color(0xFF0EA5E9), // Light Blue
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFF14B8A6), // Teal
    ];

    int colorIndex = 0;
    final List<MapEntry<String, double>> sortedEntries =
        productSalesData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Highest first

    final legendItems = sortedEntries.take(5).map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final percentage = (entry.value / totalSales * 100).toStringAsFixed(1);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "$percentage%",
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A)),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Top Products Sold",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2E5A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: PieChartPainter(
                  data: sortedEntries.map((e) => e.value).toList(),
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legendItems,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  PieChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double total = data.fold(0, (sum, item) => sum + item);
    if (total == 0) return;

    double startAngle = -1.5708; // Start at top (-90 degrees in radians)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i] / total) * 6.2832; // 360 degrees in radians
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

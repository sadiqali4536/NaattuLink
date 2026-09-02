import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/controller/seller/seller_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_orders_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_products_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Products/add_product_screen.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_notifications_screen.dart';

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
          return const SellerNotificationsScreen();
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
                        //_buildQuickActions(),
                        _buildTodaysOverview(controller),
                        _buildPromotionalBanner(),
                        _buildRecentOrders(),
                        _buildBottomStats(),
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
                  ],
                ),
              ),
              Container(
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

  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Recent Orders",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              Text(
                "View All",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              "No recent orders yet",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
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

  Widget _buildBottomStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildBottomStatCard(
              title: "This Month Sales",
              value: "₹12,850",
              trend: "↑ 12% vs last",
              trendColor: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBottomStatCard(
              title: "Performance",
              value: "Views        248\nRating       4.8 ★",
              trend: "",
              trendColor: Colors.transparent,
            ),
          ),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: controller.bottomNavIndex.value,
        onTap: controller.changeTabIndex,
        selectedItemColor: const Color(0xFF0F2E5A),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: controller.bottomNavIndex.value == 0
                    ? const Color(0xFF0F2E5A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.home,
                color: controller.bottomNavIndex.value == 0
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: controller.bottomNavIndex.value == 1
                    ? const Color(0xFF0F2E5A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: controller.bottomNavIndex.value == 1
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: controller.bottomNavIndex.value == 2
                    ? const Color(0xFF0F2E5A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: controller.bottomNavIndex.value == 2
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: controller.bottomNavIndex.value == 3
                    ? const Color(0xFF0F2E5A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: controller.bottomNavIndex.value == 3
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/seller_dashboard_controller.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/edit_store_profile_screen.dart';

class SellerStoreProfileScreen extends StatelessWidget {
  const SellerStoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = SellerDashboardController.to;
      final seller = controller.currentSeller;

      if (seller == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Store Profile')),
          body: const Center(child: Text('Store data not available')),
        );
      }

      String openSince = "Recently Opened";
      if (seller.storeOpenedAt != null) {
        openSince = DateFormat('dd MMM yyyy').format(seller.storeOpenedAt!);
      } else if (seller.createdAt != null) {
        openSince = DateFormat('dd MMM yyyy').format(seller.createdAt!);
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Store Profile'),
          backgroundColor: const Color(0xFF0F2E5A),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Get.to(() => const EditStoreProfileScreen());
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F2E5A),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront,
                          color: Color(0xFF0F2E5A), size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      seller.storeName ?? "My Store",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seller.category ?? "Category",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Opened: $openSince",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (seller.sellerPublicId != null &&
                        seller.sellerPublicId!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: seller.sellerPublicId!));
                          Get.snackbar(
                            'Success',
                            'Seller ID copied',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "ID: ${seller.sellerPublicId}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy,
                                  color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("About Business"),
                    _buildInfoCard(
                      child: Text(
                        seller.aboutBusiness?.isNotEmpty == true
                            ? seller.aboutBusiness!
                            : "No description provided.",
                        style: const TextStyle(
                            color: Color(0xFF334155), height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Contact Information"),
                    _buildInfoCard(
                      child: Column(
                        children: [
                          _buildInfoRow(
                              Icons.person_outline,
                              "Owner Name",
                              seller.fullName.isNotEmpty
                                  ? seller.fullName
                                  : (seller.sellerName ?? "Not specified")),
                          const Divider(),
                          _buildInfoRow(
                              Icons.phone_outlined,
                              "Phone",
                              seller.phoneNumber.isNotEmpty
                                  ? seller.phoneNumber
                                  : (seller.phone ?? "Not specified")),
                          if (seller.whatsappNumber != null &&
                              seller.whatsappNumber!.isNotEmpty) ...[
                            const Divider(),
                            _buildInfoRow(Icons.chat_outlined, "WhatsApp",
                                seller.whatsappNumber!),
                          ],
                          if (seller.upiId != null &&
                              seller.upiId!.isNotEmpty) ...[
                            const Divider(),
                            _buildInfoRow(Icons.qr_code_2_outlined, "UPI ID",
                                seller.upiId!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Location"),
                    _buildInfoCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Color(0xFF0F2E5A), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              seller.location?.isNotEmpty == true
                                  ? seller.location!
                                  : "Location not specified",
                              style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 14,
                                  height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F2E5A),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0F2E5A), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

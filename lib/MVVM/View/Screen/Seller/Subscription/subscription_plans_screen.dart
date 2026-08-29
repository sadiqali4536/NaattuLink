import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_registration_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Choose a Plan",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F2E5A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Start your journey with NaattuLink",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Select a plan that fits your business needs.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPlanCard(
              title: "Free Trial",
              price: "₹0",
              duration: "for 14 days",
              features: [
                "List up to 10 products",
                "Basic store analytics",
                "Local search visibility"
              ],
              buttonText: "Start Free Trial",
              isPopular: false,
              onSelect: () => _proceedToRegistration(),
            ),
            const SizedBox(height: 20),
            _buildPlanCard(
              title: "Premium Plan",
              price: "₹499",
              duration: "per month",
              features: [
                "Unlimited product listings",
                "Advanced analytics & reports",
                "Priority local search visibility",
                "Customer support"
              ],
              buttonText: "Choose Premium",
              isPopular: true,
              onSelect: () => _proceedToRegistration(),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToRegistration() {
    Get.to(() => const SellerRegistrationScreen());
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required List<String> features,
    required String buttonText,
    required bool isPopular,
    required VoidCallback onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? const Color(0xFF0F2E5A) : const Color(0xFFE2E8F0),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF0F2E5A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Center(
                child: Text(
                  "MOST POPULAR",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? const Color(0xFF0F2E5A)
                          : const Color(0xFFF1F5F9),
                      foregroundColor:
                          isPopular ? Colors.white : const Color(0xFF0F2E5A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

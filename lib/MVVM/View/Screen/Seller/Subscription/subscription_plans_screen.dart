import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_registration_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/payment_options_screen.dart';
import 'package:naattulink/MVVM/controller/seller/subscription_plans_controller.dart';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SubscriptionPlansController>()) {
      Get.put(SubscriptionPlansController());
    }
    final controller = Get.find<SubscriptionPlansController>();

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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F2E5A)));
        }

        if (controller.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.error.value,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.retry,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A)),
                  child: const Text("Retry",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        if (controller.plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(Icons.inventory_2_outlined,
                //     size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  "Currently no subscription available",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
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
              ...controller.plans.map((plan) {
                // Determine if a plan is popular just as an example (e.g. Premium Plan)
                final isPopular = plan.name.toLowerCase().contains('premium') ||
                    plan.sortOrder == 2;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildPlanCard(
                    plan: plan,
                    isPopular: isPopular,
                    onSelect: () => _proceedToPayment(plan),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  void _proceedToPayment(SubscriptionPlanModel plan) {
    Get.to(() => SellerRegistrationScreen(plan: plan));
  }

  Widget _buildPlanCard({
    required SubscriptionPlanModel plan,
    required bool isPopular,
    required VoidCallback onSelect,
  }) {
    String priceDisplay =
        plan.price == 0 ? "₹0" : "₹${plan.price.toStringAsFixed(0)}";
    String buttonText = plan.price == 0 ? "Start Free Trial" : "Subscribe";

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
                  plan.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceDisplay,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan.billingPeriod,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                ...plan.features.map((feature) => Padding(
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
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? const Color(0xFF0F2E5A)
                          : const Color(0xFFF0F6FF),
                      foregroundColor:
                          isPopular ? Colors.white : const Color(0xFF0F2E5A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

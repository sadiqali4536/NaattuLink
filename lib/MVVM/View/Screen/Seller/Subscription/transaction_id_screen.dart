import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/transaction_id_controller.dart';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';

class TransactionIdScreen extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final String paymentMethod;
  final String initialTransactionId;

  const TransactionIdScreen({
    super.key,
    required this.plan,
    required this.paymentMethod,
    required this.initialTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionIdController(
      plan: plan,
      paymentMethod: paymentMethod,
      initialTransactionId: initialTransactionId,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Transaction Details',
            style: TextStyle(
                color: Color(0xFF0F2E5A),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2E5A)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verify Payment",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please verify or enter your transaction ID to complete your subscription.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Plan", plan.name),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow("Amount", "₹${plan.price}"),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow("Billing", plan.billingPeriod),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow("Duration", "${plan.durationDays} days"),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    _buildSummaryRow("Method", paymentMethod),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transaction ID",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  if (paymentMethod == 'UPI')
                    Obx(() {
                      int minutes = controller.remainingSeconds.value ~/ 60;
                      int seconds = controller.remainingSeconds.value % 60;
                      return Text(
                        "Time left: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.transactionIdController,
                decoration: InputDecoration(
                  hintText: 'Enter Transaction ID',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F2E5A)),
                  ),
                  prefixIcon: const Icon(Icons.receipt_long, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            )
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.submitSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2E5A),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Subscribe",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

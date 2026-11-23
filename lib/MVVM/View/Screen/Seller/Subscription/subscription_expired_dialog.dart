import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/subscription_plans_screen.dart';

class SubscriptionExpiredDialog extends StatelessWidget {
  final DateTime? expiryDate;
  final String? planName;
  final String? expiryFormatted;
  final VoidCallback? onRenewPressed;

  const SubscriptionExpiredDialog({
    super.key,
    this.expiryDate,
    this.planName,
    this.expiryFormatted,
    this.onRenewPressed,
  });

  /// Static helper to display the dialog cleanly and prevent duplicate stacking
  static bool _isShowing = false;

  static Future<void> show({
    DateTime? expiryDate,
    String? planName,
    String? expiryFormatted,
    VoidCallback? onRenewPressed,
  }) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await Get.dialog(
        SubscriptionExpiredDialog(
          expiryDate: expiryDate,
          planName: planName,
          expiryFormatted: expiryFormatted,
          onRenewPressed: onRenewPressed,
        ),
        barrierDismissible: true,
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock_rounded,
                color: Colors.red.shade600,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Store Subscription Expired",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E5A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Your online store subscription has expired. Renew your subscription to continue managing products and orders.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Previous Plan",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        planName ?? "Store Plan",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Expired On",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        expiryFormatted ?? "N/A",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      if (onRenewPressed != null) {
                        onRenewPressed!();
                      } else {
                        Get.to(() => const SubscriptionPlansScreen());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Renew Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


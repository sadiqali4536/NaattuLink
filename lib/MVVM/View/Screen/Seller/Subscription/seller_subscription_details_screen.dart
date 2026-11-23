import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/seller/subscription_controller.dart';
import 'package:naattulink/MVVM/model/seller/seller_subscription_details.dart';
import 'package:naattulink/MVVM/utils/subscription_date_utils.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/subscription_plans_screen.dart';

class SellerSubscriptionDetailsScreen extends StatelessWidget {
  const SellerSubscriptionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subCtrl = SubscriptionController.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Subscription Details",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F2E5A)),
      ),
      body: Obx(() {
        final details = subCtrl.subscriptionDetails.value;
        final state = subCtrl.state.value;
        final remDays = subCtrl.remainingDays.value;

        String statusLabel = "Active";
        Color statusColor = Colors.green;

        if (state == SubscriptionState.expired) {
          statusLabel = "Expired";
          statusColor = Colors.red;
        } else if (state == SubscriptionState.expiringSoon) {
          statusLabel = "Expiring Soon ($remDays days)";
          statusColor = Colors.orange.shade800;
        } else if (state == SubscriptionState.renewalPending) {
          statusLabel = "Renewal Pending";
          statusColor = Colors.orange;
        } else if (state == SubscriptionState.suspended) {
          statusLabel = "Suspended";
          statusColor = Colors.red;
        }

        final planName = details?.planName ?? "Store Subscription Plan";
        final startDateStr = SubscriptionDateUtils.formatDisplayDate(details?.startDate);
        final expiryDateStr = SubscriptionDateUtils.formatDisplayDate(details?.expiryDate);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2E5A), Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2E5A).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          planName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor == Colors.green
                                  ? Colors.greenAccent
                                  : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildStatBox(
                          title: "Remaining Days",
                          value: remDays.toString(),
                          sub: remDays == 1 ? "day left" : "days left",
                        ),
                        const SizedBox(width: 16),
                        _buildStatBox(
                          title: "Total Duration",
                          value: (details?.durationDays ?? 30).toString(),
                          sub: "days plan",
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Subscription Period",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: "Start Date",
                      value: startDateStr,
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.event_busy_outlined,
                      label: "Expiry Date",
                      value: expiryDateStr,
                      valueColor: state == SubscriptionState.expired
                          ? Colors.red
                          : const Color(0xFF1E293B),
                    ),
                    if (details?.renewalStatus != null &&
                        details!.renewalStatus != 'none') ...[
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.pending_actions_outlined,
                        label: "Renewal Status",
                        value: details.renewalStatus.toUpperCase(),
                        valueColor: Colors.orange.shade800,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                "Feature Access",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildAccessRow("Store Home", true),
                    const Divider(height: 16),
                    _buildAccessRow(
                        "Add & Edit Products", subCtrl.hasActiveStoreAccess),
                    const Divider(height: 16),
                    _buildAccessRow("Manage Products & Stock",
                        subCtrl.hasActiveStoreAccess),
                    const Divider(height: 16),
                    _buildAccessRow(
                        "Manage Active Orders", subCtrl.hasActiveStoreAccess),
                    const Divider(height: 16),
                    _buildAccessRow(
                        "Accept New Customer Orders", subCtrl.hasActiveStoreAccess),
                    const Divider(height: 16),
                    _buildAccessRow("Order History & Analytics", true),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const SubscriptionPlansScreen());
                  },
                  icon: const Icon(Icons.autorenew, color: Colors.white),
                  label: Text(
                    state == SubscriptionState.expired
                        ? "RENEW EXPIRED SUBSCRIPTION"
                        : "RENEW / EXTEND SUBSCRIPTION",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatBox(
      {required String title, required String value, required String sub}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0F2E5A)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessRow(String title, bool isEnabled) {
    return Row(
      children: [
        Icon(
          isEnabled ? Icons.check_circle : Icons.lock_outline,
          size: 18,
          color: isEnabled ? Colors.green : Colors.red.shade400,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isEnabled ? const Color(0xFF1E293B) : Colors.grey.shade500,
            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          isEnabled ? "Active" : "Locked",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isEnabled ? Colors.green : Colors.red.shade600,
          ),
        ),
      ],
    );
  }
}


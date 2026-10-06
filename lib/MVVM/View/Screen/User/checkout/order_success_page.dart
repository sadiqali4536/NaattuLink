import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent back button by default
        title: Text(
          'order_status_label'.tr,
          style: const TextStyle(
            color: Color(0xFF0F2E5A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: WillPopScope(
        onWillPop: () async => false, // Disable back navigation
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),

                // Success animation
                SizedBox(
                  height: 220, // Reduced height to crop empty bottom space
                  width: 280,
                  child: Lottie.asset(
                    'assets/lotties/success_animation.json',
                    repeat: false,
                    fit: BoxFit.cover,
                  ),
                ),

                //const SizedBox(height: 5),

                Text(
                  'order_placed_title'.tr,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F2E5A),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'order_placed_success'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 28),

                // Order ID card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'order_id'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '#$orderId',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F2E5A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: orderId));
                              CherryToast.success(
                                title: Text('order_id_copied'.tr,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                animationType: AnimationType.fromTop,
                                toastPosition: Position.top,
                                toastDuration: const Duration(seconds: 2),
                              ).show(context);
                            },
                            child: const Icon(
                              Icons.copy_outlined,
                              size: 20,
                              color: Color(0xFF0F2E5A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAll(() => const user_Dashboard(initialIndex: 2));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A), // Primary Navy
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'continue_shopping_btn'.tr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

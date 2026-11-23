import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/transaction_id_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

class PaymentOptionsController extends GetxController {
  final SubscriptionPlanModel plan;

  PaymentOptionsController({required this.plan});

  final RxString selectedPaymentMethod = ''.obs;
  final RxBool isProcessing = false.obs;

  final List<String> paymentMethods = [
    'UPI',
  ];

  void selectMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  Future<void> proceedToPayment() async {
    if (selectedPaymentMethod.value.isEmpty) {
      CherryToast.warning(
        title: Text('Selection Required',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text('Please select a payment method.'),
        animationType: AnimationType.fromTop,
      ).show(Get.context!);
      return;
    }

    isProcessing.value = true;

    if (selectedPaymentMethod.value == 'UPI') {
      // Create a standard UPI intent URL
      final upiUri = Uri.parse(
          'upi://pay?pa=naattulink@upi&pn=NaattuLink&am=${plan.price}&cu=INR&tn=Subscription');

      try {
        // This will prompt the Android OS to show available installed UPI apps
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If no UPI apps are found or it fails
        CherryToast.warning(
          title: Text('Notice',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text(
              'Could not open UPI apps automatically. Proceeding to manual verification.'),
          animationType: AnimationType.fromTop,
        ).show(Get.context!);
      }

      // Wait for 3 seconds to simulate time taken in payment app
      await Future.delayed(const Duration(seconds: 3));
    } else {
      // MOCK PAYMENT FLOW for Card / Net Banking
      await Future.delayed(const Duration(seconds: 2));
    }

    isProcessing.value = false;

    Get.to(() => TransactionIdScreen(
          plan: plan,
          paymentMethod: selectedPaymentMethod.value,
          initialTransactionId: '',
        ));
  }
}

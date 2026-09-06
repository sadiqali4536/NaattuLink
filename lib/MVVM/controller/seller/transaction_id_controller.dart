import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_verification_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/payment_options_screen.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class TransactionIdController extends GetxController {
  final SubscriptionPlanModel plan;
  final String paymentMethod;
  final String initialTransactionId;

  TransactionIdController({
    required this.plan,
    required this.paymentMethod,
    required this.initialTransactionId,
  });

  final transactionIdController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxInt remainingSeconds = 60.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    transactionIdController.text = initialTransactionId;
    if (paymentMethod == 'UPI') {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _timer?.cancel();
        toastError("Timer expired. Please try again.");
        Get.offAll(() => PaymentOptionsScreen(plan: plan));
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    transactionIdController.dispose();
    super.onClose();
  }

  Future<void> submitSubscription() async {
    final transactionId = transactionIdController.text.trim();

    if (transactionId.isEmpty) {
      toastError("Please enter the transaction ID.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toastError("Authentication Error: Please login again.");
      return;
    }

    isLoading.value = true;
    final uid = user.uid;
    final sellerRef = FirebaseFirestore.instance.collection('sellers').doc(uid);
    final subscriptionRef = sellerRef.collection('subscription').doc('details');

    try {
      // Create a batch to ensure both operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();

      final now = DateTime.now();
      final String formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final String formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // 1. Save Subscription Details
      batch.set(subscriptionRef, {
        'planId': plan.planId, // Using Firestore auto-generated document ID
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'completed',
        'subscriptionStatus': 'pending_verification',
        'paymentDate': formattedDate,
        'paymentTime': formattedTime,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update Seller Status
      batch.update(sellerRef, {
        'status': 'pending_verification',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch
      await batch.commit();

      toastSuccess("Subscription submitted successfully!");
      Get.offAll(() => const SellerVerificationScreen());
    } on FirebaseException catch (e) {
      debugPrint("Firebase error: $e");
      toastError(
          "Unable to submit subscription. Please check your connection and try again.");
    } catch (e) {
      debugPrint("Unexpected error: $e");
      toastError("Unable to submit subscription. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }
}

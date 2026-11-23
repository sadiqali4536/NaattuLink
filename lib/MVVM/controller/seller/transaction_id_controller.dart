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
      // Fetch authoritative plan from Firestore
      final planDoc = await FirebaseFirestore.instance
          .collection('subscription_plans')
          .doc(plan.planId)
          .get();

      if (!planDoc.exists) {
        toastError("Selected plan is no longer valid. Please try again.");
        isLoading.value = false;
        return;
      }
      final authPlanData = planDoc.data()!;
      final authDurationDays = authPlanData['durationDays'] ?? 30;
      final authPrice = (authPlanData['price'] ?? 0).toDouble();
      final authPlanName = authPlanData['name'] ?? plan.name;

      // Create a batch to ensure both operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();

      final now = DateTime.now();
      final String formattedDate =
          "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final String formattedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final orderId = 'SUB-${DateTime.now().millisecondsSinceEpoch}';

      // Check if seller already exists and is an existing approved seller renewing
      final existingSellerSnap = await sellerRef.get();
      final bool isExistingApprovedSeller = existingSellerSnap.exists &&
          existingSellerSnap.data()?['registrationStatus'] == 'approved';

      // 1. Save Subscription Transaction Details
      batch.set(subscriptionRef, {
        'orderId': orderId,
        'planId': plan.planId,
        'planName': authPlanName,
        'durationDays': authDurationDays,
        'amount': authPrice,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'completed',
        'subscriptionStatus': 'pending_verification',
        'renewalStatus': 'pending',
        'paymentDate': formattedDate,
        'paymentTime': formattedTime,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Add an audit log to subscription_history subcollection
      final historyRef = sellerRef.collection('subscription_history').doc();
      batch.set(historyRef, {
        'historyId': historyRef.id,
        'sellerId': uid,
        'planId': plan.planId,
        'planName': authPlanName,
        'durationDays': authDurationDays,
        'amount': authPrice,
        'actionType': isExistingApprovedSeller ? 'renewal_request' : 'new_subscription_request',
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'performedBy': 'seller',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Update Seller Document with snapshot and strict flags
      if (isExistingApprovedSeller) {
        // Renewal for existing seller: keep registrationStatus as approved, mark renewalStatus pending
        batch.update(sellerRef, {
          'renewalStatus': 'pending',
          'pendingPlanId': plan.planId,
          'pendingPlanName': authPlanName,
          'pendingPlanDuration': authDurationDays,
          'pendingPlanPrice': authPrice,
          'pendingTransactionId': transactionId,
          'pendingPaymentMethod': paymentMethod,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // First-time registration
        batch.update(sellerRef, {
          'registrationStatus': 'pending_verification',
          'subscriptionStatus': 'pending',
          'adminVerified': false,
          'storeAccess': false,
          'selectedPlanId': plan.planId,
          'selectedPlanName': authPlanName,
          'planDurationDays': authDurationDays,
          'planPrice': authPrice,
          'subscriptionStartDate': null,
          'subscriptionEndDate': null,
          'renewalStatus': 'none',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit batch
      await batch.commit();

      toastSuccess(isExistingApprovedSeller
          ? "Renewal request submitted for verification!"
          : "Subscription submitted successfully!");
      if (isExistingApprovedSeller) {
        Get.back(); // Return to dashboard or details
      } else {
        Get.offAll(() => const SellerVerificationScreen());
      }
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

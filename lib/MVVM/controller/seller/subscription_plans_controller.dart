import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';

class SubscriptionPlansController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<SubscriptionPlanModel> plans = <SubscriptionPlanModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      error.value = '';
      plans.clear();

      final snapshot = await _firestore
          .collection('subscription_plans')
          .where('isActive', isEqualTo: true)
          .get();

      final fetchedPlans = snapshot.docs
          .map((doc) => SubscriptionPlanModel.fromMap(doc.data(), doc.id))
          .toList();

      fetchedPlans.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      plans.assignAll(fetchedPlans);
    } catch (e) {
      debugPrint("Error fetching subscription plans: $e");
      error.value = "Unable to load subscription plans. Please try again.";
    } finally {
      isLoading.value = false;
    }
  }

  void retry() {
    fetchPlans();
  }
}

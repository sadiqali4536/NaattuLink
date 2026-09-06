import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart'
    as naattulink_map;
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/payment_options_screen.dart';
import 'package:naattulink/MVVM/model/seller/subscription_plan_model.dart';

class SellerRegistrationController extends GetxController {
  static SellerRegistrationController get to => Get.find();

  SubscriptionPlanModel? selectedPlan;

  final sellerNameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final RxString fullPhoneNumber = ''.obs;
  final storeNameController = TextEditingController();
  final upiIdController = TextEditingController();
  final aboutController = TextEditingController();
  final otherCategoryController = TextEditingController();

  final RxString selectedCategory = ''.obs;
  final RxBool isReviewMode = false.obs;
  final RxBool acceptedTerms = false.obs;

  final categories = [
    'Groceries & Spices',
    'Fashion & Accessories',
    'Electronics',
    'Home & Kitchen',
    'Handmade Products',
    'Gifts & Toys',
    'Other'
  ];

  @override
  void onClose() {
    sellerNameController.dispose();
    locationController.dispose();
    phoneController.dispose();
    storeNameController.dispose();
    upiIdController.dispose();
    aboutController.dispose();
    otherCategoryController.dispose();
    super.onClose();
  }

  void proceedToReview() {
    if (sellerNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        fullPhoneNumber.value.isEmpty ||
        storeNameController.text.isEmpty ||
        upiIdController.text.isEmpty ||
        selectedCategory.value.isEmpty ||
        (selectedCategory.value == 'Other' &&
            otherCategoryController.text.isEmpty) ||
        aboutController.text.isEmpty) {
      toastError("Please fill all required fields");
      return;
    }
    isReviewMode.value = true;
  }

  void goBackToForm() {
    isReviewMode.value = false;
  }

  final RxBool isLoading = false.obs;

  Future<void> submitRegistration() async {
    if (!acceptedTerms.value) {
      toastError(
          "Action Required: Please accept the Terms and Conditions to proceed.");
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

    try {
      final sellerSnapshot = await sellerRef.get();

      final categoryToSave = selectedCategory.value == 'Other'
          ? otherCategoryController.text.trim()
          : selectedCategory.value;

      if (sellerSnapshot.exists) {
        await sellerRef.update({
          'sellerName': sellerNameController.text.trim(),
          'location': locationController.text.trim(),
          'phone': fullPhoneNumber.value,
          'storeName': storeNameController.text.trim(),
          'upiId': upiIdController.text.trim(),
          'category': categoryToSave,
          'aboutBusiness': aboutController.text.trim(),
          'status': 'draft',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await sellerRef.set({
          'uid': uid,
          'sellerName': sellerNameController.text.trim(),
          'location': locationController.text.trim(),
          'phone': fullPhoneNumber.value,
          'storeName': storeNameController.text.trim(),
          'upiId': upiIdController.text.trim(),
          'category': categoryToSave,
          'aboutBusiness': aboutController.text.trim(),
          'status': 'draft',
          'storeOpenedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      toastSuccess("Store drafted successfully! Please proceed to payment.");
      if (selectedPlan != null) {
        Get.offAll(() => PaymentOptionsScreen(plan: selectedPlan!));
      } else {
        toastError("No plan selected, please restart the process.");
      }
    } on FirebaseException catch (e) {
      debugPrint("Firebase error: $e");
      toastError(
          "Unable to create your store. Please check your connection and try again.");
    } catch (e) {
      debugPrint("Unexpected error: $e");
      toastError("Unable to create your store. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openMapPicker() async {
    final result =
        await Get.to(() => const naattulink_map.SelectLocationMapPage(
              initialLat: 11.2588,
              initialLng: 75.7804,
              flow: naattulink_map.LocationPickerFlow.registration,
            ));
    if (result != null) {
      // Assuming result is AppLocationModel
      locationController.text =
          result.formattedAddress ?? result.district ?? '';
    }
  }
}

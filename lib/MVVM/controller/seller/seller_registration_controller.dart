import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart'
    as naattulink_map;
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_verification_screen.dart';

class SellerRegistrationController extends GetxController {
  static SellerRegistrationController get to => Get.find();

  final sellerNameController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController();
  final storeNameController = TextEditingController();
  final aboutController = TextEditingController();

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
    aboutController.dispose();
    super.onClose();
  }

  void proceedToReview() {
    if (sellerNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        phoneController.text.isEmpty ||
        storeNameController.text.isEmpty ||
        selectedCategory.value.isEmpty ||
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

      if (sellerSnapshot.exists) {
        await sellerRef.update({
          'sellerName': sellerNameController.text.trim(),
          'location': locationController.text.trim(),
          'phone': phoneController.text.trim(),
          'storeName': storeNameController.text.trim(),
          'category': selectedCategory.value,
          'aboutBusiness': aboutController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await sellerRef.set({
          'uid': uid,
          'sellerName': sellerNameController.text.trim(),
          'location': locationController.text.trim(),
          'phone': phoneController.text.trim(),
          'storeName': storeNameController.text.trim(),
          'category': selectedCategory.value,
          'aboutBusiness': aboutController.text.trim(),
          'status': 'pending',
          'storeOpenedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      toastSuccess("Store created successfully!");
      Get.offAll(() => const SellerVerificationScreen());
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

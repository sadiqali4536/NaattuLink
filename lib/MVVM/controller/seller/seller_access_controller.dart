import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/seller_model.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Introduction/seller_introduction_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_registration_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_dashboard_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/subscription_plans_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_verification_screen.dart';
import 'package:naattulink/MVVM/controller/seller/subscription_controller.dart';
import 'package:naattulink/MVVM/utils/subscription_date_utils.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class SellerAccessController extends GetxController {
  static SellerAccessController get to {
    if (!Get.isRegistered<SellerAccessController>()) {
      return Get.put(SellerAccessController(), permanent: true);
    }
    return Get.find<SellerAccessController>();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<SellerModel?> currentSeller = Rx<SellerModel?>(null);
  final RxBool isLoading = false.obs;

  Future<void> handleSellerNavigation() async {
    final user = _auth.currentUser;
    if (user == null) {
      toastError("Please login first.");
      return;
    }

    isLoading.value = true;
    try {
      await loadSeller(user.uid);

      final seller = currentSeller.value;
      if (seller == null) {
        // Document does not exist -> SellerIntroductionScreen
        Get.to(() => const SellerIntroductionScreen());
      } else {
        // Routing based on strict architecture rules
        if (seller.registrationStatus == 'pending_verification') {
          Get.to(() => const SellerVerificationScreen());
        } else if (seller.registrationStatus == 'rejected') {
          Get.to(() => const SellerIntroductionScreen());
        } else if (seller.registrationStatus == 'approved') {
          // Both active and expired approved sellers can enter dashboard
          // Expired sellers have locked Products and Orders tabs with read-only Home & History
          SubscriptionController.to.initSubscriptionStream();
          Get.to(() => const SellerDashboardScreen());
        } else {
          // Catch-all for not_started, draft, or any unknown state
          Get.to(() => const SubscriptionPlansScreen());
        }
      }
    } catch (e) {
      toastError("Failed to check seller status: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSeller(String uid) async {
    final doc = await _firestore.collection('sellers').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      currentSeller.value = SellerModel.fromMap(doc.data()!, doc.id);
    } else {
      currentSeller.value = null;
    }
  }

  bool get isRegistrationComplete =>
      currentSeller.value?.registrationStatus == 'completed' ||
      currentSeller.value?.registrationStatus == 'approved' ||
      currentSeller.value?.registrationStatus == 'pending_verification';

  bool get hasActiveTrial {
    final seller = currentSeller.value;
    if (seller == null || seller.trialEndDate == null) return false;
    return SubscriptionDateUtils.isSubscriptionActive(seller.trialEndDate);
  }

  bool get hasActiveSubscription {
    final seller = currentSeller.value;
    if (seller == null || seller.subscriptionEndDate == null) return false;
    return SubscriptionDateUtils.isSubscriptionActive(seller.subscriptionEndDate);
  }

  bool get hasSellerAccess {
    final seller = currentSeller.value;
    if (seller == null) return false;

    // Strict access validation
    bool isApproved =
        seller.adminVerified == true && seller.registrationStatus == 'approved';

    bool isValidSubscription =
        seller.subscriptionStatus == 'active' && hasActiveSubscription;

    // Allow full access if they are approved AND have either an active subscription or an active trial
    return isApproved && (isValidSubscription || hasActiveTrial);
  }

  int get remainingTrialDays {
    final seller = currentSeller.value;
    if (seller == null || seller.trialEndDate == null) return 0;
    return SubscriptionDateUtils.calculateRemainingDays(seller.trialEndDate);
  }
}


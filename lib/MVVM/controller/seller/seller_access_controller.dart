import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/seller_model.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Introduction/seller_introduction_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_registration_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/seller_dashboard_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/subscription_plans_screen.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Registration/seller_verification_screen.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class SellerAccessController extends GetxController {
  static SellerAccessController get to => Get.find();

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
        if (seller.status == 'pending' || seller.status == 'Pending') {
          Get.to(() => const SellerVerificationScreen());
        } else if (seller.status == 'active' || seller.status == 'Active') {
          Get.to(() => const SellerDashboardScreen());
        } else {
          Get.to(() => const SellerIntroductionScreen());
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
      currentSeller.value?.registrationStatus == 'completed';

  bool get isSellerActive => currentSeller.value?.status == 'active';

  bool get hasActiveTrial {
    final seller = currentSeller.value;
    if (seller == null || seller.trialEndDate == null) return false;
    // Note: This relies on device time for quick UI checks,
    // but actual validation should happen via Server timestamp in DB rules or cloud functions.
    return DateTime.now().isBefore(seller.trialEndDate!);
  }

  bool get hasActiveSubscription {
    final seller = currentSeller.value;
    if (seller == null || seller.subscriptionEndDate == null) return false;
    return DateTime.now().isBefore(seller.subscriptionEndDate!);
  }

  bool get hasSellerAccess =>
      isSellerActive && (hasActiveTrial || hasActiveSubscription);

  int get remainingTrialDays {
    final seller = currentSeller.value;
    if (seller == null || seller.trialEndDate == null) return 0;
    final diff = seller.trialEndDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/onboarding/onboarding_screen.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Home/Homepage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/User_Front_page.dart';

// import 'package:starter_project_feb/app/views/auth/login/login.dart';       // adjust path
// import 'package:starter_project_feb/app/views/dashboard/dashboard.dart';    // adjust path

class CommonController extends GetxController {
  static CommonController get to => Get.find<CommonController>();

  final onboardingCompleted =
      (GetStorage().read('onboarding').toString() == "true").obs;

  Future<void> getAppVersion() async {
    startTimer();

    // bool version;
    // try {
    //   var data = await ApiBasehandler.app_version();
    //   print('after call------------------');
    //   update();
    //
    //   appversion = data;
    //
    //   GetStorage()
    //       .write('privacy_policy', appversion['privacy_policy'].toString());
    //
    //   if (Platform.isIOS) {
    //     if (appversion['ios_payment_version'].toString() ==
    //         ios_version.toString()) {
    //       GetStorage().write('pay_version', 'true');
    //     } else {
    //       GetStorage().write('pay_version', 'false');
    //     }
    //   } else {
    //     if (appversion['android_payment_version'].toString() ==
    //         android_version.toString()) {
    //       GetStorage().write('pay_version', 'true');
    //     } else {
    //       GetStorage().write('pay_version', 'false');
    //     }
    //   }
    //
    //   if (GetPlatform.isIOS &&
    //           int.parse(dot_replace(appversion['ios_force_update'].toString())) >
    //               int.parse(dot_replace(ios_version.toString())) ||
    //       GetPlatform.isAndroid &&
    //           int.parse(dot_replace(appversion['android_force_update'].toString())) >
    //               int.parse(dot_replace(android_version.toString()))) {
    //     Get.offAll(() => force_update(data: [data]));
    //   } else {
    //     startTimer();
    //   }
    //
    //   is_appversion_loading = false;
    //   update();
    // } catch (e) {
    //   print("Error fetching app version: $e");
    // }
  }

  String dotReplace(String value) {
    return value.replaceAll('.', '');
  }

  void startTimer() {
    const duration = Duration(seconds: 2);
    Timer(duration, () {
      final bool isCompleted = onboardingCompleted.value;
      final user = FirebaseAuth.instance.currentUser;

      if (!isCompleted) {
        Get.offAll(() => const OnboardingScreen());
      } else if (user != null) {
        Get.offAll(() => const FindingLocationPage());
      } else {
        Get.offAll(() => const LoginAndSigning());
      }
    });
  }
}

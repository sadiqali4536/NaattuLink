import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:naattulink/MVVM/View/Authentication/onboarding/onboarding_screen.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/common_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:get_storage/get_storage.dart';

class Authgate extends StatefulWidget {
  const Authgate({super.key});

  @override
  State<Authgate> createState() => _AuthgateState();
}

class _AuthgateState extends State<Authgate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRoute();
    });
  }

  Future<void> _checkAuthAndRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!CommonController.to.onboardingCompleted.value) {
        CommonController.to.onboardingCompleted.value = true;
        GetStorage().write('onboarding', 'true');
      }
      await AuthController.to.routeAuthenticatedUser(user);
      return;
    }

    final isCompleted = CommonController.to.onboardingCompleted.value;
    if (!isCompleted) {
      Get.offAll(() => const OnboardingScreen());
      return;
    }

    Get.offAll(() => const LoginAndSigning());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: const Color(0xFF0A235C)),
      ),
    );
  }
}

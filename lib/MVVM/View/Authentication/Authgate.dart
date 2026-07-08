import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:naattulink/MVVM/View/Authentication/onboarding/onboarding_screen.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/common_controller.dart';

class Authgate extends StatelessWidget {
  const Authgate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isCompleted = CommonController.to.onboardingCompleted.value;
      if (!isCompleted) {
        return const OnboardingScreen();
      }

      // Check Firebase auth state
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return const FindingLocationPage();
      } else {
        return const LoginAndSigning();
      }
    });
  }
}

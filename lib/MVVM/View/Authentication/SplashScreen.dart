import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/common_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Authentication/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goToLocationPage();
  }

  Future<void> _goToLocationPage() async {
    // Wait for the animation to play slightly, then initialize
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final isCompleted = CommonController.to.onboardingCompleted.value;
    if (!isCompleted) {
      Get.offAll(() => const OnboardingScreen());
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await AuthController.to.routeAuthenticatedUser(user);
    } else {
      Get.offAll(() => const LoginAndSigning());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final logoWidth = screenWidth * 0.75;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "assets/bg/Splash.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: screenHeight * 0.12,
            left: (screenWidth - logoWidth) / 2,
            width: logoWidth,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Image.asset(
                "assets/logo/logo_with_name.png",
                width: logoWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

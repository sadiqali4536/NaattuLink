import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/current_loaction_fetch.dart';

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
    // Show splash for 3 seconds, then always open the location-fetch screen.
    // FindingLocationPage handles auth-check + routing after the location is ready.
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Get.off(() => const FindingLocationPage(), transition: Transition.zoom);
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/services/app_config_service.dart';

class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recheck version when returning from the store
      AppConfigService.to.initialize().then((_) {
        if (!AppConfigService.to.isForceUpdateRequired.value) {
          // Force update no longer required, redirect to splash to resume normal flow
          Get.offAllNamed('/'); // Adjust to your route or use Get.offAll(() => const SplashScreen());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.system_update_outlined, size: 80, color: Color(0xFF0C1F41)),
            const SizedBox(height: 24),
            const Text(
              'Update Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1F41),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A new version of NaattuLink is available. Please update to continue using the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Obx(() => Text('Installed Version: ${AppConfigService.to.installedVersion.value}')),
                  const SizedBox(height: 8),
                  Obx(() => Text('Minimum Required: ${AppConfigService.to.minimumRequiredVersion.value}')),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1F41),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  AppConfigService.to.launchStore();
                },
                child: const Text(
                  'Update Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

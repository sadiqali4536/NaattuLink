import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/services/app_config_service.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

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
            const Icon(Icons.build_circle_outlined, size: 80, color: Color(0xFF0C1F41)),
            const SizedBox(height: 24),
            const Text(
              'Maintenance Break',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1F41),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
              AppConfigService.to.maintenanceMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            )),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0C1F41)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () async {
                  await AppConfigService.to.initialize();
                  if (!AppConfigService.to.isMaintenanceMode.value) {
                    Get.offAllNamed('/'); // Or back to splash
                  }
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C1F41)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

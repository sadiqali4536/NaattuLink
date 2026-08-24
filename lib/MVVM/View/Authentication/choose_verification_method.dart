import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/forgot_password_controller.dart';

class ChooseVerificationMethodPage extends StatelessWidget {
  final String identifier;
  final List<Map<String, dynamic>> methods;

  const ChooseVerificationMethodPage({
    super.key,
    required this.identifier,
    required this.methods,
  });

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller =
        Get.find<ForgotPasswordController>();

    return Scaffold(
      backgroundColor: scaffoldBackground,
      appBar: AppBar(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: buttonColors),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verify Your Identity",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Choose how you want to receive your verification code",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ...methods.map((method) {
                final isEmail = method['type'] == 'email';
                final icon = isEmail ? Icons.email_outlined : Icons.sms_outlined;
                final title = isEmail ? "Email OTP" : "SMS OTP";
                final value = method['maskedValue'] ?? "";

                return Obx(() => GestureDetector(
                      onTap: controller.isLoading.value
                          ? null
                          : () {
                              controller.sendOtp(identifier, method['type']);
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 30, color: buttonColors),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                   ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (controller.isLoading.value)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: buttonColors,
                                ),
                              )
                            else
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ));
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

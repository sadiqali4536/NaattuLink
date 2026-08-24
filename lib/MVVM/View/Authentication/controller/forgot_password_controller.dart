import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/create_new_password_page.dart';
import 'package:naattulink/MVVM/View/Authentication/verify_otp_page.dart';
import 'package:naattulink/MVVM/View/Authentication/choose_verification_method.dart';
import 'package:naattulink/MVVM/model/services/password_reset_service.dart';

class ForgotPasswordController extends GetxController {
  var isLoading = false.obs;

  String? currentVerificationId;

  static void toastError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void toastSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> checkAccount(String identifier) async {
    isLoading.value = true;
    try {
      final response = await PasswordResetService.checkAccount(identifier);
      if (response != null && response['success'] == true) {
        final methods = List<Map<String, dynamic>>.from(response['methods']);
        Get.to(() => ChooseVerificationMethodPage(
              identifier: identifier,
              methods: methods,
            ));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendOtp(String identifier, String method) async {
    isLoading.value = true;
    try {
      final response = await PasswordResetService.sendOtp(
        identifier: identifier,
        method: method,
      );

      if (response != null && response['success'] == true) {
        currentVerificationId = response['verificationId'];
        Get.to(() => VerifyOtpPage(identifier: identifier));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp(String identifier, String enteredOtp) async {
    if (currentVerificationId == null) {
      toastError('Session expired. Please request a new code.');
      return;
    }

    isLoading.value = true;
    try {
      final response = await PasswordResetService.verifyOtp(
        verificationId: currentVerificationId!,
        otp: enteredOtp,
      );

      if (response != null && response['success'] == true) {
        final resetToken = response['resetToken'];
        Get.to(() => CreateNewPasswordPage(
              identifier: identifier,
              resetToken: resetToken,
            ));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePasswordAndLogin(BuildContext context, String identifier,
      String resetToken, String newPassword) async {
    
    if (currentVerificationId == null) {
      toastError('Session expired. Please start over.');
      return;
    }

    isLoading.value = true;
    try {
      final response = await PasswordResetService.resetPassword(
        verificationId: currentVerificationId!,
        resetToken: resetToken,
        newPassword: newPassword,
      );

      if (response != null && response['success'] == true) {
        final customToken = response['customToken'];
        
        // Auto-login with the custom token
        await AuthController.to.loginWithCustomToken(context, customToken);
      }
    } catch (e) {
      debugPrint('Error updating password: $e');
      toastError('An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }
}

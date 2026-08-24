import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/model/services/otp_service.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:pinput/pinput.dart';

class LoginVerifyOtpPage extends StatefulWidget {
  final String identifier;
  final String requestId;

  const LoginVerifyOtpPage({
    Key? key,
    required this.identifier,
    required this.requestId,
  }) : super(key: key);

  @override
  State<LoginVerifyOtpPage> createState() => _LoginVerifyOtpPageState();
}

class _LoginVerifyOtpPageState extends State<LoginVerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint("=== OTP VERIFICATION PAGE: STARTING VERIFY ===");
      debugPrint("RequestId: ${widget.requestId}");
      debugPrint("OTP entered: ${_otpController.text}");

      final response = await OtpService.verifyOtp(
        requestId: widget.requestId,
        otp: _otpController.text,
        purpose: 'login',
      );

      debugPrint("OTP VERIFICATION PAGE: Response received: $response");

      if (response != null && response['success'] == true) {
        if (response['customToken'] != null) {
          debugPrint(
              "OTP VERIFICATION PAGE: Custom Token found, proceeding to login.");
          final customToken = response['customToken'];
          await AuthController.to.loginWithCustomToken(context, customToken);
        } else {
          debugPrint(
              "OTP VERIFICATION PAGE: ERROR - Success is true, but customToken is null!");
        }
      } else {
        debugPrint(
            "OTP VERIFICATION PAGE: Verification failed or response is null.");
      }
    } catch (e) {
      debugPrint("OTP VERIFICATION PAGE: Exception caught - $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verify Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A235C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please enter the 4-digit code sent to\n${widget.identifier}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 4,
                  showCursor: true,
                  defaultPinTheme: PinTheme(
                    width: 60,
                    height: 60,
                    textStyle: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 60,
                    height: 60,
                    textStyle: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFF0A235C)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Custombutton(
                  color: const Color(0xFF0A235C),
                  borderRadius: 15,
                  text: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text(
                          "Verify Code",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                  onpress: _isLoading ? () {} : _verifyOtp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

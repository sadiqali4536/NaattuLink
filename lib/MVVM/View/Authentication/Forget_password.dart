import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/forgot_password_controller.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ForgotPasswordController forgotPasswordController =
      Get.put(ForgotPasswordController());

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final topHeight = mq.height * 0.28;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image (Static)
          Positioned(
            top: 0,
            left: 0,
            width: mq.width,
            height: mq.height,
            child: Image.asset(
              "assets/bg/user_registration_bg.png",
              fit: BoxFit.cover,
            ),
          ),
          // Top section (Logo) - Static
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight,
            child: Center(
              child: SafeArea(
                bottom: false,
                child: Image.asset(
                  "assets/logo/logo_with_name.png",
                  height: 200,
                ),
              ),
            ),
          ),
          // Bottom Form Card
          Positioned(
            top: topHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Center(
                                  child: Text(
                                    "Forgot Password",
                                    style: TextStyle(
                                      color: Color(0xFF0A235C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    "Enter your email or phone number to reset",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 35),
                                Customformfield(
                                  color: Colors.white,
                                  borderColor: const Color(0xFFE2E8F0),
                                  borderRadius: 15,
                                  hinttext: "Email or Phone Number",
                                  hintstyle:
                                      const TextStyle(color: Color(0xFF94A3B8)),
                                  prefixicon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  controller: _emailController,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Please enter your Email or Phone Number";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: Obx(() => Custombutton(
                                        color: const Color(0xFF0A235C),
                                        borderRadius: 15,
                                        text: forgotPasswordController
                                                .isLoading.value
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                "Continue",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                        onpress: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            forgotPasswordController
                                                .checkAccount(
                                                    _emailController.text);
                                          }
                                        },
                                      )),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Remember your password? ",
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 15,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        HelperFunctions.navigateToScreenPop(
                                            context, const LoginAndSigning());
                                      },
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Color(0xFF0A235C),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

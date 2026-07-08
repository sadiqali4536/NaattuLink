import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/Forget_password.dart';
import 'package:naattulink/MVVM/View/Authentication/Registrationpage.dart';
import 'package:naattulink/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield.dart';

class LoginAndSigning extends StatefulWidget {
  const LoginAndSigning({super.key});

  @override
  State<LoginAndSigning> createState() => _LoginAndSigningState();
}

class _LoginAndSigningState extends State<LoginAndSigning> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
          // Bottom Form Card - Static Container
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
                key: formKey,
                child: Column(
                  children: [
                    // Scrollable form fields and login buttons
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
                                const SizedBox(height: 5),
                                const Center(
                                  child: Text(
                                    "Welcome Back!",
                                    style: TextStyle(
                                      color: Color(0xFF0A235C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    "Login to continue to your account",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Email field
                                Customformfield(
                                  color: Colors.white,
                                  borderColor: const Color(0xFFE2E8F0),
                                  borderRadius: 15,
                                  hinttext: "Email or Phone Number",
                                  hintstyle:
                                      const TextStyle(color: Color(0xFF94A3B8)),
                                  prefixicon: const Icon(Icons.mail_outline,
                                      color: Color(0xFF94A3B8)),
                                  controller: _emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required field";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Password field
                                Customformfield(
                                  color: Colors.white,
                                  borderColor: const Color(0xFFE2E8F0),
                                  borderRadius: 15,
                                  hinttext: "Password",
                                  hintstyle:
                                      const TextStyle(color: Color(0xFF94A3B8)),
                                  prefixicon: const Icon(Icons.lock_outline,
                                      color: Color(0xFF94A3B8)),
                                  controller: _passwordController,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Required field";
                                    }
                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }
                                    return null;
                                  },
                                ),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        Get.to(() => ForgetPassword());
                                      },
                                      child: const Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: Color(0xFF0A235C),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Login Button
                                SizedBox(
                                  height: 55,
                                  width: double.infinity,
                                  child: Obx(() => Custombutton(
                                        color: const Color(0xFF0A235C),
                                        borderRadius: 15,
                                        text: AuthController.to.isLoading
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                "Login",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                        onpress: _handleLogin,
                                      )),
                                ),
                                const SizedBox(height: 20),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        "OR CONTINUE WITH",
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Google Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: OutlinedButton(
                                    onPressed: _handleGoogleSignIn,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          "assets/icons/google_logo.png",
                                          height: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Google",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Don't have an account? Register (Pinned permanently to the bottom)
                    SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const Registrationpage());
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: Color(0xFF0A235C),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
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

  Future<void> _handleLogin() async {
    if (formKey.currentState!.validate()) {
      await AuthController.to.login(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await AuthController.to.loginWithGoogle(context);
  }
}

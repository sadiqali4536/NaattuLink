import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/Forget_password.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/Registrationpage.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:swiftclean_project/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/widget/button/custombutton.dart';
import 'package:swiftclean_project/MVVM/utils/widget/formfield/customformfield.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/image/UserLoginSignin.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
              top: 20,
              left: 290,
              child:
                  Image.asset("assets/icons/logo2.png", height: 70, width: 70)),
          Positioned(
              top: 50,
              left: 250,
              child:
                  Image.asset("assets/icons/SWIFT.png", height: 70, width: 70)),
          Positioned(
              top: 50,
              left: 320,
              child:
                  Image.asset("assets/icons/CLEAN.png", height: 70, width: 70)),
          Positioned(
            top: mq.height * 0.36,
            left: mq.width * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your One-Stop Solution for All",
                    style: TextStyle(
                        color: primary.c ?? Colors.white, fontSize: 18)),
                const SizedBox(height: 5),
                Text("Cleaning Needs!",
                    style: TextStyle(
                        color: primary.c ?? Colors.white, fontSize: 18)),
              ],
            ),
          ),
          Positioned(
            top: mq.height * 0.65,
            child: Column(
              children: [
                SizedBox(
                  height: 60,
                  width: 230,
                  child: Custombutton(
                    text: Text("Sign In",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: primary.c)),
                    onpress: () => _showLoginSheet(context, mq),
                  ),
                ),
                const SizedBox(height: 70),
                SizedBox(
                  height: 60,
                  width: 230,
                  child: Custombutton(
                    text: Text("Sign Up",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: primary.c)),
                    onpress: () => _showRegisterSheet(context, mq),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginSheet(BuildContext context, Size mq) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(241, 242, 243, 1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      context: context,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text("Welcome back",
                              style: TextStyle(
                                  color: black.c,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30)),
                        ),
                        const SizedBox(height: 30),
                        _buildLabel("Email"),
                        _buildField(
                            _emailController,
                            "Enter your Email Address",
                            TextInputType.emailAddress),
                        const SizedBox(height: 15),
                        _buildLabel("Password"),
                        _buildField(_passwordController, "Enter your Password",
                            TextInputType.visiblePassword,
                            obscure: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ForgetPassword()));
                            },
                            child: Text("Forgot Password?",
                                style: TextStyle(
                                    color: gradientgreen2.c,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            height: 60,
                            width: 226,
                            child: Material(
                              elevation: 10,
                              shadowColor: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(40),
                              child: Custombutton(
                                text: isLoading
                                    ? Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white))
                                    : Text("Sign In",
                                        style: TextStyle(
                                            color: primary.c, fontSize: 20)),
                                onpress: () async {
                                  if (formKey.currentState!.validate()) {
                                    setModalState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // Attempt sign in
                                      final user =
                                          await FirebaseAuthServices().signIn(
                                        context,
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                      );

                                      if (user != null) {
                                        final userId = FirebaseAuth
                                            .instance.currentUser?.uid;

                                        // Fetch user role from Firestore
                                        final userDoc = await FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(userId)
                                            .get();

                                        final workerDoc =
                                            await FirebaseFirestore.instance
                                                .collection('workers')
                                                .doc(userId)
                                                .get();

                                        final userrole =
                                            userDoc.data()?['role'];
                                        final workerrole =
                                            workerDoc.data()?['role'];

                                        if (userrole == 'user') {
                                          Get.offAll(
                                            () => const FindingLocationPage(),
                                          );
                                        } else if (workerrole == 'worker') {
                                          // Fetch worker verification status
                                          final workerDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('workers')
                                                  .doc(userId)
                                                  .get();

                                          final isVerified =
                                              workerDoc.data()?['isVerified'];

                                          if (isVerified == 1) {
                                            Get.offAll(
                                              () => const FindingLocationPage(),
                                            );
                                          } else if (isVerified == -1) {
                                            Get.snackbar(
                                              'Verification',
                                              'Your profile has been rejected by the admin due to an unsatisfactory reason.',
                                              backgroundColor: Colors.black,
                                              colorText: Colors.white,
                                            );
                                          } else if (isVerified == 0) {
                                            Get.snackbar(
                                              'Verification',
                                              'Your profile is currently under review by the admin. Please wait a moment.',
                                              backgroundColor: Colors.black,
                                              colorText: Colors.white,
                                            );
                                          } else {
                                            Get.snackbar(
                                              'Verification',
                                              'Unknown verification status. Please contact support.',
                                              backgroundColor: Colors.black,
                                              colorText: Colors.white,
                                            );
                                          }
                                        } else {
                                          Get.snackbar(
                                            'Error',
                                            'Unable to determine user role.',
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      print('Login error: $e');
                                      Get.snackbar(
                                        'Login Failed',
                                        e.toString(),
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    } finally {
                                      setModalState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                            child: Text("Or Sign in with",
                                style: TextStyle(color: Colors.grey[600]))),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  FirebaseAuthServices()
                                      .signInWithGoogle()
                                      .then((value) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(value)));
                                  });
                                },
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/icons/google_logo.png")),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              SizedBox(width: mq.width * 0.05),
                              GestureDetector(
                                onTap: () {
                                  // Gmail tap
                                },
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/icons/gmail-logo.png")),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRegisterSheet(BuildContext context, Size mq) {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      backgroundColor: const Color.fromRGBO(241, 242, 243, 1),
      context: context,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.9,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Registrationpage(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hintText,
    TextInputType inputType, {
    bool obscure = false,
  }) {
    return Center(
      child: SizedBox(
        width: 360,
        child: Customformfield(
          color: formfield.c,
          hinttext: hintText,
          hintstyle: TextStyle(color: formletters.c),
          obscureText: obscure,
          controller: controller,
          validator: (value) {
            if (value == null || value.isEmpty) return "Required field";
            if (hintText.contains("Email") &&
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return "Enter a valid email address";
            }
            if (hintText.contains("Password") && value.length < 6) {
              return "Password must be at least 6 characters";
            }
            return null;
          },
        ),
      ),
    );
  }
}

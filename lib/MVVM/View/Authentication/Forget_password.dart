import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            /// Background Image
            Image.asset(
              "assets/image/carpet.png",
              width: double.infinity,
              height: mq.height,
              fit: BoxFit.cover,
            ),

            /// Logo (Removed missing images to prevent PathNotFoundException)
            // Positioned(
            //   top: 20,
            //   left: 280,
            //   child:
            //       Image.asset("assets/icons/logo2.png", height: 70, width: 70),
            // ),
            // Positioned(
            //   top: 60,
            //   left: 260,
            //   child:
            //       Image.asset("assets/icons/SWIFT.png", height: 50, width: 55),
            // ),
            Positioned(
              top: 60,
              left: 320,
              child:
                  Image.asset("assets/icons/CLEAN.png", height: 50, width: 55),
            ),

            /// Rounded Container
            Positioned(
              top: mq.height * 0.4,
              child: Container(
                height: mq.height * 0.6,
                width: mq.width,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(220, 221, 227, 1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Forgot Password",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(right: 280),
                        child: Text(
                          "Email",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 08),

                      /// Form with Email Field
                      Form(
                        key: _formKey,
                        child: SizedBox(
                          width: 360,
                          child: Customformfield(
                            color: formfield.c,
                            hinttext: "Enter your Email Address",
                            hintstyle: TextStyle(color: formletters.c),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please Enter your Email Address";
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                            controller: _emailController,
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      /// Reset Password Button
                      SizedBox(
                        height: 55,
                        width: 220,
                        child: Material(
                          elevation: 10,
                          borderRadius: BorderRadius.circular(30),
                          child: Custombutton(
                            text: const Text(
                              "Reset Password",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            onpress: () {
                              if (_formKey.currentState!.validate()) {
                                print("Password reset link sent to email");
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 95, left: 35),
                        child: Row(
                          children: [
                            Text(
                              "Remember your password?",
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                HelperFunctions.navigateToScreenPop(
                                    context, LoginAndSigning());
                              },
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                    fontSize: 18, color: gradientgreen2.c),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

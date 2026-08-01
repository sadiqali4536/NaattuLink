// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
// // import 'package:naattulink/MVVM/utils/widget/button/dropdown/custdropdown.dart';

// // class Registrationpage extends StatefulWidget {
// //   const Registrationpage({super.key});

// //   @override
// //   State<Registrationpage> createState() => _RegistrationpageState();
// // }

// // class _RegistrationpageState extends State<Registrationpage> {
// //   int selectedIndex = 0;
// //   bool isUser = true;
// //   bool _agreeToTerms = false;

// //   // Controllers for user fields
// //   final TextEditingController userNameController = TextEditingController();
// //   final TextEditingController userPhoneController = TextEditingController();
// //   final TextEditingController userEmailController = TextEditingController();
// //   final TextEditingController userPasswordController = TextEditingController();
// //   final TextEditingController userConfirmPasswordController =
// //       TextEditingController();

// //   // Controllers for worker fields
// //   final TextEditingController workerNameController = TextEditingController();
// //   final TextEditingController workerPhoneController = TextEditingController();
// //   final TextEditingController workerEmailController = TextEditingController();
// //   final TextEditingController workerPasswordController =
// //       TextEditingController();
// //   final TextEditingController workerConfirmPasswordController =
// //       TextEditingController();

// //   String? selectedCategory = "";
// //   final formKey = GlobalKey<FormState>();

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       resizeToAvoidBottomInset: true,
// //       body: Stack(
// //         children: [
// //           // Background Image (Static, covers full screen)
// //           Positioned.fill(
// //             child: Image.asset(
// //               isUser
// //                   ? "assets/bg/user_registration_bg.png"
// //                   : "assets/bg/worker_registration_bg.png",
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           // Scrollable Content
// //           SafeArea(
// //             child: Form(
// //               key: formKey,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   // Back Button at the top left (fixed in place)
// //                   Padding(
// //                     padding: const EdgeInsets.only(left: 12.0, top: 10.0),
// //                     child: IconButton(
// //                       icon: const Icon(Icons.arrow_back,
// //                           color: Color(0xFF0A235C), size: 28),
// //                       onPressed: () {
// //                         Get.back();
// //                       },
// //                     ),
// //                   ),
// //                   // Scrollable Form Content
// //                   Expanded(
// //                     child: SingleChildScrollView(
// //                       physics: const BouncingScrollPhysics(),
// //                       child: Align(
// //                         alignment: Alignment.topCenter,
// //                         child: Padding(
// //                           padding: const EdgeInsets.symmetric(horizontal: 24.0),
// //                           child: ConstrainedBox(
// //                             constraints: const BoxConstraints(maxWidth: 360),
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 // Circular Logo
// //                                 Center(
// //                                   child: Image.asset(
// //                                     "assets/logo/logo without name.png",
// //                                     height: 120,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 15),
// //                                 const Center(
// //                                   child: Text(
// //                                     "Create Account",
// //                                     style: TextStyle(
// //                                       color: Color(0xFF0A235C),
// //                                       fontWeight: FontWeight.bold,
// //                                       fontSize: 28,
// //                                     ),
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 8),
// //                                 const Center(
// //                                   child: Text(
// //                                     "Join us and enjoy the best experience",
// //                                     style: TextStyle(
// //                                       color: Colors.grey,
// //                                       fontSize: 14,
// //                                       fontWeight: FontWeight.w400,
// //                                     ),
// //                                     textAlign: TextAlign.center,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 25),

// //                                 // Role Toggle
// //                                 _buildRoleToggle(),
// //                                 const SizedBox(height: 25),

// //                                 // Form Fields
// //                                 ...(isUser
// //                                     ? _buildUserFields()
// //                                     : _buildWorkerFields()),
// //                                 const SizedBox(height: 15),

// //                                 // Terms & Conditions Checkbox
// //                                 Row(
// //                                   children: [
// //                                     Checkbox(
// //                                       value: _agreeToTerms,
// //                                       activeColor: const Color(0xFF0A235C),
// //                                       onChanged: (value) {
// //                                         setState(() {
// //                                           _agreeToTerms = value ?? false;
// //                                         });
// //                                       },
// //                                     ),
// //                                     Expanded(
// //                                       child: RichText(
// //                                         text: TextSpan(
// //                                           text: "I agree to the ",
// //                                           style: TextStyle(
// //                                               color: Colors.grey[600],
// //                                               fontSize: 13),
// //                                           children: const [
// //                                             TextSpan(
// //                                               text: "Terms & Conditions",
// //                                               style: TextStyle(
// //                                                 color: Color(0xFF0A235C),
// //                                                 fontWeight: FontWeight.bold,
// //                                               ),
// //                                             ),
// //                                             TextSpan(text: " and "),
// //                                             TextSpan(
// //                                               text: "Privacy Policy",
// //                                               style: TextStyle(
// //                                                 color: Color(0xFF0A235C),
// //                                                 fontWeight: FontWeight.bold,
// //                                               ),
// //                                             ),
// //                                           ],
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 const SizedBox(height: 25),

// //                                 // Register Button
// //                                 SizedBox(
// //                                   height: 55,
// //                                   width: double.infinity,
// //                                   child: Custombutton(
// //                                     color: const Color(0xFF0A235C),
// //                                     borderRadius: 15,
// //                                     text: const Text(
// //                                       "Register",
// //                                       style: TextStyle(
// //                                         color: Colors.white,
// //                                         fontSize: 18,
// //                                         fontWeight: FontWeight.bold,
// //                                       ),
// //                                     ),
// //                                     onpress: _handleRegister,
// //                                   ),
// //                                 ),
// //                                 const SizedBox(height: 25),

// //                                 // Already have an account? Login
// //                                 Row(
// //                                   mainAxisAlignment: MainAxisAlignment.center,
// //                                   children: [
// //                                     Text(
// //                                       "Already have an account? ",
// //                                       style: TextStyle(
// //                                         color: Colors.grey[600],
// //                                         fontSize: 15,
// //                                       ),
// //                                     ),
// //                                     GestureDetector(
// //                                       onTap: () {
// //                                         Get.back();
// //                                       },
// //                                       child: const Text(
// //                                         "Login",
// //                                         style: TextStyle(
// //                                           color: Color(0xFF0A235C),
// //                                           fontWeight: FontWeight.bold,
// //                                           fontSize: 15,
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ],
// //                                 ),
// //                                 const SizedBox(height: 30),
// //                               ],
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildRoleToggle() {
// //     return Container(
// //       width: double.infinity,
// //       height: 55,
// //       decoration: BoxDecoration(
// //         color: const Color(0xFFF1F5F9),
// //         borderRadius: BorderRadius.circular(30),
// //       ),
// //       padding: const EdgeInsets.all(4),
// //       child: Row(
// //         children: [
// //           // User Role Button
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setState(() {
// //                   selectedIndex = 0;
// //                   isUser = true;
// //                 });
// //               },
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: isUser ? const Color(0xFF0A235C) : Colors.transparent,
// //                   borderRadius: BorderRadius.circular(26),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.person_outline,
// //                       color: isUser ? Colors.white : const Color(0xFF64748B),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "User",
// //                       style: TextStyle(
// //                         color: isUser ? Colors.white : const Color(0xFF64748B),
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 16,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //           // Worker Role Button
// //           Expanded(
// //             child: GestureDetector(
// //               onTap: () {
// //                 setState(() {
// //                   selectedIndex = 1;
// //                   isUser = false;
// //                 });
// //               },
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   color: !isUser ? const Color(0xFF0A235C) : Colors.transparent,
// //                   borderRadius: BorderRadius.circular(26),
// //                 ),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(
// //                       Icons.business_center_outlined,
// //                       color: !isUser ? Colors.white : const Color(0xFF64748B),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Text(
// //                       "Business / Worker",
// //                       style: TextStyle(
// //                         color: !isUser ? Colors.white : const Color(0xFF64748B),
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 16,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   List<Widget> _buildUserFields() {
// //     return [
// //       RegistrationInputField(
// //         label: "FULL NAME",
// //         hintText: "Enter your full name",
// //         prefixIcon: Icons.person_outline,
// //         controller: userNameController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your username';
// //           }
// //           if (value.length < 3) {
// //             return 'Username must be at least 3 characters';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "EMAIL",
// //         hintText: "Enter your email",
// //         prefixIcon: Icons.mail_outline,
// //         controller: userEmailController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your email';
// //           }
// //           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
// //             return 'Please enter a valid email';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "PHONE NUMBER",
// //         hintText: "Enter your phone number",
// //         prefixIcon: Icons.phone_outlined,
// //         controller: userPhoneController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your phone number';
// //           }
// //           if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
// //             return 'Please enter a valid phone number';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "PASSWORD",
// //         hintText: "Create a password",
// //         prefixIcon: Icons.lock_outline,
// //         controller: userPasswordController,
// //         isPassword: true,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your password';
// //           }
// //           if (value.length < 6) {
// //             return 'Password must be at least 6 characters';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "CONFIRM PASSWORD",
// //         hintText: "Confirm your password",
// //         prefixIcon: Icons.lock_outline,
// //         controller: userConfirmPasswordController,
// //         isPassword: true,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please confirm your password';
// //           }
// //           if (value != userPasswordController.text) {
// //             return 'Passwords do not match';
// //           }
// //           return null;
// //         },
// //       ),
// //     ];
// //   }

// //   List<Widget> _buildWorkerFields() {
// //     return [
// //       const Text(
// //         "Service Category",
// //         style: TextStyle(
// //             fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
// //       ),
// //       const SizedBox(height: 8),
// //       Custdropdown(
// //         items: const ["Exterior", "Interior", "Vehicle", "Pet", "Home"],
// //         onchanged: (value) {
// //           setState(() {
// //             selectedCategory = value;
// //           });
// //         },
// //       ),
// //       const SizedBox(height: 15),
// //       RegistrationInputField(
// //         label: "FULL NAME",
// //         hintText: "Enter your full name",
// //         prefixIcon: Icons.person_outline,
// //         controller: workerNameController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your username';
// //           }
// //           if (value.length < 3) {
// //             return 'Username must be at least 3 characters';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "EMAIL",
// //         hintText: "Enter your email",
// //         prefixIcon: Icons.mail_outline,
// //         controller: workerEmailController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your email';
// //           }
// //           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
// //             return 'Please enter a valid email';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "PHONE NUMBER",
// //         hintText: "Enter your phone number",
// //         prefixIcon: Icons.phone_outlined,
// //         controller: workerPhoneController,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your phone number';
// //           }
// //           if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
// //             return 'Please enter a valid phone number';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "PASSWORD",
// //         hintText: "Create a password",
// //         prefixIcon: Icons.lock_outline,
// //         controller: workerPasswordController,
// //         isPassword: true,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter your password';
// //           }
// //           if (value.length < 6) {
// //             return 'Password must be at least 6 characters';
// //           }
// //           return null;
// //         },
// //       ),
// //       RegistrationInputField(
// //         label: "CONFIRM PASSWORD",
// //         hintText: "Confirm your password",
// //         prefixIcon: Icons.lock_outline,
// //         controller: workerConfirmPasswordController,
// //         isPassword: true,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please confirm your password';
// //           }
// //           if (value != workerPasswordController.text) {
// //             return 'Passwords do not match';
// //           }
// //           return null;
// //         },
// //       ),
// //     ];
// //   }

// //   void _handleRegister() {
// //     if (!_agreeToTerms) {
// //       Get.snackbar(
// //         "Agreement Required",
// //         "Please read and agree to the Terms & Conditions and Privacy Policy to register.",
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }

// //     if (formKey.currentState!.validate()) {
// //       if (isUser) {
// //         registerUser();
// //       } else {
// //         registerWorker();
// //       }
// //     }
// //   }

// //   void registerUser() async {
// //     try {
// //       final userCredential =
// //           await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //         email: userEmailController.text.trim(),
// //         password: userPasswordController.text.trim(),
// //       );
// //       final uid = userCredential.user!.uid;

// //       await FirebaseFirestore.instance.collection("users").doc(uid).set({
// //         "username": userNameController.text.trim(),
// //         "phone": userPhoneController.text.trim(),
// //         "email": userEmailController.text.trim(),
// //         "role": "user",
// //         "profile_img": "",
// //         "created_at": FieldValue.serverTimestamp(),
// //         "updated_at": FieldValue.serverTimestamp(),
// //         "status": "active",
// //         "password": userPasswordController.text.trim(),
// //         "loyalty_points": 0,
// //       });

// //       Get.snackbar("Success", "User registered successfully",
// //           backgroundColor: Colors.green, colorText: Colors.white);
// //       if (mounted) Navigator.pop(context);
// //     } on FirebaseAuthException catch (e) {
// //       _handleAuthError(e);
// //     } catch (e) {
// //       Get.snackbar("Error", "Something went wrong. Please try again.$e",
// //           backgroundColor: Colors.red, colorText: Colors.white);
// //     }
// //   }

// //   void registerAdmin() async {
// //     try {
// //       final userCredential =
// //           await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //         email: userEmailController.text.trim(),
// //         password: userPasswordController.text.trim(),
// //       );
// //       final uid = userCredential.user!.uid;

// //       await FirebaseFirestore.instance.collection("admin").doc(uid).set({
// //         "username": userNameController.text.trim(),
// //         "email": userEmailController.text.trim(),
// //         "role": "admin",
// //         "profile_img": "",
// //         "created_at": FieldValue.serverTimestamp(),
// //         "password": userPasswordController.text.trim(),
// //       });

// //       Get.snackbar("Success", "User registered successfully",
// //           backgroundColor: Colors.green, colorText: Colors.white);
// //       if (mounted) Navigator.pop(context);
// //     } on FirebaseAuthException catch (e) {
// //       _handleAuthError(e);
// //     } catch (e) {
// //       Get.snackbar("Error", "Something went wrong. Please try again.$e",
// //           backgroundColor: Colors.red, colorText: Colors.white);
// //     }
// //   }

// //   void registerWorker() async {
// //     if (selectedCategory == null || selectedCategory!.isEmpty) {
// //       Get.snackbar("Error", "Please select a service category",
// //           backgroundColor: Colors.red, colorText: Colors.white);
// //       return;
// //     }

// //     try {
// //       final userCredential =
// //           await FirebaseAuth.instance.createUserWithEmailAndPassword(
// //         email: workerEmailController.text.trim(),
// //         password: workerPasswordController.text.trim(),
// //       );
// //       final uid = userCredential.user!.uid;

// //       await FirebaseFirestore.instance.collection("workers").doc(uid).set({
// //         "username": workerNameController.text.trim(),
// //         "phone": workerPhoneController.text.trim(),
// //         "email": workerEmailController.text.trim(),
// //         "role": "worker",
// //         "category": selectedCategory,
// //         "profile_img": "",
// //         "created_at": FieldValue.serverTimestamp(),
// //         "updated_at": FieldValue.serverTimestamp(),
// //         "status": "pending",
// //         "services": [],
// //         "ratings": 0,
// //         "total_reviews": 0,
// //         "isVerified": 0,
// //         "password": workerPasswordController.text.trim(),
// //       });

// //       Get.snackbar(
// //           "Success", "Worker registered successfully. Awaiting admin approval.",
// //           backgroundColor: Colors.green, colorText: Colors.white);
// //       if (mounted) Navigator.pop(context);
// //     } on FirebaseAuthException catch (e) {
// //       _handleAuthError(e);
// //     } catch (e) {
// //       Get.snackbar("Error", "Something went wrong. Please try again.",
// //           backgroundColor: Colors.red, colorText: Colors.white);
// //     }
// //   }

// //   void _handleAuthError(FirebaseAuthException e) {
// //     String errorMessage = switch (e.code) {
// //       'weak-password' => 'The password provided is too weak.',
// //       'email-already-in-use' => 'An account already exists for that email.',
// //       'invalid-email' => 'Please enter a valid email address.',
// //       _ => e.message ?? "An unknown error occurred",
// //     };
// //     Get.snackbar("Error", errorMessage,
// //         backgroundColor: Colors.red, colorText: Colors.white);
// //   }
// // }

// // class RegistrationInputField extends StatefulWidget {
// //   final String label;
// //   final String hintText;
// //   final IconData prefixIcon;
// //   final TextEditingController controller;
// //   final bool isPassword;
// //   final FormFieldValidator<String>? validator;

// //   const RegistrationInputField({
// //     super.key,
// //     required this.label,
// //     required this.hintText,
// //     required this.prefixIcon,
// //     required this.controller,
// //     this.isPassword = false,
// //     this.validator,
// //   });

// //   @override
// //   State<RegistrationInputField> createState() => _RegistrationInputFieldState();
// // }

// // class _RegistrationInputFieldState extends State<RegistrationInputField> {
// //   bool _obscureText = true;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 15),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(20),
// //         border: Border.all(color: const Color(0xFFE2E8F0)),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withOpacity(0.01),
// //             blurRadius: 10,
// //             offset: const Offset(0, 4),
// //           ),
// //         ],
// //       ),
// //       padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.center,
// //         children: [
// //           Icon(widget.prefixIcon, color: const Color(0xFF94A3B8), size: 24),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Text(
// //                   widget.label,
// //                   style: const TextStyle(
// //                     color: Color(0xFF0A235C),
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.bold,
// //                     letterSpacing: 0.5,
// //                   ),
// //                 ),
// //                 TextFormField(
// //                   controller: widget.controller,
// //                   obscureText: widget.isPassword ? _obscureText : false,
// //                   validator: widget.validator,
// //                   style: const TextStyle(
// //                     fontSize: 15,
// //                     color: Colors.black,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                   decoration: InputDecoration(
// //                     isDense: true,
// //                     contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
// //                     hintText: widget.hintText,
// //                     hintStyle:
// //                         const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
// //                     border: InputBorder.none,
// //                     enabledBorder: InputBorder.none,
// //                     focusedBorder: InputBorder.none,
// //                     errorBorder: InputBorder.none,
// //                     focusedErrorBorder: InputBorder.none,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           if (widget.isPassword)
// //             IconButton(
// //               icon: Icon(
// //                 _obscureText
// //                     ? Icons.visibility_outlined
// //                     : Icons.visibility_off_outlined,
// //                 color: const Color(0xFF94A3B8),
// //                 size: 20,
// //               ),
// //               onPressed: () {
// //                 setState(() {
// //                   _obscureText = !_obscureText;
// //                 });
// //               },
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
// import 'package:naattulink/MVVM/utils/widget/button/dropdown/custdropdown.dart';

// class Registrationpage extends StatefulWidget {
//   const Registrationpage({super.key});

//   @override
//   State<Registrationpage> createState() => _RegistrationpageState();
// }

// class _RegistrationpageState extends State<Registrationpage> {
//   int selectedIndex = 0;
//   bool isUser = true;
//   bool _agreeToTerms = false;

//   // Controllers for user fields
//   final TextEditingController userNameController = TextEditingController();
//   final TextEditingController userPhoneController = TextEditingController();
//   final TextEditingController userEmailController = TextEditingController();
//   final TextEditingController userPasswordController = TextEditingController();
//   final TextEditingController userConfirmPasswordController =
//       TextEditingController();

//   // Controllers for worker fields
//   final TextEditingController workerNameController = TextEditingController();
//   final TextEditingController workerPhoneController = TextEditingController();
//   final TextEditingController workerEmailController = TextEditingController();
//   final TextEditingController workerPasswordController =
//       TextEditingController();
//   final TextEditingController workerConfirmPasswordController =
//       TextEditingController();

//   String? selectedCategory = "";
//   final formKey = GlobalKey<FormState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       body: Stack(
//         children: [
//           // Background Image (Static, covers full screen)
//           Positioned.fill(
//             child: Image.asset(
//               isUser
//                   ? "assets/bg/user_registration_bg.png"
//                   : "assets/bg/worker_registration_bg.png",
//               fit: BoxFit.cover,
//             ),
//           ),
//           // Scrollable Content
//           SafeArea(
//             child: Form(
//               key: formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Back Button at the top left (fixed in place)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 12.0, top: 10.0),
//                     child: IconButton(
//                       icon: const Icon(Icons.arrow_back,
//                           color: Color(0xFF0A235C), size: 28),
//                       onPressed: () {
//                         Get.back();
//                       },
//                     ),
//                   ),
//                   // Scrollable Form Content
//                   Expanded(
//                     child: SingleChildScrollView(
//                       physics: const BouncingScrollPhysics(),
//                       child: Align(
//                         alignment: Alignment.topCenter,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                           child: ConstrainedBox(
//                             constraints: const BoxConstraints(maxWidth: 360),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // Circular Logo
//                                 Column(
//                                   children: [
//                                     Center(
//                                       child: Image.asset(
//                                         "assets/logo/logo without name.png",
//                                         height: 160,
//                                       ),
//                                     ),
//                                     const Center(
//                                       child: Text(
//                                         "Create Account",
//                                         style: TextStyle(
//                                           color: Color(0xFF0A235C),
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 28,
//                                         ),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     const Center(
//                                       child: Text(
//                                         "Join us and enjoy the best experience",
//                                         style: TextStyle(
//                                           color: Colors.grey,
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w400,
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 25),
//                                   ],
//                                 ),
//                                 // const SizedBox(height: 15),

//                                 // Role Toggle
//                                 _buildRoleToggle(),
//                                 const SizedBox(height: 25),

//                                 // Form Fields
//                                 ...(isUser
//                                     ? _buildUserFields()
//                                     : _buildWorkerFields()),
//                                 const SizedBox(height: 15),

//                                 // Terms & Conditions Checkbox
//                                 Row(
//                                   children: [
//                                     Checkbox(
//                                       value: _agreeToTerms,
//                                       activeColor: const Color(0xFF0A235C),
//                                       onChanged: (value) {
//                                         setState(() {
//                                           _agreeToTerms = value ?? false;
//                                         });
//                                       },
//                                     ),
//                                     Expanded(
//                                       child: RichText(
//                                         text: TextSpan(
//                                           text: "I agree to the ",
//                                           style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontSize: 13),
//                                           children: const [
//                                             TextSpan(
//                                               text: "Terms & Conditions",
//                                               style: TextStyle(
//                                                 color: Color(0xFF0A235C),
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             TextSpan(text: " and "),
//                                             TextSpan(
//                                               text: "Privacy Policy",
//                                               style: TextStyle(
//                                                 color: Color(0xFF0A235C),
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 25),

//                                 // Register Button
//                                 SizedBox(
//                                   height: 55,
//                                   width: double.infinity,
//                                   child: Custombutton(
//                                     color: const Color(0xFF0A235C),
//                                     borderRadius: 15,
//                                     text: const Text(
//                                       "Register",
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     onpress: _handleRegister,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 25),

//                                 // Already have an account? Login
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       "Already have an account? ",
//                                       style: TextStyle(
//                                         color: Colors.grey[600],
//                                         fontSize: 15,
//                                       ),
//                                     ),
//                                     GestureDetector(
//                                       onTap: () {
//                                         Get.back();
//                                       },
//                                       child: const Text(
//                                         "Login",
//                                         style: TextStyle(
//                                           color: Color(0xFF0A235C),
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 30),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRoleToggle() {
//     return Container(
//       width: double.infinity,
//       height: 55,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F5F9),
//         borderRadius: BorderRadius.circular(30),
//       ),
//       padding: const EdgeInsets.all(4),
//       child: Row(
//         children: [
//           // User Role Button
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   selectedIndex = 0;
//                   isUser = true;
//                 });
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: isUser ? const Color(0xFF0A235C) : Colors.transparent,
//                   borderRadius: BorderRadius.circular(26),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.person_outline,
//                       color: isUser ? Colors.white : const Color(0xFF64748B),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "User",
//                       style: TextStyle(
//                         color: isUser ? Colors.white : const Color(0xFF64748B),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Worker Role Button
//           Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   selectedIndex = 1;
//                   isUser = false;
//                 });
//               },
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: !isUser ? const Color(0xFF0A235C) : Colors.transparent,
//                   borderRadius: BorderRadius.circular(26),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.business_center_outlined,
//                       color: !isUser ? Colors.white : const Color(0xFF64748B),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Business / Worker",
//                       style: TextStyle(
//                         color: !isUser ? Colors.white : const Color(0xFF64748B),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildUserFields() {
//     return [
//       RegistrationInputField(
//         label: "FULL NAME",
//         hintText: "Enter your full name",
//         prefixIcon: Icons.person_outline,
//         controller: userNameController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your username';
//           }
//           if (value.length < 3) {
//             return 'Username must be at least 3 characters';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "EMAIL",
//         hintText: "Enter your email",
//         prefixIcon: Icons.mail_outline,
//         controller: userEmailController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your email';
//           }
//           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//             return 'Please enter a valid email';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "PHONE NUMBER",
//         hintText: "Enter your phone number",
//         prefixIcon: Icons.phone_outlined,
//         controller: userPhoneController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your phone number';
//           }
//           if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
//             return 'Please enter a valid phone number';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "PASSWORD",
//         hintText: "Create a password",
//         prefixIcon: Icons.lock_outline,
//         controller: userPasswordController,
//         isPassword: true,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your password';
//           }
//           if (value.length < 6) {
//             return 'Password must be at least 6 characters';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "CONFIRM PASSWORD",
//         hintText: "Confirm your password",
//         prefixIcon: Icons.verified_user_outlined,
//         controller: userConfirmPasswordController,
//         isPassword: true,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please confirm your password';
//           }
//           if (value != userPasswordController.text) {
//             return 'Passwords do not match';
//           }
//           return null;
//         },
//       ),
//     ];
//   }

//   List<Widget> _buildWorkerFields() {
//     return [
//       const Text(
//         "Service Category",
//         style: TextStyle(
//             fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
//       ),
//       const SizedBox(height: 8),
//       Custdropdown(
//         items: const ["Exterior", "Interior", "Vehicle", "Pet", "Home"],
//         onchanged: (value) {
//           setState(() {
//             selectedCategory = value;
//           });
//         },
//       ),
//       const SizedBox(height: 15),
//       RegistrationInputField(
//         label: "FULL NAME",
//         hintText: "Enter your full name",
//         prefixIcon: Icons.person_outline,
//         controller: workerNameController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your username';
//           }
//           if (value.length < 3) {
//             return 'Username must be at least 3 characters';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "EMAIL",
//         hintText: "Enter your email",
//         prefixIcon: Icons.mail_outline,
//         controller: workerEmailController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your email';
//           }
//           if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//             return 'Please enter a valid email';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "PHONE NUMBER",
//         hintText: "Enter your phone number",
//         prefixIcon: Icons.phone_outlined,
//         controller: workerPhoneController,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your phone number';
//           }
//           if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
//             return 'Please enter a valid phone number';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "PASSWORD",
//         hintText: "Create a password",
//         prefixIcon: Icons.lock_outline,
//         controller: workerPasswordController,
//         isPassword: true,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter your password';
//           }
//           if (value.length < 6) {
//             return 'Password must be at least 6 characters';
//           }
//           return null;
//         },
//       ),
//       RegistrationInputField(
//         label: "CONFIRM PASSWORD",
//         hintText: "Confirm your password",
//         prefixIcon: Icons.verified_user_outlined,
//         controller: workerConfirmPasswordController,
//         isPassword: true,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please confirm your password';
//           }
//           if (value != workerPasswordController.text) {
//             return 'Passwords do not match';
//           }
//           return null;
//         },
//       ),
//     ];
//   }

//   void _handleRegister() {
//     if (!_agreeToTerms) {
//       Get.snackbar(
//         "Agreement Required",
//         "Please read and agree to the Terms & Conditions and Privacy Policy to register.",
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }

//     if (formKey.currentState!.validate()) {
//       if (isUser) {
//         registerUser();
//       } else {
//         registerWorker();
//       }
//     }
//   }

//   void registerUser() async {
//     try {
//       final userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: userEmailController.text.trim(),
//         password: userPasswordController.text.trim(),
//       );
//       final uid = userCredential.user!.uid;

//       await FirebaseFirestore.instance.collection("users").doc(uid).set({
//         "username": userNameController.text.trim(),
//         "phone": userPhoneController.text.trim(),
//         "email": userEmailController.text.trim(),
//         "role": "user",
//         "profile_img": "",
//         "created_at": FieldValue.serverTimestamp(),
//         "updated_at": FieldValue.serverTimestamp(),
//         "status": "active",
//         "password": userPasswordController.text.trim(),
//         "loyalty_points": 0,
//       });

//       Get.snackbar("Success", "User registered successfully",
//           backgroundColor: Colors.green, colorText: Colors.white);
//       if (mounted) Navigator.pop(context);
//     } on FirebaseAuthException catch (e) {
//       _handleAuthError(e);
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong. Please try again.$e",
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   void registerAdmin() async {
//     try {
//       final userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: userEmailController.text.trim(),
//         password: userPasswordController.text.trim(),
//       );
//       final uid = userCredential.user!.uid;

//       await FirebaseFirestore.instance.collection("admin").doc(uid).set({
//         "username": userNameController.text.trim(),
//         "email": userEmailController.text.trim(),
//         "role": "admin",
//         "profile_img": "",
//         "created_at": FieldValue.serverTimestamp(),
//         "password": userPasswordController.text.trim(),
//       });

//       Get.snackbar("Success", "User registered successfully",
//           backgroundColor: Colors.green, colorText: Colors.white);
//       if (mounted) Navigator.pop(context);
//     } on FirebaseAuthException catch (e) {
//       _handleAuthError(e);
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong. Please try again.$e",
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   void registerWorker() async {
//     if (selectedCategory == null || selectedCategory!.isEmpty) {
//       Get.snackbar("Error", "Please select a service category",
//           backgroundColor: Colors.red, colorText: Colors.white);
//       return;
//     }

//     try {
//       final userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: workerEmailController.text.trim(),
//         password: workerPasswordController.text.trim(),
//       );
//       final uid = userCredential.user!.uid;

//       await FirebaseFirestore.instance.collection("workers").doc(uid).set({
//         "username": workerNameController.text.trim(),
//         "phone": workerPhoneController.text.trim(),
//         "email": workerEmailController.text.trim(),
//         "role": "worker",
//         "category": selectedCategory,
//         "profile_img": "",
//         "created_at": FieldValue.serverTimestamp(),
//         "updated_at": FieldValue.serverTimestamp(),
//         "status": "pending",
//         "services": [],
//         "ratings": 0,
//         "total_reviews": 0,
//         "isVerified": 0,
//         "password": workerPasswordController.text.trim(),
//       });

//       Get.snackbar(
//           "Success", "Worker registered successfully. Awaiting admin approval.",
//           backgroundColor: Colors.green, colorText: Colors.white);
//       if (mounted) Navigator.pop(context);
//     } on FirebaseAuthException catch (e) {
//       _handleAuthError(e);
//     } catch (e) {
//       Get.snackbar("Error", "Something went wrong. Please try again.",
//           backgroundColor: Colors.red, colorText: Colors.white);
//     }
//   }

//   void _handleAuthError(FirebaseAuthException e) {
//     String errorMessage = switch (e.code) {
//       'weak-password' => 'The password provided is too weak.',
//       'email-already-in-use' => 'An account already exists for that email.',
//       'invalid-email' => 'Please enter a valid email address.',
//       _ => e.message ?? "An unknown error occurred",
//     };
//     Get.snackbar("Error", errorMessage,
//         backgroundColor: Colors.red, colorText: Colors.white);
//   }
// }

// class RegistrationInputField extends StatefulWidget {
//   final String label;
//   final String hintText;
//   final IconData prefixIcon;
//   final TextEditingController controller;
//   final bool isPassword;
//   final FormFieldValidator<String>? validator;

//   const RegistrationInputField({
//     super.key,
//     required this.label,
//     required this.hintText,
//     required this.prefixIcon,
//     required this.controller,
//     this.isPassword = false,
//     this.validator,
//   });

//   @override
//   State<RegistrationInputField> createState() => _RegistrationInputFieldState();
// }

// class _RegistrationInputFieldState extends State<RegistrationInputField> {
//   bool _obscureText = true;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Icon in a soft rounded-square background, matching the design
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF1F5F9),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(widget.prefixIcon,
//                 color: const Color(0xFF64748B), size: 20),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   widget.label,
//                   style: const TextStyle(
//                     color: Color(0xFF0A235C),
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 TextFormField(
//                   controller: widget.controller,
//                   obscureText: widget.isPassword ? _obscureText : false,
//                   validator: widget.validator,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     color: Colors.black,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   decoration: InputDecoration(
//                     isDense: true,
//                     contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
//                     hintText: widget.hintText,
//                     hintStyle:
//                         const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
//                     border: InputBorder.none,
//                     enabledBorder: InputBorder.none,
//                     focusedBorder: InputBorder.none,
//                     errorBorder: InputBorder.none,
//                     focusedErrorBorder: InputBorder.none,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (widget.isPassword)
//             IconButton(
//               icon: Icon(
//                 _obscureText
//                     ? Icons.visibility_outlined
//                     : Icons.visibility_off_outlined,
//                 color: const Color(0xFF94A3B8),
//                 size: 20,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _obscureText = !_obscureText;
//                 });
//               },
//             ),
//         ],
//       ),
//     );
//   }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/button/dropdown/custdropdown.dart';
import 'package:naattulink/MVVM/View/Authentication/healthcare_worker_registration.dart';
import 'package:naattulink/MVVM/View/Authentication/business_worker_registration.dart';
import 'package:naattulink/MVVM/View/Authentication/transport_worker_registration.dart';

class Registrationpage extends StatefulWidget {
  const Registrationpage({super.key});

  @override
  State<Registrationpage> createState() => _RegistrationpageState();
}

class _RegistrationpageState extends State<Registrationpage> {
  int selectedIndex = 0;
  bool isUser = true;
  bool _agreeToTerms = false;

  // Controllers for user fields
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userPhoneController = TextEditingController();
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController userPasswordController = TextEditingController();
  final TextEditingController userConfirmPasswordController =
      TextEditingController();

  // Controllers for worker fields
  final TextEditingController workerNameController = TextEditingController();
  final TextEditingController workerPhoneController = TextEditingController();
  final TextEditingController workerEmailController = TextEditingController();
  final TextEditingController workerLocationController =
      TextEditingController();
  final TextEditingController workerExperienceController =
      TextEditingController();
  final TextEditingController workerAboutController = TextEditingController();
  final TextEditingController workerPasswordController =
      TextEditingController();
  final TextEditingController workerConfirmPasswordController =
      TextEditingController();

  String? selectedCategory = "";
  final formKey = GlobalKey<FormState>();

  String? _selectedUserDistrict;
  String? _selectedWorkerDistrict;

  Widget _buildDistrictDropdown(bool isForUser) {
    final List<String> districts = [
      "Kozhikode",
      "Kannur",
      "Malappuram",
      "Wayanad",
      "Palakkad",
      "Thrissur",
      "Ernakulam",
      "Kottayam",
      "Alappuzha",
      "Pathanamthitta",
      "Kollam",
      "Thiruvananthapuram",
      "Idukki",
      "Kasaragod"
    ];

    String? currentVal =
        isForUser ? _selectedUserDistrict : _selectedWorkerDistrict;
    if (currentVal != null && !districts.contains(currentVal)) {
      districts.add(currentVal);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "DISTRICT",
                  style: TextStyle(
                    color: Color(0xFF0A235C),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              value: currentVal,
              hint: const Text('Select your district',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF94A3B8)),
              decoration: const InputDecoration(
                prefixIcon:
                    Icon(Icons.location_on, color: Color(0xFF94A3B8), size: 22),
                border: InputBorder.none,
              ),
              items: districts.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  if (isForUser) {
                    _selectedUserDistrict = newValue;
                  } else {
                    _selectedWorkerDistrict = newValue;
                  }
                });
              },
              validator: (v) => v == null ? 'Please select a district' : null,
            ),
          ),
        ],
      ),
    );
  }

  // New variables for multi-step worker registration
  int workerStep = 1;
  String? selectedWorkerCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image (Static, covers full screen)

          // Scrollable Content
          SafeArea(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(top: 26.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Circular Logo
                          Column(
                            children: [
                              const Center(
                                child: Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: Color(0xFF0A235C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text(
                                  "Join us and enjoy the best bakery experience",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),
                          // const SizedBox(height: 15),

                          // Role Toggle
                          _buildRoleToggle(),
                          const SizedBox(height: 25),

                          // Form Fields
                          ...(isUser
                              ? _buildUserFields()
                              : _buildWorkerFields()),
                          const SizedBox(height: 15),

                          // Terms & Conditions Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                activeColor: const Color(0xFF0A235C),
                                onChanged: (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: "I agree to the ",
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13),
                                    children: const [
                                      TextSpan(
                                        text: "Terms & Conditions",
                                        style: TextStyle(
                                          color: Color(0xFF0A235C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: " and "),
                                      TextSpan(
                                        text: "Privacy Policy",
                                        style: TextStyle(
                                          color: Color(0xFF0A235C),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // Register Button
                          SizedBox(
                            height: 55,
                            width: double.infinity,
                            child: Obx(() => Custombutton(
                                  color: const Color(0xFF0A235C),
                                  borderRadius: 15,
                                  text: AuthController.to.isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : (isUser || workerStep < 3)
                                          ? Text(
                                              isUser ? "Register" : "Continue",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Complete Registration ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Icon(Icons.done_all,
                                                    color: Colors.white,
                                                    size: 20),
                                              ],
                                            ),
                                  onpress: _handleRegister,
                                )),
                          ),
                          const SizedBox(height: 25),

                          // Already have an account? Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.back();
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Color(0xFF0A235C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating Back Button
          // SafeArea(
          //   child: Padding(
          //     padding: const EdgeInsets.only(left: 16.0, top: 20.0),
          //     child: Container(
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: IconButton(
          //         icon: const Icon(Icons.arrow_back_ios,
          //             color: Color(0xFF0A235C), size: 28),
          //         onPressed: () {
          //           Get.back();
          //         },
          //       ),
          //     ),
          //   ),
          // ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 20.0),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF0A235C),
                  size: 20,
                ),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          // User Role Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 0;
                  isUser = true;
                });
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF0A235C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: isUser ? Colors.white : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "User",
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Worker Role Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = 1;
                  isUser = false;
                });
              },
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: !isUser ? const Color(0xFF0A235C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      color: !isUser ? Colors.white : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Business / Worker",
                      style: TextStyle(
                        color: !isUser ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  List<Widget> _buildUserFields() {
    return [
      RegistrationInputField(
        label: "FULL NAME",
        hintText: "Enter your full name",
        prefixIcon: Icons.person_outline,
        controller: userNameController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your username';
          }
          if (value.length < 3) {
            return 'Username must be at least 3 characters';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "EMAIL",
        hintText: "Enter your email",
        prefixIcon: Icons.mail_outline,
        controller: userEmailController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "PHONE NUMBER",
        hintText: "Enter your phone number",
        prefixIcon: Icons.phone_outlined,
        controller: userPhoneController,
        keyboardType: TextInputType.phone,
        prefixText: '+91 ',
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
            return 'Please enter a valid 10-digit Indian mobile number';
          }
          return null;
        },
      ),
      _buildDistrictDropdown(true),
      RegistrationInputField(
        label: "PASSWORD",
        hintText: "Create a password",
        prefixIcon: Icons.lock_outline,
        controller: userPasswordController,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "CONFIRM PASSWORD",
        hintText: "Confirm your password",
        prefixIcon: Icons.verified_user_outlined,
        controller: userConfirmPasswordController,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != userPasswordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildWorkerFields() {
    if (workerStep == 1) {
      return _buildWorkerStep1();
    } else if (workerStep == 2) {
      return _buildWorkerStep2();
    } else {
      return _buildWorkerStep3();
    }
  }

  List<Widget> _buildWorkerStep1() {
    return [
      _buildProgressIndicator(),
      const SizedBox(height: 25),
      const Text(
        "SELECT CATEGORY",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A235C),
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 15),
      _buildCategoryCard(
        title: "Workers",
        subtitle: "Plumber, Electrician, Carpenter and more",
        icon: Icons.people_outline,
      ),
      _buildCategoryCard(
        title: "Transport (Travels)",
        subtitle: "Taxi, Bus, Auto Drivers and more",
        icon: Icons.directions_car_outlined,
      ),
      _buildCategoryCard(
        title: "Healthcare",
        subtitle: "Hospitals, Clinics, Pharmacy and more",
        icon: Icons.health_and_safety_outlined,
      ),
      _buildCategoryCard(
        title: "Shops & Businesses",
        subtitle: "Food, Grocery, Travels and more",
        icon: Icons.storefront_outlined,
      ),
      const SizedBox(height: 20),
      _buildWhyJoinBlock(),
      const SizedBox(height: 15),
    ];
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem(1, "CATEGORY", workerStep >= 1),
        _buildStepLine(workerStep >= 2),
        _buildStepItem(2, "DETAILS", workerStep >= 2),
        _buildStepLine(workerStep >= 3),
        _buildStepItem(3, "VERIFY", workerStep >= 3),
      ],
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF0A235C) : Colors.white,
            border: Border.all(
              color: isActive ? const Color(0xFF0A235C) : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0A235C) : Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: isActive ? const Color(0xFF0A235C) : Colors.grey[300],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedWorkerCategory == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedWorkerCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A235C) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF0A235C),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyJoinBlock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF021133), // Dark navy
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Why join NaattuLink?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          _buildWhyJoinItem(
            "Trusted Platform",
            "Verified users and businesses",
          ),
          const SizedBox(height: 16),
          _buildWhyJoinItem(
            "Grow Your Presence",
            "Reach more local customers",
          ),
          const SizedBox(height: 16),
          _buildWhyJoinItem(
            "Easy & Secure",
            "Manage your profile and bookings easily",
          ),
        ],
      ),
    );
  }

  Widget _buildWhyJoinItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFF10B981),
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWorkerStep2() {
    return [
      _buildProgressIndicator(),
      const SizedBox(height: 25),

      // Profile Photo Upload
      Center(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A235C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Upload profile photo",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),

      RegistrationInputField(
        label: "Full Name",
        hintText: "Enter your name",
        prefixIcon: Icons.person_outline,
        controller: workerNameController,
        isRequired: true,
      ),
      RegistrationInputField(
        label: "Mobile Number",
        hintText: "Enter your mobile number",
        prefixIcon: Icons.phone_outlined,
        controller: workerPhoneController,
        keyboardType: TextInputType.phone,
        isRequired: true,
        prefixText: '+91 ',
        maxLength: 10,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
            return 'Please enter a valid 10-digit Indian mobile number';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "Email",
        hintText: "Enter your email",
        prefixIcon: Icons.mail_outline,
        controller: workerEmailController,
        keyboardType: TextInputType.emailAddress,
        isRequired: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
      _buildDistrictDropdown(false),
      RegistrationInputField(
        label: "Location/Area",
        hintText: "Enter the area or landmark",
        prefixIcon: Icons.location_on_outlined,
        controller: workerLocationController,
        suffixIcon: const Icon(Icons.my_location, color: Color(0xFF0A235C)),
        isRequired: true,
      ),

      const SizedBox(height: 5),
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: "Select Profession",
              style: TextStyle(
                color: Color(0xFF0A235C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: " *",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          List<String> categoryItems = [];
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              String categoryName = doc.id;
              if (data != null) {
                if (data.containsKey('title')) {
                  categoryName = data['title'].toString();
                } else if (data.containsKey('category')) {
                  categoryName = data['category'].toString();
                } else if (data.containsKey('name')) {
                  categoryName = data['name'].toString();
                }
              }
              categoryItems.add(categoryName);
            }
          }
          if (categoryItems.isEmpty) {
            categoryItems = ["Loading..."];
          }
          return Custdropdown(
            items: categoryItems,
            onchanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          );
        },
      ),
      const SizedBox(height: 15),

      RegistrationInputField(
        label: "Years of Experience",
        hintText: "e.g. 5",
        prefixIcon: Icons.work_outline,
        controller: workerExperienceController,
        keyboardType: TextInputType.number,
        isRequired: true,
      ),
      RegistrationInputField(
        label: "About Me / Skills",
        hintText: "Tell us about your expertise...",
        prefixIcon: Icons.description_outlined,
        controller: workerAboutController,
        maxLines: 3,
      ),

      const SizedBox(height: 10),
      const Text(
        "ID Proof / Certificate",
        style: TextStyle(
          color: Color(0xFF0A235C),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tap to upload",
              style: TextStyle(
                color: Color(0xFF0A235C),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "JPG, PNG or PDF (Max 5MB)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
    ];
  }

  List<Widget> _buildWorkerStep3() {
    return [
      _buildProgressIndicator(),
      const SizedBox(height: 25),
      const Center(
        child: Text(
          "Verify Email Address",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A235C),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: Text(
          workerEmailController.text.isNotEmpty
              ? workerEmailController.text
              : "email@example.com",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
      const SizedBox(height: 30),
      RegistrationInputField(
        label: "Password",
        hintText: "Create a strong password",
        prefixIcon: Icons.lock_outline,
        controller: workerPasswordController,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "Confirm Password",
        hintText: "Re-enter password",
        prefixIcon: Icons.lock_outline,
        controller: workerConfirmPasswordController,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != workerPasswordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
      const SizedBox(height: 40),
      const Center(
        child: Icon(
          Icons.shield_outlined,
          color: Color(0xFFE2E8F0),
          size: 80,
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Future<void> _handleRegister() async {
    if (!isUser && workerStep == 1) {
      if (selectedWorkerCategory == null) {
        Get.snackbar(
          "Category Required",
          "Please select a category to continue.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      if (!_agreeToTerms) {
        Get.snackbar(
          "Agreement Required",
          "Please read and agree to the Terms & Conditions and Privacy Policy to continue.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      setState(() {
        if (selectedWorkerCategory == 'Transport (Travels)') {
          // Navigate to dedicated transport registration page
          Get.to(() => const TransportWorkerRegistrationPage());
          return;
        }
        if (selectedWorkerCategory == 'Healthcare') {
          // Navigate to dedicated healthcare registration page
          Get.to(() => const HealthcareWorkerRegistrationPage());
          return;
        }
        if (selectedWorkerCategory == 'Shops & Businesses') {
          // Navigate to dedicated business registration page
          Get.to(() => const BusinessWorkerRegistrationPage());
          return;
        }
        workerStep = 2;
        selectedCategory = selectedWorkerCategory;
      });
      return;
    }

    if (!isUser && workerStep == 2) {
      if (formKey.currentState!.validate()) {
        setState(() {
          workerStep = 3;
        });
      }
      return;
    }

    if (!_agreeToTerms) {
      Get.snackbar(
        "Agreement Required",
        "Please read and agree to the Terms & Conditions and Privacy Policy to register.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (formKey.currentState!.validate()) {
      double? lat;
      double? lng;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (e) {
        debugPrint("Location fetch failed: $e");
      }

      if (isUser) {
        AuthController.to.registerUser(
          context,
          username: userNameController.text.trim(),
          phone: '+91${userPhoneController.text.trim()}',
          email: userEmailController.text.trim(),
          password: userPasswordController.text.trim(),
          district: _selectedUserDistrict,
          latitude: lat,
          longitude: lng,
        );
      } else {
        AuthController.to.registerWorker(
          context,
          username: workerNameController.text.trim(),
          phone: '+91${workerPhoneController.text.trim()}',
          email: workerEmailController.text.trim(),
          password: workerPasswordController.text.trim(),
          category: selectedCategory ?? "",
          location: workerLocationController.text.trim(),
          experience: workerExperienceController.text.trim(),
          about: workerAboutController.text.trim(),
          district: _selectedWorkerDistrict,
          latitude: lat,
          longitude: lng,
        );
      }
    }
  }
}

class RegistrationInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool isPassword;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isRequired;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const RegistrationInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.isRequired = false,
    this.prefixText,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<RegistrationInputField> createState() => _RegistrationInputFieldState();
}

class _RegistrationInputFieldState extends State<RegistrationInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: Icon(widget.prefixIcon,
                color: const Color(0xFF94A3B8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.label,
                        style: const TextStyle(
                          color: Color(0xFF0A235C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: widget.controller,
                  obscureText: widget.isPassword ? _obscureText : false,
                  validator: widget.validator,
                  maxLines: widget.isPassword ? 1 : widget.maxLines,
                  keyboardType: widget.keyboardType,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: "",
                    prefixText: widget.prefixText,
                    contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
                    hintText: widget.hintText,
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isPassword)
            IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
          else if (widget.suffixIcon != null)
            widget.suffixIcon!,
        ],
      ),
    );
  }
}

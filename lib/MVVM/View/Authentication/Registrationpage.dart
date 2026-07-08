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
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/button/dropdown/custdropdown.dart';

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
  final TextEditingController workerPasswordController =
      TextEditingController();
  final TextEditingController workerConfirmPasswordController =
      TextEditingController();

  String? selectedCategory = "";
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image (Static, covers full screen)
          Positioned.fill(
            child: Image.asset(
              isUser
                  ? "assets/bg/user_registration_bg.png"
                  : "assets/bg/worker_registration_bg.png",
              fit: BoxFit.cover,
            ),
          ),
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
                              Center(
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: 0.75,
                                    child: Image.asset(
                                      "assets/logo/logo without name.png",
                                      height: 220,
                                    ),
                                  ),
                                ),
                              ),
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
                                  "Join us and enjoy the best experience",
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
                                      : const Text(
                                          "Register",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
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
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Get.back();
                    },
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF0A235C),
                        size: 20,
                      ),
                    ),
                  ),
                ),
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Business / Worker",
                      style: TextStyle(
                        color: !isUser ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      ),
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
    return [
      const Text(
        "Service Category",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      const SizedBox(height: 8),
      Custdropdown(
        items: const ["Exterior", "Interior", "Vehicle", "Pet", "Home"],
        onchanged: (value) {
          setState(() {
            selectedCategory = value;
          });
        },
      ),
      const SizedBox(height: 15),
      RegistrationInputField(
        label: "FULL NAME",
        hintText: "Enter your full name",
        prefixIcon: Icons.person_outline,
        controller: workerNameController,
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
        controller: workerEmailController,
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
        controller: workerPhoneController,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      ),
      RegistrationInputField(
        label: "PASSWORD",
        hintText: "Create a password",
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
        label: "CONFIRM PASSWORD",
        hintText: "Confirm your password",
        prefixIcon: Icons.verified_user_outlined,
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
    ];
  }

  void _handleRegister() {
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
      if (isUser) {
        AuthController.to.registerUser(
          context,
          username: userNameController.text.trim(),
          phone: userPhoneController.text.trim(),
          email: userEmailController.text.trim(),
          password: userPasswordController.text.trim(),
        );
      } else {
        AuthController.to.registerWorker(
          context,
          username: workerNameController.text.trim(),
          phone: workerPhoneController.text.trim(),
          email: workerEmailController.text.trim(),
          password: workerPasswordController.text.trim(),
          category: selectedCategory ?? "",
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

  const RegistrationInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.validator,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon in a soft rounded-square background, matching the design
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.prefixIcon,
                color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFF0A235C),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextFormField(
                  controller: widget.controller,
                  obscureText: widget.isPassword ? _obscureText : false,
                  validator: widget.validator,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
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
            ),
        ],
      ),
    );
  }
}

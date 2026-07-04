import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:swiftclean_project/MVVM/model/models/user_model.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/Config/Toast.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Sign in with Email and Password
  Future<UserCredential?> signIn(
      BuildContext context, String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = "Incorrect email or password. Please try again.";
        if (e.code == 'invalid-email') {
          message = "Please enter a valid email address.";
        } else if (e.code == 'user-disabled') {
          message = "This account has been disabled. Please contact support.";
        } else if (e.code == 'too-many-requests') {
          message = "Too many login attempts. Please try again later.";
        } else if (e.code == 'network-request-failed') {
          message = "Network error. Please check your internet connection.";
        } else if (e.message != null &&
            e.message!.contains("supplied auth credential is incorrect")) {
          message = "Incorrect email or password. Please try again.";
        }

        toastError(message);
      }
    } catch (e, stackTrace) {
      debugPrint("Generic Sign-In Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      if (context.mounted) {
        toastError("An unexpected login error occurred. Please try again.");
      }
    }
    return null;
  }

  // Create User
  Future<User?> createUser(
      BuildContext context, String email, String password, String role) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = credential.user;

      if (user != null) {
        UserModel userData = UserModel(
          createAt: FieldValue.serverTimestamp(),
          email: user.email,
          role: role,
          phone: "",
          address: "",
          profileUrl: "",
          uid: user.uid,
          username: "",
        );

        await db.collection('users').doc(user.uid).set(userData.toMap());
      }

      if (context.mounted) {
        toastSuccess("Registration Successful");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = "Registration failed. Please try again.";
        if (e.code == 'email-already-in-use') {
          message = "This email is already registered. Please sign in instead.";
        } else if (e.code == 'weak-password') {
          message = "Password is too weak. Please use at least 6 characters.";
        } else if (e.code == 'invalid-email') {
          message = "Please enter a valid email address.";
        } else if (e.code == 'network-request-failed') {
          message = "Network error. Please check your internet connection.";
        }

        toastError(message);
      }
    } catch (e, stackTrace) {
      debugPrint("Generic Registration Error: $e");
      debugPrint("Stack Trace: $stackTrace");
      if (context.mounted) {
        toastError(
            "An unexpected registration error occurred. Please try again.");
      }
    }
    return null;
  }

  // Google Sign In
  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return 'Sign-in aborted by user';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return 'FirebaseAuthException: \${e.message}';
    } catch (e) {
      return 'Exception during sign-in: \$e';
    }
  }

  // Sign Out
  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      toastSuccess("Logout Successful!");
    }
  }

  // Add item to cart
  Future<void> addToCart({
    required BuildContext context,
    required String serviceId,
    required String serviceName,
    required double price,
    required double originalPrice,
    required String imageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      final cartData = {
        'userId': userId,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await db.collection('carts').add(cartData);

      if (context.mounted) {
        toastSuccess("Service added to cart");
      }
    } catch (e) {
      if (context.mounted) {
        toastError("Failed to add to cart: ${e.toString()}");
      }
    }
  }

  // Send 5-digit verification code for booking cancellation
  Future<void> sendCancellationCodeToEmail({
    required String email,
    required String bookingId,
    required BuildContext context,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final code = (Random().nextInt(90000) + 10000).toString(); // 5-digit code

      // Save the code to Firestore
      await db.collection('bookingCancelCodes').doc(user.uid).set({
        'code': code,
        'bookingId': bookingId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // EmailJS or your email service configuration
      const serviceId = 'your_emailjs_service_id';
      const templateId = 'your_template_id';
      const userId = 'your_emailjs_user_id';

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': email,
            'verification_code': code,
          }
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          toastSuccess("Verification code sent to email.");
        }
      } else {
        throw Exception("Failed to send email");
      }
    } catch (e) {
      if (context.mounted) {
        toastError("Error: $e");
      }
    }
  }

  // Verify code and cancel the booking
  Future<bool> verifyAndCancelBooking({
    required String inputCode,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await db.collection('bookingCancelCodes').doc(user.uid).get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null || data['code'] != inputCode) return false;

    final bookingId = data['bookingId'];
    if (bookingId == null) return false;

    // Delete the booking
    await db.collection('bookings').doc(bookingId).delete();

    // Optional: delete the code document
    await db.collection('bookingCancelCodes').doc(user.uid).delete();

    if (context.mounted) {
      toastSuccess("Booking canceled successfully.");
    }

    return true;
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:naattulink/MVVM/model/models/user_model.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';
import 'package:naattulink/MVVM/model/services/notification_service.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Sign in with Email and Password
  Future<UserCredential?> signIn(
      BuildContext context, String identifier, String password) async {
    try {
      String emailToLogin = identifier.trim();

      // Check if identifier is not an email (assumed to be a phone number)
      if (!emailToLogin.contains('@')) {
        String rawPhone = emailToLogin.replaceAll(' ', '');
        String phoneWithPrefix = rawPhone;
        if (!rawPhone.startsWith('+91')) {
          phoneWithPrefix = '+91$rawPhone';
        } else {
          rawPhone = rawPhone.replaceFirst('+91', '');
        }

        // Search for the user by phone number across all collections
        final collections = [
          'users',
          'workers',
          'transports',
          'healthcare',
          'shops_businesses'
        ];

        String? foundEmail;
        for (var collection in collections) {
          final querySnapshot = await db
              .collection(collection)
              .where('phone', whereIn: [rawPhone, phoneWithPrefix])
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            foundEmail = querySnapshot.docs.first.data()['email'];
            break;
          }
        }

        if (foundEmail == null || foundEmail.isEmpty) {
          if (context.mounted) {
            toastError("No account found with this phone number.");
          }
          return null;
        }

        emailToLogin = foundEmail;
      }

      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: emailToLogin, password: password);
      return credential;
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      if (context.mounted) {
        toastError(message);
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
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      if (context.mounted) {
        toastError(message);
      }
    }
    return null;
  }

  // Google Sign In
  Future<String> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.disconnect();
      } catch (_) {} // Ignored if not previously signed in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
    await NotificationService.instance.clearFcmTokenFromFirestore();
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
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      if (context.mounted) {
        toastError(message);
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
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      if (context.mounted) {
        toastError(message);
      }
    }
  }

  // Verify code and cancel the booking
  Future<bool> verifyAndCancelBooking({
    required String inputCode,
    required BuildContext context,
  }) async {
    try {
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
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      if (context.mounted) {
        toastError(message);
      }
      return false;
    }
  }
}

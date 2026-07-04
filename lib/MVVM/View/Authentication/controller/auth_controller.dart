import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:swiftclean_project/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_project/MVVM/utils/Config/Toast.dart';
import 'package:swiftclean_project/MVVM/View/Screen/Worker/Worker_Dashboard.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final _authServices = FirebaseAuthServices();
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> login(
      BuildContext context, String email, String password) async {
    _isLoading.value = true;
    try {
      final userCredential =
          await _authServices.signIn(context, email, password);
      if (userCredential != null) {
        toastSuccess("Login Successful!");
        final userId = userCredential.user?.uid;
        if (userId != null) {
          // Fetch user/worker role
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          final workerDoc = await FirebaseFirestore.instance
              .collection('workers')
              .doc(userId)
              .get();

          if (userDoc.exists && userDoc.data()?['role'] == 'user') {
            Get.offAll(() => const FindingLocationPage());
          } else if (workerDoc.exists &&
              workerDoc.data()?['role'] == 'worker') {
            final isVerified = workerDoc.data()?['isVerified'];
            if (isVerified == 1) {
              Get.offAll(() => const FindingLocationPage());
            } else if (isVerified == -1) {
              toastWarning(
                  'Your profile has been rejected by the admin due to an unsatisfactory reason.');
            } else if (isVerified == 0) {
              toastInfo(
                  'Your profile is currently under review by the admin. Please wait a moment.');
            } else {
              toastWarning(
                  'Unknown verification status. Please contact support.');
            }
          } else {
            toastError('Unable to determine user role.');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("AuthController Login Error: $e\n$stackTrace");
      toastError("Login Failed: ${e.toString()}");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    _isLoading.value = true;
    try {
      final message = await _authServices.signInWithGoogle();
      if (message == 'Success') {
        toastSuccess("Google Login Successful!");
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          // Check role or go to location page
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            Get.offAll(() => const FindingLocationPage());
          } else {
            // New Google User default to user role
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .set({
              "username": FirebaseAuth.instance.currentUser?.displayName ?? "",
              "phone": "",
              "email": FirebaseAuth.instance.currentUser?.email ?? "",
              "role": "user",
              "profile_img": FirebaseAuth.instance.currentUser?.photoURL ?? "",
              "created_at": FieldValue.serverTimestamp(),
              "updated_at": FieldValue.serverTimestamp(),
              "status": "active",
              "loyalty_points": 0,
            });
            Get.offAll(() => const FindingLocationPage());
          }
        }
      } else {
        toastError(message);
      }
    } catch (e, stackTrace) {
      debugPrint("AuthController Google Sign-In Error: $e\n$stackTrace");
      toastError("Google Sign-In Failed: ${e.toString()}");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> registerUser(
    BuildContext context, {
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading.value = true;
    try {
      final user =
          await _authServices.createUser(context, email, password, 'user');
      if (user != null) {
        // Update user profile with fields
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          "username": username,
          "phone": phone,
          "updated_at": FieldValue.serverTimestamp(),
          "status": "active",
          "password": password,
          "loyalty_points": 0,
        });
        toastSuccess("User registered successfully");
        Get.offAll(() => const FindingLocationPage());
      }
    } catch (e, stackTrace) {
      debugPrint("AuthController User Registration Error: $e\n$stackTrace");
      toastError("Something went wrong. Please try again.");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> registerWorker(
    BuildContext context, {
    required String username,
    required String phone,
    required String email,
    required String password,
    required String category,
  }) async {
    _isLoading.value = true;
    try {
      final user =
          await _authServices.createUser(context, email, password, 'worker');
      if (user != null) {
        // Update worker details in workers collection
        await FirebaseFirestore.instance
            .collection("workers")
            .doc(user.uid)
            .set({
          "username": username,
          "phone": phone,
          "email": email,
          "role": "worker",
          "category": category,
          "profile_img": "",
          "created_at": FieldValue.serverTimestamp(),
          "updated_at": FieldValue.serverTimestamp(),
          "status": "pending",
          "services": [],
          "ratings": 0,
          "total_reviews": 0,
          "isVerified": 0,
          "password": password,
        });

        // Also remove from users table if createUser automatically added it (FirebaseAuthServices.createUser adds it to 'users')
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();

        toastSuccess(
            "Worker registered successfully. Awaiting admin approval.");
        Get.offAll(() => const WorkerDashboard());
      }
    } catch (e, stackTrace) {
      debugPrint("AuthController Worker Registration Error: $e\n$stackTrace");
      toastError("Something went wrong. Please try again.");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    await _authServices.signOut(context);
  }
}

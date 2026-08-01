import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:naattulink/MVVM/View/Authentication/worker_verification_waiting_screen.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Worker_Dashboard/Worker_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_main_page.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';

import 'package:get_storage/get_storage.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final _authServices = FirebaseAuthServices();
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  Future<void> routeAuthenticatedUser(User firebaseUser) async {
    final userId = firebaseUser.uid;

    // Step 1: Check users collection
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()?['role'] == 'user') {
      Get.offAll(() => const FindingLocationPage());
      return;
    }

    // Step 2: Search worker collections
    final collections = [
      'workers',
      'transports',
      'healthcare',
      'shops_businesses'
    ];
    DocumentSnapshot? foundDoc;
    String? foundCollection;

    for (var collection in collections) {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      if (doc.exists) {
        foundDoc = doc;
        foundCollection = collection;
        break;
      }
    }

    if (foundDoc != null) {
      // Check verification status
      final dataMap = foundDoc.data() as Map<String, dynamic>?;

      final requiresVerification =
          foundCollection == 'workers' && dataMap?['role'] == 'worker';

      if (requiresVerification) {
        final isVerified = dataMap?['isVerified'];
        if (isVerified == 0) {
          toastInfo(
              'Your profile is currently under review by the admin. Please wait a moment.');
          Get.offAll(() => const WorkerVerificationWaitingScreen());
          return;
        } else if (isVerified == -1) {
          toastWarning(
              'Your profile has been rejected by the admin due to an unsatisfactory reason.');
          return;
        } else if (isVerified != 1) {
          toastWarning('Unknown verification status. Please contact support.');
          return;
        }
      }

      final data = foundDoc.data() as Map<String, dynamic>? ?? {};

      // Route based on collection
      if (foundCollection == 'workers') {
        final category = data['category'] ?? '';
        final excludedCategories = [
          "Transport (Travels)",
          "Healthcare",
          "Shops & Businesses"
        ];
        if (!excludedCategories.contains(category)) {
          // General Worker Dashboard
          Get.offAll(() => const FindingLocationPage());
        } else {
          // Fallback if category was one of excluded but stored in 'workers' by mistake
          Get.offAll(() => const FindingLocationPage());
        }
      } else if (foundCollection == 'transports') {
        final transportCategory = data['transport_category'] ?? '';
        if (transportCategory == 'Bus') {
          // Bus Dashboard
          final busController = Get.put(BusDashboardController());
          await busController.initialize();
          Get.offAll(() => const BusWorkerMainPage());
        } else if (transportCategory == 'Truck / JCB') {
          // Truck/JCB Dashboard placeholder
          Get.offAll(() => const FindingLocationPage());
        } else if (transportCategory == 'Taxi') {
          // Taxi Dashboard placeholder
          Get.offAll(() => const FindingLocationPage());
        } else {
          Get.offAll(() => const FindingLocationPage());
        }
      } else if (foundCollection == 'healthcare') {
        // Healthcare Dashboard placeholder
        Get.offAll(() => const FindingLocationPage());
      } else if (foundCollection == 'shops_businesses') {
        // Shops & Businesses Dashboard placeholder
        Get.offAll(() => const FindingLocationPage());
      }
    } else {
      toastError('Unable to determine user role or collection.');
      await logout(Get.context!);
    }
  }

  Future<void> login(
      BuildContext context, String email, String password) async {
    _isLoading.value = true;
    try {
      final userCredential =
          await _authServices.signIn(context, email, password);
      if (userCredential != null && userCredential.user != null) {
        toastSuccess("Login Successful!");
        await routeAuthenticatedUser(userCredential.user!);
      }
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      toastError(message);
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
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          bool foundAnywhere = userDoc.exists;
          if (!foundAnywhere) {
            final collections = [
              'workers',
              'transports',
              'healthcare',
              'shops_businesses'
            ];
            for (var collection in collections) {
              final doc = await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(user.uid)
                  .get();
              if (doc.exists) {
                foundAnywhere = true;
                break;
              }
            }
          }

          if (!foundAnywhere) {
            // New Google User default to user role
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              "username": user.displayName ?? "",
              "phone": "",
              "email": user.email ?? "",
              "role": "user",
              "profile_img": user.photoURL ?? "",
              "created_at": FieldValue.serverTimestamp(),
              "updated_at": FieldValue.serverTimestamp(),
              "status": "active",
              "loyalty_points": 0,
            });
          }
          await routeAuthenticatedUser(user);
        }
      } else {
        toastError(message);
      }
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      toastError(message);
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
    String? district,
    double? latitude,
    double? longitude,
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
          if (district != null) "district": district,
          if (latitude != null) "latitude": latitude,
          if (longitude != null) "longitude": longitude,
        });
        toastSuccess("User registered successfully");
        Get.offAll(() => const FindingLocationPage());
      }
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      toastError(message);
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
    required String location,
    required String experience,
    required String about,
    String? district,
    double? latitude,
    double? longitude,
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
          // Key fields at top
          "created_at": FieldValue.serverTimestamp(),
          "location": location,
          "experience": experience,
          "about": about,
          if (district != null) "district": district,
          if (latitude != null) "latitude": latitude,
          if (longitude != null) "longitude": longitude,
          // Core fields
          "username": username,
          "phone": phone,
          "email": email,
          "role": "worker",
          "category": category,
          "profile_img": "",
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
        Get.offAll(() => const WorkerVerificationWaitingScreen());
      }
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      toastError(message);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      // 1. Sign out from Firebase
      await _authServices.signOut(context);

      // 2. Clear all local storage
      final getStorage = GetStorage();
      await getStorage.erase();

      // Clear controller states if needed

      // 3. Remove navigation stack and route to login
      Get.offAll(() => const LoginAndSigning());
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint(message);
      toastError(message);
    }
  }
}

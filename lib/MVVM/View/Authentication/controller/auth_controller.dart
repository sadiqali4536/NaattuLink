import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/current_loaction_fetch.dart';
import 'package:naattulink/MVVM/View/Authentication/worker_verification_waiting_screen.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Worker_Dashboard/Worker_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/healthcare_worker_dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';

import 'package:get_storage/get_storage.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/model/services/notification_service.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';
import 'package:naattulink/MVVM/View/Authentication/Registrationpage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final _authServices = FirebaseAuthServices();
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Future<void> routeAuthenticatedUser(User firebaseUser) async {
    final userId = firebaseUser.uid;
    debugPrint("=== ROUTING USER ===");
    debugPrint("Firebase UID: $userId");
    debugPrint("Email: ${firebaseUser.email}");
    debugPrint("Phone: ${firebaseUser.phoneNumber}");

    NotificationService.instance.syncCurrentToken();

    Future<DocumentSnapshot?> findInCollection(String collection) async {
      // 1. By UID
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      if (doc.exists) {
        debugPrint("Found in $collection by UID");
        return doc;
      }

      // 2. By Email
      if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        final emailQuery = await FirebaseFirestore.instance
            .collection(collection)
            .where('email', isEqualTo: firebaseUser.email!.trim().toLowerCase())
            .limit(1)
            .get();
        if (emailQuery.docs.isNotEmpty) {
          debugPrint("Found in $collection by Email");
          return emailQuery.docs.first;
        }
      }

      // 3. By Phone
      if (firebaseUser.phoneNumber != null &&
          firebaseUser.phoneNumber!.isNotEmpty) {
        String phone = firebaseUser.phoneNumber!;
        String rawPhone = phone;
        String phoneWithPrefix = phone;
        if (!phone.startsWith('+91')) {
          phoneWithPrefix = '+91$phone';
        } else {
          rawPhone = phone.replaceFirst('+91', '');
        }
        final phoneQuery = await FirebaseFirestore.instance
            .collection(collection)
            .where('phone', whereIn: [rawPhone, phoneWithPrefix])
            .limit(1)
            .get();
        if (phoneQuery.docs.isNotEmpty) {
          debugPrint("Found in $collection by Phone");
          return phoneQuery.docs.first;
        }
      }
      return null;
    }

    final collections = [
      'workers',
      'transports',
      'healthcare',
      'shops_businesses',
      'businesses',
      'users'
    ];
    String? foundCollection;
    DocumentSnapshot? foundDoc;

    for (var collection in collections) {
      foundDoc = await findInCollection(collection);
      if (foundDoc != null) {
        foundCollection = collection;
        debugPrint("User/Worker found in collection: $foundCollection");
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
          Get.offAll(() => const BusWorkerDashboard());
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
        final profession = data['profession'] ?? '';
        debugPrint("ROUTING HEALTHCARE USER. Profession is: '\$profession'");
        if (profession == 'Pharmacy' || profession == 'Emergency Services') {
          Get.offAll(() => const user_Dashboard());
        } else {
          Get.offAll(() => const HealthcareWorkerDashboard());
        }
      } else if (foundCollection == 'shops_businesses' ||
          foundCollection == 'businesses') {
        final category = data['category'] ?? '';
        if (category == 'Online services') {
          Get.offAll(() => const user_Dashboard());
        } else {
          Get.offAll(() => const FindingLocationPage());
        }
      } else if (foundCollection == 'users') {
        Get.offAll(() => const FindingLocationPage());
      }
    } else {
      toastError('Unable to determine user role or collection.');
      await logout(Get.context!);
    }
  }

  Future<void> login(BuildContext context, String identifier, String password,
      bool isPhoneLogin) async {
    _isLoading.value = true;
    try {
      String loginId = identifier.trim().toLowerCase();
      bool isEmail = !isPhoneLogin;

      debugPrint("=== LOGIN STARTED ===");
      debugPrint("Current Login Mode: ${isPhoneLogin ? 'PHONE' : 'EMAIL'}");
      debugPrint("Entered Identifier: $loginId");
      debugPrint("Entered Password: [HIDDEN]");

      String authEmail = loginId;

      final collections = [
        'users',
        'workers',
        'transports',
        'healthcare',
        'shops_businesses',
        'businesses'
      ];

      bool userFound = false;
      Map<String, dynamic>? userData;

      if (isEmail) {
        debugPrint("\nEMAIL LOGIN:");
        debugPrint("Normalized email: $loginId");
        debugPrint("Checking all collections for email...");
        for (var col in collections) {
          final query = await FirebaseFirestore.instance
              .collection(col)
              .where('email', isEqualTo: loginId)
              .get();
          if (query.docs.isNotEmpty) {
            userFound = true;
            userData = query.docs.first.data() as Map<String, dynamic>;
            debugPrint("User found in collection: $col");
            break;
          }
        }
      } else {
        debugPrint("\nPHONE LOGIN:");
        debugPrint("Checking all collections for phone...");
        String phoneWithPrefix = loginId;
        String rawPhone = loginId;
        if (!loginId.startsWith('+91')) {
          phoneWithPrefix = '+91$loginId';
        } else {
          rawPhone = loginId.replaceFirst('+91', '');
        }

        for (var col in collections) {
          final query = await FirebaseFirestore.instance
              .collection(col)
              .where('phone', whereIn: [rawPhone, phoneWithPrefix]).get();
          if (query.docs.isNotEmpty) {
            userFound = true;
            userData = query.docs.first.data() as Map<String, dynamic>;
            debugPrint("User found in collection: $col");
            break;
          }
        }
      }

      debugPrint("User found: $userFound");

      if (userFound) {
        if (!isEmail) {
          authEmail = userData!['email'] ?? '';
          debugPrint("Registered email found: $authEmail");
          if (authEmail.isEmpty) {
            toastError("No email associated with this phone number.");
            return;
          }
        }
        debugPrint("Starting Firebase authentication...");
      } else {
        debugPrint("Final Navigation: REGISTRATION");
        toastError("User not found. Please register first.");
        Get.to(() => const Registrationpage());
        return; // Stop login process
      }

      // STEP 2: Authenticate with Firebase using Email & Password
      debugPrint("Authenticating with email: $authEmail");
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );

      if (userCredential.user != null) {
        toastSuccess("Login Successful!");
        await routeAuthenticatedUser(userCredential.user!);
      } else {
        debugPrint("Firebase Authentication Result: FAILED");
        debugPrint("Final Navigation: LOGIN ERROR");
        toastError("Failed to authenticate.");
      }
    } catch (e, stackTrace) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint("Firebase Authentication Result: FAILED");
      debugPrint("Error Details: $e");
      debugPrint("Final Navigation: LOGIN ERROR");
      toastError(message);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loginWithCustomToken(
      BuildContext context, String customToken) async {
    _isLoading.value = true;
    try {
      debugPrint("=== OTP LOGIN STARTED ===");
      final userCredential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        debugPrint("Firebase Custom Auth Result: SUCCESS");
        debugPrint("Firebase UID: ${user.uid}");
        toastSuccess("Login Successful!");
        await routeAuthenticatedUser(user);
      } else {
        toastError("Failed to authenticate.");
      }
    } catch (e) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint("Firebase Custom Auth Result: FAILED");
      debugPrint("Error Details: $e");
      toastError(message);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    debugPrint("=== GOOGLE LOGIN STARTED ===");
    _isLoading.value = true;
    try {
      final googleSignIn = GoogleSignIn();
      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("Google Sign-In aborted by user.");
        return;
      }

      final selectedEmail = googleUser.email.trim().toLowerCase();
      debugPrint("Selected Google Email: $selectedEmail");
      debugPrint("Normalized Email: $selectedEmail");
      debugPrint("Checking users collection...");

      final collections = [
        'users',
        'workers',
        'transports',
        'healthcare',
        'shops_businesses',
        'businesses'
      ];

      bool found = false;
      for (var col in collections) {
        final query = await FirebaseFirestore.instance
            .collection(col)
            .where('email', isEqualTo: selectedEmail)
            .get();
        if (query.docs.isNotEmpty) {
          if (col == 'businesses' || col == 'shops_businesses') {
            final data = query.docs.first.data();
            final category = data['category'] ?? '';
            if (category == 'Online services') {
              found = true;
              debugPrint("User found in collection: $col with Online services");
              break;
            } else {
              debugPrint(
                  "Found in $col but category is '$category', not 'Online services'. Skipping.");
              continue;
            }
          } else {
            found = true;
            debugPrint("User found in collection: $col");
            break;
          }
        }
      }

      if (found) {
        // Proceed with Firebase Auth
        debugPrint("Firebase Authentication Started...");
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        debugPrint("Firebase UID: \${userCredential.user?.uid}");
        debugPrint("Final Login Decision: SUCCESS");

        toastSuccess("Google Login Successful!");
        await routeAuthenticatedUser(userCredential.user!);
      } else {
        await googleSignIn.signOut();
        debugPrint("Final Login Decision: USER NOT FOUND");
        toastError("User not found. Please register first.");
        Get.to(() => const Registrationpage());
      }
    } catch (e, stackTrace) {
      final message = FirebaseErrorHandler.getReadableErrorMessage(e);
      debugPrint("!!! GOOGLE LOGIN EXCEPTION !!!");
      debugPrint("Error Details: \$e");
      debugPrint("Stack Trace: \$stackTrace");
      toastError(message);
    } finally {
      debugPrint("=== GOOGLE SIGN-IN PROCESS FINISHED (Login Page) ===");
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

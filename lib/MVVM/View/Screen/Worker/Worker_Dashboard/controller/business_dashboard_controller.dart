import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BusinessDashboardController extends GetxController {
  static BusinessDashboardController get to => Get.find<BusinessDashboardController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  RxBool isLoading = true.obs;
  StreamSubscription? _userSub;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  @override
  void onClose() {
    _userSub?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    try {
      isLoading(true);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      _userSub?.cancel();

      // Listen to Businesses user profile
      _userSub = _firestore
          .collection('businesses')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          userData.value = doc.data()!;
        }
      });
    } catch (e) {
      print("Error initializing BusinessDashboardController: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data, File? imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User is not authenticated.");
    }

    try {
      String? imageUrl;
      if (imageFile != null) {
        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$uid.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final updateData = {...data};
      if (imageUrl != null) {
        updateData['profile_img'] = imageUrl;
      }
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('businesses').doc(uid).update(updateData);
    } catch (e) {
      throw Exception("Failed to update profile: $e");
    }
  }
}

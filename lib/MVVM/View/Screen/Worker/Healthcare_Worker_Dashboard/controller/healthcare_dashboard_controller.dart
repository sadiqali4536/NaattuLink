import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'dart:io';

class HealthcareDashboardController extends GetxController {
  static HealthcareDashboardController get to =>
      Get.find<HealthcareDashboardController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  RxList<Map<String, dynamic>> doctors = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> consultations = <Map<String, dynamic>>[].obs;

  RxBool isLoading = true.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxBool isSearchFocused = false.obs;

  List<Map<String, dynamic>> get filteredConsultations {
    if (searchQuery.value.trim().isEmpty) {
      return consultations;
    }
    final query = searchQuery.value.trim().toLowerCase();
    return consultations.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      final mobile = (c['mobile'] ?? '').toString().toLowerCase();
      return title.contains(query) || mobile.contains(query);
    }).toList();
  }

  StreamSubscription? _userSub;
  StreamSubscription? _doctorsSub;
  StreamSubscription? _consultationsSub;

  @override
  void onInit() {
    super.onInit();
    initialize();
    searchFocusNode.addListener(() {
      isSearchFocused.value = searchFocusNode.hasFocus;
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    _userSub?.cancel();
    _doctorsSub?.cancel();
    _consultationsSub?.cancel();
    super.onClose();
  }

  Future<void> initialize() async {
    try {
      isLoading(true);
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      _userSub?.cancel();
      _doctorsSub?.cancel();
      _consultationsSub?.cancel();

      // Listen to Healthcare user profile
      _userSub = _firestore
          .collection('healthcare')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          userData.value = doc.data()!;
        }
      });

      // Listen to Doctors subcollection
      _doctorsSub = _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('doctors')
          .snapshots()
          .listen((snapshot) {
        doctors.assignAll(snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
      });

      // Listen to Consultations subcollection
      _consultationsSub = _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('consultations')
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        consultations.assignAll(snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
      });
    } catch (e) {
      print("Error initializing HealthcareDashboardController: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshData() async {
    await initialize();
  }

  Future<void> updateConsultationStatus(
      String consultationId, String newStatus) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('consultations')
          .doc(consultationId)
          .update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (Get.context != null) {
        if (newStatus == 'unscheduled') {
          CherryToast.warning(
            title: const Text("Notice",
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: Text("Consultation status updated to $newStatus."),
            animationDuration: const Duration(milliseconds: 500),
            toastDuration: const Duration(seconds: 3),
          ).show(Get.context!);
        } else {
          CherryToast.success(
            title: const Text("Success",
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: Text("Consultation status updated to $newStatus."),
            animationDuration: const Duration(milliseconds: 500),
            toastDuration: const Duration(seconds: 3),
          ).show(Get.context!);
        }
      }
    } catch (e) {
      if (Get.context != null) {
        CherryToast.error(
          title: const Text("Error",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text("Failed to update status: $e"),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    }
  }

  Future<void> deleteConsultation(String consultationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final docRef = _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('consultations')
          .doc(consultationId);

      final doctorsSnapshot = await _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('doctors')
          .where('consultationId', isEqualTo: consultationId)
          .get();

      if (doctorsSnapshot.docs.isNotEmpty) {
        // Use batches to delete doctors (Firestore limit is 500 ops per batch)
        final int batchSize = 400;
        for (int i = 0; i < doctorsSnapshot.docs.length; i += batchSize) {
          final batch = _firestore.batch();
          final end = (i + batchSize < doctorsSnapshot.docs.length)
              ? i + batchSize
              : doctorsSnapshot.docs.length;

          for (var j = i; j < end; j++) {
            batch.delete(doctorsSnapshot.docs[j].reference);
          }
          await batch.commit();
        }
      }

      // Delete the consultation document itself
      await docRef.delete();

      if (Get.context != null) {
        CherryToast.success(
          title: const Text("Success",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text("Consultation deleted successfully."),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    } catch (e) {
      if (Get.context != null) {
        CherryToast.error(
          title: const Text("Error",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text("Failed to delete consultation: $e"),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    }
  }

  Future<void> updateDoctorStatus(
      String consultationId, String doctorId, String newStatus) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('doctors')
          .doc(doctorId)
          .update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (Get.context != null) {
        if (newStatus == 'inactive') {
          CherryToast.warning(
            title: const Text("Notice",
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text("Doctor marked as Not Available."),
            animationDuration: const Duration(milliseconds: 500),
            toastDuration: const Duration(seconds: 3),
          ).show(Get.context!);
        } else {
          CherryToast.success(
            title: const Text("Success",
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text("Doctor marked as Available."),
            animationDuration: const Duration(milliseconds: 500),
            toastDuration: const Duration(seconds: 3),
          ).show(Get.context!);
        }
      }
    } catch (e) {
      if (Get.context != null) {
        CherryToast.error(
          title: const Text("Error",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text("Failed to update status: $e"),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    }
  }

  Future<void> deleteDoctor(String consultationId, String doctorId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('healthcare')
          .doc(uid)
          .collection('doctors')
          .doc(doctorId)
          .delete();

      if (Get.context != null) {
        CherryToast.success(
          title: const Text("Success",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text("Doctor deleted successfully."),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    } catch (e) {
      if (Get.context != null) {
        CherryToast.error(
          title: const Text("Error",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text("Failed to delete doctor: $e"),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(Get.context!);
      }
    }
  }

  Future<void> updateUserProfile(
      Map<String, dynamic> data, File? imageFile) async {
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
        updateData['profile_image'] = imageUrl;
      }
      updateData['updated_at'] = FieldValue.serverTimestamp();

      await _firestore.collection('healthcare').doc(uid).update(updateData);
    } catch (e) {
      throw Exception("Failed to update profile: $e");
    }
  }
}

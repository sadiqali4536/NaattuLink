import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BusDashboardController extends GetxController {
  static BusDashboardController get to => Get.find<BusDashboardController>();

  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  final RxList<QueryDocumentSnapshot> buses = <QueryDocumentSnapshot>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  RxInt busLimit = 10.obs;
  final ScrollController scrollController = ScrollController();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
  bool _isInitializing = false;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    // Start initialization if not already started (useful for hot reloads)
    initialize();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent * 0.9) {
        fetchMoreBuses();
      }
    });
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    if (uid == null) return;

    _isInitializing = true;
    try {
      isLoading.value = true;

      // Check network connectivity first
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          hasError.value = true;
          return;
        }
      } on SocketException catch (_) {
        hasError.value = true;
        return;
      }

      // Fetch initial data
      final userDoc = await FirebaseFirestore.instance
          .collection('transports')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        userData.value = userDoc.data() ?? {};
      }

      final busesQuery = await FirebaseFirestore.instance
          .collection('transports')
          .doc(uid)
          .collection('buses')
          .limit(busLimit.value)
          .get();
      buses.assignAll(busesQuery.docs);

      // Start real-time listeners after initial load
      _startListeners();
      hasError.value = false;
    } catch (e) {
      print("Error initializing BusDashboardController: $e");
      hasError.value = true;
    } finally {
      _isInitializing = false;
      _isInitialized = true;
      isLoading.value = false;
    }
  }

  void _startListeners() {
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('transports')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        userData.value = doc.data() ?? {};
      }
    });

    _listenToBuses();
  }

  void _listenToBuses() {
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('transports')
        .doc(uid)
        .collection('buses')
        .limit(busLimit.value)
        .snapshots()
        .listen((query) {
      buses.assignAll(query.docs);
    });
  }

  void fetchMoreBuses() {
    busLimit.value += 10;
    _listenToBuses();
  }

  Future<void> refreshData() async {
    _isInitialized = false;
    await initialize();
  }
}

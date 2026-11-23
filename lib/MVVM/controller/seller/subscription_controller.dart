import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/seller_subscription_details.dart';
import 'package:naattulink/MVVM/model/seller/subscription_history_model.dart';
import 'package:naattulink/MVVM/utils/subscription_date_utils.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Subscription/subscription_expired_dialog.dart';

export 'package:naattulink/MVVM/model/seller/seller_subscription_details.dart' show SubscriptionState, SellerSubscriptionDetails;

class SubscriptionController extends GetxController with WidgetsBindingObserver {
  static SubscriptionController get to {
    if (!Get.isRegistered<SubscriptionController>()) {
      return Get.put(SubscriptionController(), permanent: true);
    }
    return Get.find<SubscriptionController>();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<DocumentSnapshot>? _sellerSubscription;
  StreamSubscription<DocumentSnapshot>? _subscriptionDetailsSub;

  final Rx<SellerSubscriptionDetails?> subscriptionDetails =
      Rx<SellerSubscriptionDetails?>(null);
  final RxInt remainingDays = 0.obs;
  final Rx<SubscriptionState> state = SubscriptionState.notStarted.obs;
  final RxBool isLoading = false.obs;
  final RxList<SubscriptionHistoryModel> historyList =
      <SubscriptionHistoryModel>[].obs;

  DateTime? _lastCalculatedDate;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    initSubscriptionStream();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _sellerSubscription?.cancel();
    _subscriptionDetailsSub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate calculation when resuming from background
      recalculateRemaining();
    }
  }

  void initSubscriptionStream() {
    final user = _auth.currentUser;
    if (user == null) {
      resetState();
      return;
    }

    final uid = user.uid;
    _sellerSubscription?.cancel();
    _subscriptionDetailsSub?.cancel();

    // Listen to seller doc for realtime changes
    _sellerSubscription =
        _firestore.collection('sellers').doc(uid).snapshots().listen(
      (doc) {
        if (!doc.exists || doc.data() == null) {
          resetState();
          return;
        }
        _syncFromSellerDoc(doc.data()!, uid);
      },
      onError: (err) {
        debugPrint("[SubscriptionController] seller doc listen error: $err");
      },
    );

    // Listen to subscription/details doc
    _subscriptionDetailsSub = _firestore
        .collection('sellers')
        .doc(uid)
        .collection('subscription')
        .doc('details')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        _syncFromDetailsDoc(doc.data()!, uid);
      }
    });

    fetchHistory();
  }

  void _syncFromSellerDoc(Map<String, dynamic> data, String uid) {
    final current = subscriptionDetails.value;
    final planName = data['selectedPlanName'] ??
        current?.planName ??
        'Store Subscription';
    final planId = data['selectedPlanId'] ?? current?.planId;
    final durationDays = (data['planDurationDays'] ??
        data['subscriptionDuration'] ??
        current?.durationDays ??
        30) as int;

    DateTime? startDate;
    if (data['subscriptionStartDate'] is Timestamp) {
      startDate = (data['subscriptionStartDate'] as Timestamp).toDate();
    }
    DateTime? expiryDate;
    if (data['subscriptionEndDate'] is Timestamp) {
      expiryDate = (data['subscriptionEndDate'] as Timestamp).toDate();
    }

    final regStatus = data['registrationStatus']?.toString() ?? 'pending';
    final subStatus = data['subscriptionStatus']?.toString() ?? 'pending';
    final renewalStatus = data['renewalStatus']?.toString() ??
        (current?.renewalStatus ?? 'none');

    final updated = SellerSubscriptionDetails(
      sellerId: uid,
      planId: planId,
      planName: planName,
      durationDays: durationDays,
      startDate: startDate ?? current?.startDate,
      expiryDate: expiryDate ?? current?.expiryDate,
      lastRenewedAt: current?.lastRenewedAt,
      renewalStatus: renewalStatus,
      lastTransactionId: current?.lastTransactionId,
      lastPaymentMethod: current?.lastPaymentMethod,
      lastAmount: (data['planPrice'] ?? current?.lastAmount)?.toDouble(),
      createdAt: current?.createdAt,
      updatedAt: current?.updatedAt,
    );

    subscriptionDetails.value = updated;
    _evaluateState(
      regStatus: regStatus,
      rawSubStatus: subStatus,
      renewalStatus: renewalStatus,
      expiryDate: updated.expiryDate,
    );
  }

  void _syncFromDetailsDoc(Map<String, dynamic> data, String uid) {
    final current = subscriptionDetails.value;
    DateTime? expDate;
    if (data['expiryDate'] is Timestamp) {
      expDate = (data['expiryDate'] as Timestamp).toDate();
    }

    final updated = SellerSubscriptionDetails(
      sellerId: uid,
      planId: data['planId'] ?? current?.planId,
      planName: data['planName'] ?? current?.planName ?? 'Store Subscription',
      durationDays: (data['durationDays'] ?? current?.durationDays ?? 30) as int,
      startDate: current?.startDate,
      expiryDate: expDate ?? current?.expiryDate,
      lastRenewedAt: data['lastRenewedAt'] is Timestamp
          ? (data['lastRenewedAt'] as Timestamp).toDate()
          : current?.lastRenewedAt,
      renewalStatus: data['renewalStatus'] ?? current?.renewalStatus ?? 'none',
      lastTransactionId: data['transactionId'] ?? current?.lastTransactionId,
      lastPaymentMethod: data['paymentMethod'] ?? current?.lastPaymentMethod,
      lastAmount: (data['amount'] ?? current?.lastAmount)?.toDouble(),
    );

    subscriptionDetails.value = updated;
    recalculateRemaining();
  }

  void _evaluateState({
    required String regStatus,
    required String rawSubStatus,
    required String renewalStatus,
    required DateTime? expiryDate,
  }) {
    final now = DateTime.now();
    final days = SubscriptionDateUtils.calculateRemainingDays(expiryDate,
        currentTime: now);
    remainingDays.value = days;
    _lastCalculatedDate = now;

    if (regStatus == 'pending_verification' || rawSubStatus == 'pending') {
      state.value = SubscriptionState.renewalPending;
      return;
    }

    if (rawSubStatus == 'cancelled' || rawSubStatus == 'banned' || regStatus == 'banned') {
      state.value = SubscriptionState.suspended;
      return;
    }

    if (renewalStatus == 'pending') {
      state.value = SubscriptionState.renewalPending;
      return;
    }

    final isActive =
        SubscriptionDateUtils.isSubscriptionActive(expiryDate, currentTime: now);

    if (!isActive || days <= 0) {
      state.value = SubscriptionState.expired;
    } else if (days <= 7) {
      state.value = SubscriptionState.expiringSoon;
    } else {
      state.value = SubscriptionState.active;
    }
  }

  /// Recalculates remaining days based on current clock & updates state
  void recalculateRemaining() {
    final details = subscriptionDetails.value;
    if (details == null || details.expiryDate == null) {
      remainingDays.value = 0;
      return;
    }

    final now = DateTime.now();
    _lastCalculatedDate = now;
    final days = SubscriptionDateUtils.calculateRemainingDays(
        details.expiryDate, currentTime: now);
    remainingDays.value = days;

    final isActive = SubscriptionDateUtils.isSubscriptionActive(
        details.expiryDate, currentTime: now);

    if (!isActive || days <= 0) {
      state.value = SubscriptionState.expired;
    } else if (days <= 7) {
      state.value = SubscriptionState.expiringSoon;
    } else {
      state.value = SubscriptionState.active;
    }
  }

  bool get hasActiveStoreAccess {
    return state.value == SubscriptionState.active ||
        state.value == SubscriptionState.expiringSoon;
  }

  bool get isExpired => state.value == SubscriptionState.expired;

  bool get isExpiringSoon => state.value == SubscriptionState.expiringSoon;

  bool get isRenewalPending => state.value == SubscriptionState.renewalPending;

  String get expiryDateFormatted =>
      SubscriptionDateUtils.formatDisplayDate(subscriptionDetails.value?.expiryDate);

  void promptExpiredDialog({VoidCallback? onRenewPressed}) {
    SubscriptionExpiredDialog.show(
      expiryDate: subscriptionDetails.value?.expiryDate,
      planName: subscriptionDetails.value?.planName,
      expiryFormatted: expiryDateFormatted,
      onRenewPressed: onRenewPressed,
    );
  }

  Future<void> fetchHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snap = await _firestore
          .collection('sellers')
          .doc(user.uid)
          .collection('subscription_history')
          .orderBy('timestamp', descending: true)
          .limit(25)
          .get();

      historyList.value = snap.docs
          .map((doc) => SubscriptionHistoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint("[SubscriptionController] fetchHistory error: $e");
    }
  }

  void resetState() {
    subscriptionDetails.value = null;
    remainingDays.value = 0;
    state.value = SubscriptionState.notStarted;
    historyList.clear();
  }
}


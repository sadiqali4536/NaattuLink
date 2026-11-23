import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naattulink/MVVM/model/models/queue_model.dart';
import 'package:naattulink/MVVM/model/services/queue_repository.dart';
import 'package:naattulink/MVVM/utils/service_functions/auth_lookup_service.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueueController extends GetxController {
  final QueueRepository _repository = QueueRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isLoading = false.obs;
  var currentToken = Rxn<QueueTokenModel>();

  // Fetch Public ID logic if stored locally or in Firestore
  Future<String> _getUserPublicId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('publicId') ?? 'NL-USR-UNKNOWN';
  }

  Future<void> takeToken(
    BuildContext context, {
    required String businessDocId,
    required String businessPublicId,
    String? serviceId,
    String? serviceName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      CherryToast.warning(
        title: const Text('Login Required',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Please login to take a token.'),
        animationType: AnimationType.fromTop,
      ).show(context);
      return;
    }

    isLoading.value = true;

    // Resolve universal participant
    final participant =
        await AuthLookupService.resolveUniversalParticipant(user.uid);
    if (participant == null) {
      isLoading.value = false;
      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Could not verify your account identity.'),
        animationType: AnimationType.fromTop,
      ).show(context);
      return;
    }

    final result = await _repository.assignTokenAtomically(
      businessDocId: businessDocId,
      businessPublicId: businessPublicId,
      participant: participant,
      serviceId: serviceId,
      serviceName: serviceName,
    );

    isLoading.value = false;

    if (result['success']) {
      currentToken.value = result['token'];
      if (result['existing'] == true) {
        CherryToast.info(
          title: const Text('Existing Token',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text(
              'You already have token #${currentToken.value!.tokenNumber}.'),
          animationType: AnimationType.fromTop,
        ).show(context);
      } else {
        CherryToast.success(
          title: const Text('Token Assigned',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description:
              Text('Your token number is #${currentToken.value!.tokenNumber}.'),
          animationType: AnimationType.fromTop,
        ).show(context);
      }
    } else {
      String errorMessage = 'Failed to take token.';
      switch (result['error']) {
        case 'business_not_found':
        case 'business_not_approved':
          errorMessage = 'Business is not available.';
          break;
        case 'queue_disabled':
          errorMessage = 'Queue is not enabled for this business.';
          break;
        case 'queue_closed':
          errorMessage = 'The queue is currently closed.';
          break;
        case 'queue_full':
          errorMessage = 'The queue is full. Please try again later.';
          break;
        default:
          errorMessage = result['error'] ?? 'Unknown error';
      }

      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(errorMessage),
        animationType: AnimationType.fromTop,
      ).show(context);
    }
  }

  Future<void> cancelToken(
    BuildContext context, {
    required String businessDocId,
    required String businessPublicId,
    required String tokenId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;

    // Resolve universal participant
    final participant =
        await AuthLookupService.resolveUniversalParticipant(user.uid);
    if (participant == null) {
      isLoading.value = false;
      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Could not verify your account identity.'),
        animationType: AnimationType.fromTop,
      ).show(context);
      return;
    }

    final result = await _repository.cancelTokenAtomically(
      businessDocId: businessDocId,
      businessPublicId: businessPublicId,
      tokenId: tokenId,
      participant: participant,
    );
    isLoading.value = false;

    if (result['success']) {
      currentToken.value = null;
      CherryToast.success(
        title: const Text('Cancelled',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Your token was cancelled successfully.'),
        animationType: AnimationType.fromTop,
      ).show(context);
    } else {
      String errorMessage = 'Failed to cancel token.';
      if (result['error'] == 'cancellation_disabled') {
        errorMessage = 'This business does not allow cancellations.';
      }
      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(errorMessage),
        animationType: AnimationType.fromTop,
      ).show(context);
    }
  }
}

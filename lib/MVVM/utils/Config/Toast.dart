// ------------------------------toast start------------------------
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

toastWarning(msg) async {
  final context = Get.overlayContext ?? Get.context;
  if (context != null) {
    CherryToast.warning(
      description: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      animationType: AnimationType.fromLeft,
      displayCloseButton: false,
      borderRadius: 16,
      toastDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }
}

toastError(msg) async {
  final context = Get.overlayContext ?? Get.context;
  if (context != null) {
    CherryToast.error(
      description: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      animationType: AnimationType.fromLeft,
      displayCloseButton: false,
      borderRadius: 16,
      toastDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }
}

toastSuccess(msg) async {
  final context = Get.overlayContext ?? Get.context;
  if (context != null) {
    CherryToast.success(
      description: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      animationType: AnimationType.fromLeft,
      displayCloseButton: false,
      borderRadius: 16,
      toastDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }
}

toastInfo(msg) async {
  final context = Get.overlayContext ?? Get.context;
  if (context != null) {
    CherryToast.info(
      description: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      animationType: AnimationType.fromLeft,
      displayCloseButton: false,
      borderRadius: 16,
      toastDuration: const Duration(milliseconds: 2500),
    ).show(context);
  }
}

// ------------------------------toast start------------------------

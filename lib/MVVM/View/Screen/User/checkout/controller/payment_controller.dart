import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/order_success_page.dart';

enum PaymentMethod { upi, cashOnDelivery }

enum UpiPaymentState { initial, paymentInitiated, transactionIdEntered }

class PaymentController extends GetxController {
  // Config
  static const String merchantUpiId =
      'merchant@upi'; // Replace with real UPI ID
  static const String merchantName = 'NaattuLink';

  // State
  var selectedPaymentMethod = PaymentMethod.cashOnDelivery.obs;
  var upiPaymentState = UpiPaymentState.initial.obs;
  var transactionId = ''.obs;
  var isPlacingOrder = false.obs;

  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
    if (method == PaymentMethod.cashOnDelivery) {
      upiPaymentState.value = UpiPaymentState.initial;
      transactionId.value = '';
    }
  }

  Future<void> initiateUpiPayment(double amount) async {
    final uri = Uri.parse(
        'upi://pay?pa=$merchantUpiId&pn=$merchantName&am=${amount.toStringAsFixed(2)}&cu=INR');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        upiPaymentState.value = UpiPaymentState.paymentInitiated;
      } else {
        Get.snackbar('Error', 'No compatible UPI application found.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to open the selected payment app.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void updateTransactionId(String id) {
    transactionId.value = id;
    if (id.trim().isNotEmpty &&
        upiPaymentState.value == UpiPaymentState.paymentInitiated) {
      upiPaymentState.value = UpiPaymentState.transactionIdEntered;
    } else if (id.trim().isEmpty &&
        upiPaymentState.value == UpiPaymentState.transactionIdEntered) {
      upiPaymentState.value = UpiPaymentState.paymentInitiated;
    }
  }

  String _buildFullAddress(AppLocationModel loc) {
    List<String> parts = [];
    if (loc.landmark != null && loc.landmark!.trim().isNotEmpty) {
      parts.add(loc.landmark!.trim());
    }
    parts.add(loc.formattedAddress);
    if (loc.city != null &&
        loc.city!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.city!)) {
      parts.add(loc.city!.trim());
    }
    if (loc.district.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.district)) {
      parts.add(loc.district.trim());
    }
    if (loc.state != null &&
        loc.state!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.state!)) {
      parts.add(loc.state!.trim());
    }
    if (loc.pincode != null &&
        loc.pincode!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.pincode!)) {
      parts.add(loc.pincode!.trim());
    }
    return parts.join(', ');
  }

  Future<void> placeOrder({
    required List<CartItemModel> cartItems,
    required double totalAmount,
    required AppLocationModel address,
    required bool isFromCart,
  }) async {
    if (isPlacingOrder.value) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Your session has expired. Please login again.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (selectedPaymentMethod.value == PaymentMethod.upi) {
      if (transactionId.value.trim().isEmpty) {
        Get.snackbar('Error', 'Please enter the UPI Transaction ID / UTR.',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }
    }

    isPlacingOrder.value = true;

    try {
      String? generatedOrderId;

      for (var item in cartItems) {
        String? finalSellerId = item.sellerId;
        if (finalSellerId == null || finalSellerId.isEmpty) {
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('store_products')
                .doc(item.productId)
                .get();
            if (productDoc.exists) {
              final pData = productDoc.data();
              finalSellerId =
                  pData?['sellerId'] ?? pData?['ownerId'] ?? pData?['storeId'];
            }
          } catch (e) {
            debugPrint("Failed to fetch product for sellerId: $e");
          }
        }

        final bookingData = {
          'userId': user.uid,
          'productId': item.productId,
          'serviceTitle': item.productName,
          'image': item.productImage,
          'originalPrice': item.price.toString(),
          'discountPrice': item.offerPrice.toString(),
          'discount': '',
          'rating': 0.0,
          'category': '',
          'serviceType': '',
          'bookingType': 'Product Order',
          'status': selectedPaymentMethod.value == PaymentMethod.upi
              ? 'pending_verification'
              : 'pending',
          'paymentMethod': selectedPaymentMethod.value == PaymentMethod.upi
              ? 'upi'
              : 'cash_on_delivery',
          'transactionId': selectedPaymentMethod.value == PaymentMethod.upi
              ? transactionId.value.trim()
              : null,
          'workerId': null,
          'workerName': null,
          'sellerId': finalSellerId,
          'quantity': item.quantity,
          'variantName': item.variantName,
          'deliveryAddress': {
            'formattedAddress': _buildFullAddress(address),
            'latitude': address.latitude,
            'longitude': address.longitude,
            'district': address.district,
            'pincode': address.pincode,
            'receiverPhone': address.receiverPhone,
            'receiverName': address.receiverName,
            'alternatePhone': address.alternatePhone,
          },
          'totalAmount': item.offerPrice * item.quantity,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final docRef = await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);
        if (generatedOrderId == null) {
          generatedOrderId = docRef.id;
        }

        if (finalSellerId != null && finalSellerId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('seller_notifications')
              .add({
            'sellerId': finalSellerId,
            'title': 'New Order Received',
            'message': 'You have received a new order for ${item.productName}',
            'type': 'order',
            'created_at': FieldValue.serverTimestamp(),
            'is_read': false,
          });
        }

        if (isFromCart) {
          await FirebaseFirestore.instance
              .collection('carts')
              .doc(user.uid)
              .collection('items')
              .doc(item.id)
              .delete();
        }
      }

      Get.offAll(
          () => OrderSuccessPage(orderId: generatedOrderId ?? 'UNKNOWN'));
    } catch (e) {
      debugPrint("Error confirming order: $e");
      Get.snackbar('Error', 'Unable to place your order. Please try again.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isPlacingOrder.value = false;
    }
  }
}

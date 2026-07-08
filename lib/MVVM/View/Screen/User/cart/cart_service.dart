import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/models/cart_model.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/animation_widget/tickmark.dart';
import 'package:naattulink/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

Future<void> addToCart({
  required BuildContext context,
  required String? serviceName,
  required String? image,
  required String? originalPrice,
  required String? discountPrice,
  required String? discount,
  required int? rating,
  required String? category,
  required String? serviceType,
  String? selectedRoom,
  int? count,
  DateTime? selectedDate,
  String? selectedTime,
  String? gardenSize,
  Map<String, Object?>? extraDetails,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to add items to cart.')),
    );
    return;
  }

  try {
    final uid = user.uid;
    final userCartCollectionRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(uid)
        .collection('cartItems');

    // Create a new doc reference to generate an ID
    final newDocRef = userCartCollectionRef.doc();
    final String serviceId = newDocRef.id;

    final cartItem = CartModel(
      service_id: serviceId,
      service_name: serviceName ?? '',
      image: image ?? '',
      original_price: originalPrice ?? '',
      price: discountPrice ?? '',
      discount: discount ?? '',
      rating: rating ?? 0,
      category: category ?? '',
      service_type: serviceType ?? '',
      addedAt: Timestamp.now(),
    ).toJson();

    await newDocRef.set(cartItem);

    if (context.mounted) {
      CustomSnackBar.show(
          useTick: true,
          context: context,
          message: "Added to cart successfully!",
          color: Colors.white);
    }
  } catch (e) {
    debugPrint('Add to cart failed: $e');
    if (context.mounted) {
      CustomSnackBar.show(
          icon: Icons.cancel,
          iconcolor: erroriconcolor,
          context: context,
          message: "Failed to add to cart: ${e.toString()}",
          color: Colors.white);
    }
  }
}

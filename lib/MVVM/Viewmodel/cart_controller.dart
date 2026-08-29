import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/user/cart_item_model.dart';
import '../model/seller/store_product_model.dart';
import '../model/seller/product_variant.dart';

class CartController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _cartSubscription;
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        if (_currentUserId != user.uid) {
          _currentUserId = user.uid;
          _listenToCart();
        }
      } else {
        _currentUserId = null;
        clearCart();
      }
    });
  }

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }

  void _listenToCart() {
    _cartSubscription?.cancel();
    if (_currentUserId == null) return;

    isLoading.value = true;
    _cartSubscription = _firestore
        .collection('carts')
        .doc(_currentUserId)
        .collection('items')
        .snapshots()
        .listen((snapshot) {
      cartItems.value = snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data(), doc.id))
          .toList();
      isLoading.value = false;
    }, onError: (error) {
      isLoading.value = false;
      debugPrint("Error listening to cart: $error");
    });
  }

  int get totalItemCount => cartItems.length;
  int get totalQuantity =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal =>
      cartItems.fold(0, (sum, item) => sum + (item.offerPrice * item.quantity));

  void clearCart() {
    cartItems.clear();
    _cartSubscription?.cancel();
  }

  Future<void> addToCart(StoreProductModel product,
      {ProductVariant? variant}) async {
    final String? uid = _auth.currentUser?.uid ?? _currentUserId;
    if (uid == null) {
      // User is not logged in, should be handled by UI redirecting to login
      Get.snackbar('Login Required', 'Please log in to add items to cart',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      final String variantId = variant?.id ?? '';
      final String cartItemId =
          variantId.isNotEmpty ? '${product.id}_$variantId' : product.id;

      final DocumentReference cartItemRef = _firestore
          .collection('carts')
          .doc(uid)
          .collection('items')
          .doc(cartItemId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(cartItemRef);

        if (snapshot.exists) {
          final existingItem = CartItemModel.fromMap(
              snapshot.data() as Map<String, dynamic>, snapshot.id);
          final int newQuantity = existingItem.quantity + 1;

          // Check stock
          final int availableStock =
              variant?.stockQuantity ?? product.stockQuantity;
          if (newQuantity > availableStock && availableStock > 0) {
            throw Exception('Cannot exceed available stock limit.');
          }

          transaction.update(cartItemRef, {
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Check stock
          final int availableStock =
              variant?.stockQuantity ?? product.stockQuantity;
          if (availableStock <= 0) {
            throw Exception('Product is out of stock.');
          }

          final newItem = CartItemModel(
            id: cartItemId,
            productId: product.id,
            productName: product.productName,
            productImage: variant?.image ?? product.coverImage,
            price: variant?.price ?? product.price,
            offerPrice: variant?.discountPrice ?? product.discountPrice,
            quantity: 1,
            variantId: variant?.id,
            variantName:
                variant != null ? variant.attributes.values.join(' - ') : null,
            sellerId: product.sellerId,
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          transaction.set(cartItemRef, newItem.toMap());
        }
      });

      isLoading.value = false;
      Get.snackbar(
        'Success',
        'Added to cart',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      isLoading.value = false;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    if (_currentUserId == null) return;
    try {
      await _firestore
          .collection('carts')
          .doc(_currentUserId)
          .collection('items')
          .doc(cartItemId)
          .delete();
    } catch (e) {
      debugPrint("Error removing from cart: $e");
    }
  }

  Future<void> increaseQuantity(String cartItemId, int maxStock) async {
    if (_currentUserId == null) return;

    final itemIndex = cartItems.indexWhere((item) => item.id == cartItemId);
    if (itemIndex >= 0) {
      final item = cartItems[itemIndex];
      if (item.quantity >= maxStock && maxStock > 0) {
        Get.snackbar('Stock Limit', 'Cannot exceed available stock limit.');
        return;
      }

      try {
        await _firestore
            .collection('carts')
            .doc(_currentUserId)
            .collection('items')
            .doc(cartItemId)
            .update({
          'quantity': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error increasing quantity: $e");
      }
    }
  }

  Future<void> decreaseQuantity(String cartItemId) async {
    if (_currentUserId == null) return;

    final itemIndex = cartItems.indexWhere((item) => item.id == cartItemId);
    if (itemIndex >= 0) {
      final item = cartItems[itemIndex];
      if (item.quantity > 1) {
        try {
          await _firestore
              .collection('carts')
              .doc(_currentUserId)
              .collection('items')
              .doc(cartItemId)
              .update({
            'quantity': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint("Error decreasing quantity: $e");
        }
      } else {
        await removeFromCart(cartItemId);
      }
    }
  }
}

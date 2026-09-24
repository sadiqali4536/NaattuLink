import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StockManager {
  /// Deducts stock when an order is placed.
  /// Throws an exception if insufficient stock.
  static Future<void> deductStock({
    required String bookingId,
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    await _updateStockTransaction(
      bookingId: bookingId,
      productId: productId,
      quantityChange: -quantity,
      variantId: variantId,
      operationType: 'deduct',
    );
  }

  /// Restores stock when an order is cancelled/rejected.
  static Future<void> restoreStock({
    required String bookingId,
    required String productId,
    required int quantity,
    String? variantId,
  }) async {
    await _updateStockTransaction(
      bookingId: bookingId,
      productId: productId,
      quantityChange: quantity,
      variantId: variantId,
      operationType: 'restore',
    );
  }

  static Future<void> _updateStockTransaction({
    required String bookingId,
    required String productId,
    required int quantityChange,
    String? variantId,
    required String operationType,
  }) async {
    final db = FirebaseFirestore.instance;
    final productRef = db.collection('store_products').doc(productId);

    // Idempotency: Create a unique operation ID based on the booking and operation type.
    final opId = '${bookingId}_$operationType';
    final operationRef = db.collection('stock_operations').doc(opId);

    await db.runTransaction((transaction) async {
      // 1. Check idempotency
      final opDoc = await transaction.get(operationRef);
      if (opDoc.exists) {
        debugPrint("Stock operation $opId already completed. Skipping.");
        return; // Already processed
      }

      // 2. Read product
      final productDoc = await transaction.get(productRef);
      if (!productDoc.exists) {
        throw Exception("Product not found");
      }

      final data = productDoc.data()!;

      // 3. Update stock
      if (variantId != null && variantId.isNotEmpty) {
        // Update variant stock
        List<dynamic> variants = data['variants'] ?? [];
        bool variantFound = false;

        for (int i = 0; i < variants.length; i++) {
          final variant = variants[i] as Map<String, dynamic>;
          if (variant['id'] == variantId) {
            variantFound = true;
            int currentStock = variant['stockQuantity'] ?? 0;
            int newStock = currentStock + quantityChange;

            if (newStock < 0) {
              throw Exception("Insufficient stock available.");
            }

            variants[i]['stockQuantity'] = newStock;
            break;
          }
        }

        if (!variantFound) {
          throw Exception("Variant not found in product.");
        }

        transaction.update(productRef, {'variants': variants});
      } else {
        // Update main product stock (Legacy fallback)
        int currentStock = data['stockQuantity'] ?? 0;
        int newStock = currentStock + quantityChange;

        if (newStock < 0) {
          throw Exception("Insufficient stock available.");
        }

        transaction.update(productRef, {'stockQuantity': newStock});
      }

      // 4. Mark operation as completed
      transaction.set(operationRef, {
        'bookingId': bookingId,
        'productId': productId,
        'variantId': variantId,
        'quantityChange': quantityChange,
        'operationType': operationType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}

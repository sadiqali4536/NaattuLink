import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentUpiResolver {
  static Future<String?> resolvePaymentUpiId(
      {String sellerId = '', String productId = ''}) async {
    String? platformFeeStatus;
    String? platformUpi;

    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          platformFeeStatus = data['PlatformFeeStatus']?.toString();
          platformUpi = data['platform_upi']?.toString().trim();
        }
      }
    } catch (e) {
      debugPrint(
          "Error reading platform_settings (possibly missing or permission denied): $e");
    }

    String? sellerUpi;
    try {
      String resolvedSellerId = sellerId;
      if (resolvedSellerId.isEmpty && productId.isNotEmpty) {
        final productDoc = await FirebaseFirestore.instance
            .collection('store_products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          final pData = productDoc.data() as Map<String, dynamic>?;
          if (pData != null) {
            resolvedSellerId = (pData['sellerId'] ??
                    pData['ownerId'] ??
                    pData['storeId'] ??
                    '')
                .toString()
                .trim();
          }
        }
      }

      if (resolvedSellerId.isNotEmpty) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(resolvedSellerId)
            .get();

        if (sellerDoc.exists) {
          final data = sellerDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            sellerUpi = data['upiId']?.toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching seller UPI: $e");
    }

    final isPlatformFeeActive =
        platformFeeStatus?.trim().toLowerCase() == 'active';

    final paymentUpiId = isPlatformFeeActive ? platformUpi : sellerUpi;

    return (paymentUpiId != null && paymentUpiId.isNotEmpty)
        ? paymentUpiId
        : null;
  }
}

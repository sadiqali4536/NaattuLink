import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/View/Screen/Seller/Dashboard/order_details_screen.dart';

class SellerRefundPendingOrdersScreen extends StatelessWidget {
  const SellerRefundPendingOrdersScreen({super.key});

  Widget _buildOrderItem({
    required String orderId,
    required String items,
    required String price,
    required String status,
    required Color statusColor,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (paymentMethod != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFB9D5FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod.toLowerCase() == 'upi'
                                ? Icons.currency_rupee
                                : Icons.money,
                            size: 10,
                            color: const Color(0xFF0857A0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentMethod.toLowerCase() == 'upi'
                                ? 'UPI'
                                : 'Cash on Delivery',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0857A0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (paymentMethod.toLowerCase() == 'upi' &&
                        (paymentStatus?.toLowerCase() == 'completed' ||
                            paymentStatus?.toLowerCase() == 'paid' ||
                            paymentStatus?.toLowerCase() == 'success')) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'PAID',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2E5A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Refund Pending Orders",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                "No recent orders yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('sellerId', isEqualTo: uid)
                  .where('bookingType', isEqualTo: 'Product Order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "Error loading orders",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No orders found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                // Filter and sort locally
                final allDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status =
                      (data['status'] ?? '').toString().toLowerCase();
                  if (!status.contains('cancel') && !status.contains('reject'))
                    return false;

                  final isRefunded = data['Refuned']?.toString() == '1' ||
                      data['Refuned']?.toString().toLowerCase() == 'true' ||
                      data['Refuned'] == true ||
                      data['Refuned'] == 1;

                  final paymentMethod =
                      data['paymentMethod']?.toString().toLowerCase() ?? '';
                  final transactionId = data['transactionId']?.toString() ?? '';
                  final isOnline = paymentMethod.contains('online') ||
                      paymentMethod.contains('upi') ||
                      transactionId.isNotEmpty;

                  return isOnline && !isRefunded;
                }).toList();

                if (allDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        "No refund pending orders",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                allDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = (aData['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = (bData['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: allDocs.length,
                  itemBuilder: (context, index) {
                    final doc = allDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final displayId = data['orderId'] != null
                        ? "#${data['orderId']}"
                        : "#${docId.toUpperCase()}";

                    // Handle cart array for items display
                    String itemsText = '1 Item';
                    final cart = data['cart'];
                    if (cart is List) {
                      int totalQty = 0;
                      for (var item in cart) {
                        if (item is Map) {
                          totalQty +=
                              num.tryParse(item['qty']?.toString() ?? '1')
                                      ?.toInt() ??
                                  1;
                        }
                      }
                      itemsText = '$totalQty Item${totalQty > 1 ? 's' : ''}';
                    }

                    // Format price
                    final rawPrice = data['totalAmount'] ??
                        data['price'] ??
                        data['discountPrice'] ??
                        0;
                    final parsedPrice = num.tryParse(rawPrice.toString()) ?? 0;
                    final priceText = '₹${parsedPrice.toInt()}';

                    // Parse status and assign color
                    final statusStr = (data['status'] ?? 'Pending').toString();
                    Color statusColor = Colors.orange;
                    if (statusStr.toLowerCase().contains('dispatch')) {
                      statusColor = Colors.green;
                    } else if (statusStr.toLowerCase().contains('deliver')) {
                      statusColor = Colors.green;
                    } else if (statusStr.toLowerCase().contains('cancel') ||
                        statusStr.toLowerCase().contains('reject')) {
                      statusColor = Colors.red;
                    }

                    // Build mapped data for order details
                    final customerName =
                        data['customerName']?.toString().isNotEmpty == true
                            ? data['customerName'].toString()
                            : (data['deliveryAddress']?['receiverName']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? data['deliveryAddress']['receiverName']
                                    .toString()
                                : 'Customer');
                    final mappedData = {
                      'docId': docId,
                      'orderId': data['orderId']?.toString() ?? docId,
                      'customerName': customerName,
                      'customerLocation': data['deliveryAddress']
                              ?['formattedAddress'] ??
                          'Unknown Location',
                      'customerPhone':
                          data['deliveryAddress']?['receiverPhone'] ?? '',
                      'customerAltPhone':
                          data['deliveryAddress']?['alternatePhone'] ?? '',
                      'status': (data['status'] ?? 'Pending').toString(),
                      'subtotal': rawPrice,
                      'deliveryFee': 0,
                      'paymentMethod': data['paymentMethod'] ?? 'Unknown',
                      'paymentStatus': data['paymentStatus'] ?? 'Pending',
                      'transactionId': data['transactionId'],
                      'Refuned': data['Refuned'],
                      'isFromRefundScreen': true,
                      'formattedReceipt': data['formattedReceipt'],
                      'ocrAmountExtracted': data['ocrAmountExtracted'],
                      'ocrReceiverUpi': data['ocrReceiverUpi'],
                      'ocrPaymentDateTime': data['ocrPaymentDateTime'],
                      'ocrHasSuccessIndicator': data['ocrHasSuccessIndicator'],
                      'cancellationReason': data['cancellationReason'],
                      'cancellationComment': data['cancellationComment'],
                      'items': cart is List && cart.isNotEmpty
                          ? cart
                          : [
                              {
                                'name': data['serviceTitle'] ?? 'Product',
                                'qty': data['quantity'] ?? 1,
                                'price': rawPrice,
                                'image': data['image'],
                              }
                            ],
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          Get.to(() =>
                              SellerOrderDetailsScreen(orderData: mappedData));
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _buildOrderItem(
                          orderId: displayId,
                          items: itemsText,
                          price: priceText,
                          status: statusStr,
                          statusColor: statusColor,
                          paymentMethod:
                              mappedData['paymentMethod']?.toString(),
                          paymentStatus:
                              mappedData['paymentStatus']?.toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

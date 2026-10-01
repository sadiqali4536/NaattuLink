import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:naattulink/MVVM/utils/stock_manager.dart';
import 'cancellation_confirmed_screen.dart';

class OrderCancellationScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> orderData;

  const OrderCancellationScreen({
    Key? key,
    required this.bookingId,
    required this.orderData,
  }) : super(key: key);

  @override
  State<OrderCancellationScreen> createState() =>
      _OrderCancellationScreenState();
}

class _OrderCancellationScreenState extends State<OrderCancellationScreen> {
  String? _selectedReason;
  final TextEditingController _commentController = TextEditingController();
  bool _isCancelling = false;
  bool _hasCommentText = false;

  final List<String> _cancellationReasons = [
    'I ordered this product by mistake',
    'I found a better price',
    'I no longer need this product',
    'I want to change the product/order',
    'I ordered the wrong product',
    'Delivery is taking too long',
    'Product price has now decreased',
    'I want to change the payment option',
    'I was hoping for a shorter delivery time',
    'My reason is not listed here',
  ];

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      final hasText = _commentController.text.trim().isNotEmpty;
      if (hasText != _hasCommentText) {
        setState(() {
          _hasCommentText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedReason == null ||
        (_selectedReason == 'My reason is not listed here' &&
            !_hasCommentText)) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);

      // Re-check Firestore status
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        throw Exception('Order not found');
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();

      if (status != 'pending' &&
          status != 'processing' &&
          status != 'pending_verification') {
        CherryToast.warning(
          description: const Text(
            'This order can no longer be cancelled because its status has changed.',
            style: TextStyle(color: Colors.black87),
          ),
          animationType: AnimationType.fromLeft,
          toastPosition: Position.bottom,
          toastDuration: const Duration(seconds: 4),
        ).show(context);
        setState(() {
          _isCancelling = false;
        });
        return;
      }

      final paymentMethod = data['paymentMethod'] ?? 'cash_on_delivery';
      final isOnline = paymentMethod.toString().toLowerCase() == 'upi';

      await docRef.update({
        'status': 'Cancelled',
        'cancellationReason': _selectedReason,
        'cancellationComment': _commentController.text.trim(),
        'cancelledBy': 'customer',
        'cancelledAt': FieldValue.serverTimestamp(),
        'refundStatus': isOnline ? 'Pending' : 'Not Applicable',
      });

      try {
        final productId = data['productId'];
        if (productId != null) {
          final variantId = data['variantId'];
          final variantName = data['variantName'];
          final quantityStr = data['quantity']?.toString() ?? '1';
          final quantity = int.tryParse(quantityStr) ?? 1;

          await StockManager.restoreStock(
            bookingId: docRef.id,
            productId: productId.toString(),
            quantity: quantity,
            variantId: variantId?.toString(),
            variantName: variantName?.toString(),
          );
        }
      } catch (e) {
        debugPrint("Error restoring stock on user cancellation: $e");
      }

      final productName = data['serviceTitle'] ?? 'Product';
      final orderIdStr = data['orderId']?.toString() ?? widget.bookingId;

      Get.off(() => CancellationConfirmedScreen(
            productName: productName,
            orderId: orderIdStr,
          ));
    } catch (e) {
      CherryToast.error(
        description: Text(
          'Failed to cancel order: $e',
          style: const TextStyle(color: Colors.black87),
        ),
        animationType: AnimationType.fromLeft,
        toastPosition: Position.bottom,
      ).show(context);
      setState(() {
        _isCancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String productName =
        widget.orderData['serviceTitle'] ?? 'Product Name';
    final String imageUrl = widget.orderData['image'] ?? '';
    final int quantity = widget.orderData['quantity'] ?? 1;
    final dynamic priceVal = widget.orderData['discountPrice'] ??
        widget.orderData['totalAmount'] ??
        widget.orderData['originalPrice'] ??
        0;
    final double rawPrice = priceVal is num
        ? priceVal.toDouble()
        : double.tryParse(priceVal.toString()) ?? 0.0;
    final String formattedPrice = rawPrice == rawPrice.toInt()
        ? rawPrice.toInt().toString()
        : rawPrice.toStringAsFixed(2);
    final String variantName = widget.orderData['variantName'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text('request_cancellation'.tr,
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                            width: 70, height: 70, color: Colors.grey.shade200),
                      ),
                    )
                  else
                    Container(
                        width: 70, height: 70, color: Colors.grey.shade200),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (variantName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(variantName,
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 13)),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Qty: $quantity',
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 13)),
                            Text('₹$formattedPrice',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 5, 150, 82))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reasons
            Text('reason_cancellation'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _cancellationReasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(reason,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Colors.black87 : Colors.black54,
                            )),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                        activeColor: const Color(0xFF0F2E5A),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        dense: true,
                      ),
                      if (reason != _cancellationReasons.last)
                        Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),

            if (_selectedReason == 'My reason is not listed here') ...[
              const SizedBox(height: 24),
              Text('comments_req'.tr,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tell us more about your reason...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F2E5A)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: (_selectedReason != null &&
              (_selectedReason != 'My reason is not listed here' ||
                  _hasCommentText))
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCancelling ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('submit_request'.tr,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

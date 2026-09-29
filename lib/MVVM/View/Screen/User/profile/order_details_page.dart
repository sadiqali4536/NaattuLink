import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/order_status_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/order_cancellation_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class OrderDetailsPage extends StatefulWidget {
  final String bookingId;

  const OrderDetailsPage({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final List<String> _timelineSteps = [
    'pending',
    'processing',
    'dispatched',
  ];

  int _getCurrentStepIndex(String status) {
    final lower = status.toLowerCase();
    if (lower == 'pending') return 0;
    if (lower == 'processing') return 1;
    if (lower == 'dispatched') return 2;
    return 0; // Default to 0 for unrecognized pending-like statuses
  }

  String _getStepDate(Map<String, dynamic> data, String step) {
    Timestamp? timestamp;
    if (step == 'pending') {
      timestamp = data['createdAt'];
    } else if (step == 'processing') {
      timestamp =
          data['acceptedAt'] ?? data['processedAt'] ?? data['processingAt'];
    } else if (step == 'dispatched') {
      timestamp =
          data['dispatchedAt'] ?? data['shippedAt'] ?? data['updatedAt'];
    } else if (step == 'cancelled') {
      timestamp = data['cancelledAt'] ?? data['updatedAt'] ?? data['createdAt'];
    }

    if (timestamp != null) {
      try {
        return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(
              body: Center(child: Text('Error loading order details')));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Order not found')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String rawStatus = data['status'] ?? 'pending';
        final String statusTitle =
            OrderStatusUtils.getOrderStatusTitle(rawStatus);
        final String statusMessage =
            OrderStatusUtils.getOrderStatusMessage(rawStatus);

        final String orderId = data['orderId']?.toString() ?? widget.bookingId;
        final double rawPrice =
            (data['totalAmount'] ?? data['price'] ?? 0).toDouble();
        final String formattedPrice = rawPrice == rawPrice.toInt()
            ? rawPrice.toInt().toString()
            : rawPrice.toStringAsFixed(2);

        final bool isCancelled = rawStatus.toLowerCase() == 'cancelled';
        final bool canCancel = rawStatus.toLowerCase() == 'pending' ||
            rawStatus.toLowerCase() == 'processing' ||
            rawStatus.toLowerCase() == 'pending_verification';
        final int currentStep =
            isCancelled ? -1 : _getCurrentStepIndex(rawStatus);

        return Scaffold(
            backgroundColor: const Color(0xFFFAFAFA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: const AppBackButton(),
              title: const Text(
                'Order Details',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              centerTitle: false,
              actions: [
                TextButton(
                  onPressed: () =>
                      _showHelpBottomSheet(context, data, rawStatus),
                  child: const Text('Help',
                      style: TextStyle(
                          color: Color(0xFF0F2E5A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Order ID',
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('#$orderId',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    if (data['transactionId'] != null &&
                                        data['transactionId']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text('Transaction ID',
                                          style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('${data['transactionId']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ],
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Total Price',
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('₹$formattedPrice',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color.fromARGB(
                                                255, 5, 150, 82))),
                                  ],
                                ),
                              ],
                            ),

                            Builder(builder: (context) {
                              final paymentMethod = data['paymentMethod']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';
                              final transactionId =
                                  data['transactionId']?.toString() ?? '';
                              final isOnline =
                                  paymentMethod.contains('online') ||
                                      paymentMethod.contains('upi') ||
                                      transactionId.isNotEmpty;

                              final isRefunded = data['Refuned']?.toString() ==
                                      '1' ||
                                  data['Refuned']?.toString().toLowerCase() ==
                                      'true' ||
                                  data['Refuned'] == true ||
                                  data['Refuned'] == 1;

                              if (isCancelled && isOnline) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isRefunded
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isRefunded
                                            ? Colors.green.shade200
                                            : Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                          isRefunded
                                              ? Icons.check_circle_outline
                                              : Icons.currency_rupee,
                                          color: isRefunded
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isRefunded
                                                  ? "Refund Processed Successfully"
                                                  : "Refund Pending",
                                              style: TextStyle(
                                                color: isRefunded
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              isRefunded
                                                  ? "Your refund has been marked as completed by the seller."
                                                  : "Your refund amount will process within 2 days.",
                                              style: TextStyle(
                                                color: isRefunded
                                                    ? Colors.green.shade600
                                                    : Colors.orange.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            const SizedBox(height: 24),

                            // Timeline
                            const Text(
                              'Order Tracking',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: List.generate(
                                    isCancelled ? 2 : _timelineSteps.length,
                                    (index) {
                                  final displaySteps = isCancelled
                                      ? ['pending', 'cancelled']
                                      : _timelineSteps;
                                  final step = displaySteps[index];
                                  final isCompleted =
                                      isCancelled ? true : index <= currentStep;
                                  final isLast =
                                      index == displaySteps.length - 1;
                                  final isCancelledStep = step == 'cancelled';

                                  String title = '';
                                  String subtitle = '';
                                  if (step == 'pending') {
                                    title = 'Order Confirmed';
                                    subtitle = 'Your order has been received';
                                  } else if (step == 'processing') {
                                    title = 'Processing';
                                    subtitle = 'Your order is being processed';
                                  } else if (step == 'dispatched') {
                                    title = 'Order Dispatched';
                                    subtitle = 'Your order has been dispatched';
                                  } else if (step == 'cancelled') {
                                    title = 'Order Cancelled';
                                    final paymentMethod = data['paymentMethod']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    final transactionId =
                                        data['transactionId']?.toString() ?? '';
                                    final isOnline =
                                        paymentMethod.contains('online') ||
                                            paymentMethod.contains('upi') ||
                                            transactionId.isNotEmpty;

                                    final isRefunded =
                                        data['Refuned']?.toString() == '1' ||
                                            data['Refuned']
                                                    ?.toString()
                                                    .toLowerCase() ==
                                                'true' ||
                                            data['Refuned'] == true ||
                                            data['Refuned'] == 1;

                                    if (isOnline) {
                                      subtitle = isRefunded
                                          ? 'Refund completed successfully'
                                          : 'Refund amount will process within 2 days';
                                    } else {
                                      subtitle =
                                          'Your order has been cancelled';
                                    }
                                  }

                                  String dateText = isCompleted
                                      ? _getStepDate(data, step)
                                      : '';

                                  return _buildTimelineStep(
                                    title: title,
                                    subtitle: subtitle,
                                    dateText: dateText,
                                    isCompleted: isCompleted,
                                    isLast: isLast,
                                    isCancelledStep: isCancelledStep,
                                  );
                                }),
                              ),
                            ),

                            if (!isCancelled &&
                                currentStep == 2 &&
                                data['trackingUrl'] != null &&
                                data['trackingUrl'].toString().isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildTrackOrderCard(
                                  data['trackingUrl'].toString()),
                            ],

                            if (data['paymentMethod'] == 'upi' &&
                                data['transactionId'] != null)
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('payments')
                                    .doc(data['transactionId'].toString())
                                    .get(),
                                builder: (context, paymentSnapshot) {
                                  if (!paymentSnapshot.hasData ||
                                      !paymentSnapshot.data!.exists)
                                    return const SizedBox.shrink();
                                  final pData = paymentSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                                  if (pData == null ||
                                      pData['formattedReceipt'] == null)
                                    return const SizedBox.shrink();

                                  return Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  insetPadding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 24),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFDFDFD),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300,
                                                          width: 1.5),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          blurRadius: 20,
                                                          offset: const Offset(
                                                              0, 10),
                                                        )
                                                      ],
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            const Text(
                                                              'RECEIPT',
                                                              style: TextStyle(
                                                                letterSpacing:
                                                                    2,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontSize: 18,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.close,
                                                                  color: Colors
                                                                      .black54),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            final boxWidth =
                                                                constraints
                                                                    .constrainWidth();
                                                            const dashWidth =
                                                                6.0;
                                                            const dashHeight =
                                                                1.5;
                                                            final dashCount =
                                                                (boxWidth /
                                                                        (2 *
                                                                            dashWidth))
                                                                    .floor();
                                                            return Flex(
                                                              direction: Axis
                                                                  .horizontal,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children:
                                                                  List.generate(
                                                                      dashCount,
                                                                      (_) {
                                                                return const SizedBox(
                                                                  width:
                                                                      dashWidth,
                                                                  height:
                                                                      dashHeight,
                                                                  child: DecoratedBox(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                              color: Colors.grey)),
                                                                );
                                                              }),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Flexible(
                                                          child:
                                                              SingleChildScrollView(
                                                            child: MarkdownBody(
                                                              data: pData[
                                                                      'formattedReceipt']
                                                                  .toString(),
                                                              styleSheet:
                                                                  MarkdownStyleSheet(
                                                                h1: const TextStyle(
                                                                    color: Colors
                                                                        .black87,
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                                h3: const TextStyle(
                                                                    color: Colors
                                                                        .black87,
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                                p: const TextStyle(
                                                                    color: Colors
                                                                        .black87,
                                                                    fontSize:
                                                                        14,
                                                                    height:
                                                                        1.5),
                                                                strong: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        LayoutBuilder(
                                                          builder: (context,
                                                              constraints) {
                                                            final boxWidth =
                                                                constraints
                                                                    .constrainWidth();
                                                            const dashWidth =
                                                                6.0;
                                                            const dashHeight =
                                                                1.5;
                                                            final dashCount =
                                                                (boxWidth /
                                                                        (2 *
                                                                            dashWidth))
                                                                    .floor();
                                                            return Flex(
                                                              direction: Axis
                                                                  .horizontal,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children:
                                                                  List.generate(
                                                                      dashCount,
                                                                      (_) {
                                                                return const SizedBox(
                                                                  width:
                                                                      dashWidth,
                                                                  height:
                                                                      dashHeight,
                                                                  child: DecoratedBox(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                              color: Colors.grey)),
                                                                );
                                                              }),
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        const Center(
                                                          child: Text(
                                                            'Thank you for your order!',
                                                            style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color: Colors
                                                                  .black54,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.receipt_long,
                                                          color: Color(
                                                              0xFF0F2E5A)),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'View Payment Receipt',
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFF0F2E5A),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Colors.black45),
                                                ],
                                              ),
                                            ),
                                          )));
                                },
                              ),

                            // Extra details like shipping address could go here if available
                            const SizedBox(height: 40),
                          ],
                        ),
                      )
                    ])));
      },
    );
  }

  void _showHelpBottomSheet(
      BuildContext context, Map<String, dynamic> data, String rawStatus) {
    final status = rawStatus.toLowerCase();
    final bool canCancel = status == 'pending' ||
        status == 'processing' ||
        status == 'pending_verification';
    final bool isDispatched = status == 'shipped' || status == 'dispatched';
    final bool isDelivered = status == 'delivered' || status == 'completed';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Help',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Change my phone number'),
                onTap: () {
                  Get.back();
                  _showChangePhoneDialog(context, data);
                },
              ),
              if (!isDelivered)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Change delivery address'),
                  subtitle: isDispatched
                      ? const Text('Order already dispatched')
                      : null,
                  enabled: !isDispatched,
                  onTap: () {
                    Get.back();
                    _showChangeAddressDialog(context, data);
                  },
                ),
              if (!isDelivered)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined),
                  title: const Text('Cancel my order'),
                  subtitle: !canCancel
                      ? const Text('Order already dispatched')
                      : null,
                  enabled: canCancel,
                  onTap: () {
                    Get.back();
                    _showCancelConfirmationDialog(context, data);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmationDialog(
      BuildContext context, Map<String, dynamic> data) {
    final productName = data['serviceTitle'] ?? 'Product';
    final variantName = data['variantName'] ?? '';
    final imageUrl = data['image'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Cancel your order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox()),
              ),
            const SizedBox(height: 12),
            Text(productName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (variantName.isNotEmpty)
              Text(variantName,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 16),
            const Text(
                'If you cancel now, you may not be able to avail this deal again.\n\nDo you still want to cancel?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => OrderCancellationScreen(
                  bookingId: widget.bookingId, orderData: data));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, Map<String, dynamic> data) {
    final deliveryAddress =
        data['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final currentPhone = deliveryAddress['receiverPhone'] ?? '';
    final TextEditingController phoneController =
        TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Change Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Number',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            Text(currentPhone.isEmpty ? 'N/A' : currentPhone,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'New Phone Number', prefixText: '+91 '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = phoneController.text.trim();
              if (newPhone.length < 10) {
                Get.snackbar('Error', 'Please enter a valid phone number',
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              Get.back();
              deliveryAddress['receiverPhone'] = newPhone;
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .update({'deliveryAddress': deliveryAddress});
              Get.snackbar('Success', 'Phone number updated successfully',
                  backgroundColor: Colors.green, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2E5A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Number'),
          ),
        ],
      ),
    );
  }

  void _showChangeAddressDialog(
      BuildContext context, Map<String, dynamic> data) {
    final deliveryAddress =
        data['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final currentAddress = deliveryAddress['formattedAddress'] ?? '';
    final TextEditingController addressController =
        TextEditingController(text: currentAddress);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Change Delivery Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Address',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
            Text(currentAddress.isEmpty ? 'N/A' : currentAddress,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'New Delivery Address',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAddress = addressController.text.trim();
              if (newAddress.isEmpty) {
                Get.snackbar('Error', 'Please enter a valid address',
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              // Re-check status before updating
              final docSnap = await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .get();
              if (docSnap.exists) {
                final currentStatus =
                    (docSnap.data()!['status'] ?? '').toString().toLowerCase();
                if (currentStatus == 'shipped' ||
                    currentStatus == 'dispatched' ||
                    currentStatus == 'delivered' ||
                    currentStatus == 'completed' ||
                    currentStatus == 'cancelled') {
                  Get.back();
                  Get.snackbar('Cannot Update',
                      'This order has already been $currentStatus, so the delivery address can no longer be changed.',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4));
                  return;
                }
              }
              Get.back();
              deliveryAddress['formattedAddress'] = newAddress;
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .update({'deliveryAddress': deliveryAddress});
              Get.snackbar('Success', 'Delivery address updated successfully',
                  backgroundColor: Colors.green, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2E5A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String dateText,
    required bool isCompleted,
    required bool isLast,
    bool isCancelledStep = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCancelledStep
                      ? Colors.red
                      : (isCompleted
                          ? const Color(0xFF059669)
                          : Colors.grey.shade300),
                  border: isCompleted || isCancelledStep
                      ? null
                      : Border.all(color: Colors.grey.shade400),
                ),
                child: isCancelledStep
                    ? const Icon(Icons.close, color: Colors.white, size: 14)
                    : (isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF059669)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isCompleted ? FontWeight.bold : FontWeight.w500,
                      color: isCompleted ? Colors.black87 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted ? Colors.black54 : Colors.black38,
                    ),
                  ),
                  if (dateText.isNotEmpty && isCompleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackOrderCard(String url) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your order has been dispatched. Track your shipment for updates.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () async {
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2E5A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Track Your Order',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

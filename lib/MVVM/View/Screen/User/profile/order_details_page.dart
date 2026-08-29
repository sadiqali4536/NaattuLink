import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/order_status_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Order Details',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order details'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String rawStatus = data['status'] ?? 'pending';
          final String statusTitle =
              OrderStatusUtils.getOrderStatusTitle(rawStatus);
          final String statusMessage =
              OrderStatusUtils.getOrderStatusMessage(rawStatus);

          final String orderId =
              data['orderId']?.toString() ?? widget.bookingId;
          final double rawPrice =
              (data['totalAmount'] ?? data['price'] ?? 0).toDouble();
          final String formattedPrice = rawPrice == rawPrice.toInt()
              ? rawPrice.toInt().toString()
              : rawPrice.toStringAsFixed(2);

          final bool isCancelled = rawStatus.toLowerCase() == 'cancelled';
          final int currentStep =
              isCancelled ? -1 : _getCurrentStepIndex(rawStatus);

          return SingleChildScrollView(
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
                                          color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('#$orderId',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Total Price',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('₹$formattedPrice',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color:
                                              Color.fromARGB(255, 5, 150, 82))),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Timeline
                          if (!isCancelled) ...[
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
                                children: List.generate(_timelineSteps.length,
                                    (index) {
                                  final step = _timelineSteps[index];
                                  final isCompleted = index <= currentStep;
                                  final isLast =
                                      index == _timelineSteps.length - 1;

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
                                  );
                                }),
                              ),
                            ),
                          ],

                          if (!isCancelled &&
                              currentStep == 2 &&
                              data['trackingUrl'] != null &&
                              data['trackingUrl'].toString().isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildTrackOrderCard(
                                data['trackingUrl'].toString()),
                          ],

                          // Extra details like shipping address could go here if available
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  ]));
        },
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String dateText,
    required bool isCompleted,
    required bool isLast,
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
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : Colors.grey.shade300,
                  border: isCompleted
                      ? null
                      : Border.all(color: Colors.grey.shade400),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
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

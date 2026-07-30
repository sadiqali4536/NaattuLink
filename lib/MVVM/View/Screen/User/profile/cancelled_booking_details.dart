import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../services/service_details_page.dart';
import '../User_Dashboard/user_Dashboard.dart';

class CancelledBookingDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;

  const CancelledBookingDetails({
    super.key,
    required this.data,
    required this.bookingId,
  });

  String get _status => data['status']?.toString().toLowerCase() ?? 'cancelled';
  bool get _isCancelled => _status == 'cancelled';

  String get _formattedDate {
    try {
      return DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(data['selectedDate'] ?? ''));
    } catch (_) {
      return data['selectedDate'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => Get.offAll(() => const user_Dashboard()),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _isCancelled
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(_isCancelled ? Icons.cancel_outlined : Icons.done_all,
                  color: _isCancelled
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              _isCancelled ? 'Booking Cancelled!' : 'Booking Completed!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isCancelled
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB)),
            ),
            const SizedBox(height: 8),
            Text(
              _isCancelled
                  ? "We'll keep you posted on the status."
                  : "Thank you for using our service.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Order No Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ORDER NO',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                      Text(bookingId.substring(0, 10).toUpperCase(),
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline,
                          size: 18, color: Color(0xFF3B82F6)),
                      label: const Text('Chat with us',
                          style: TextStyle(color: Color(0xFF3B82F6))),
                      style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Color(0xFFE5E7EB), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SERVICE ADDRESS',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${data['addressTitle'] ?? ''}\n${data['addressSubtitle'] ?? ''}'
                              .trim(),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87, height: 1.4),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Service', data['serviceName'] ?? 'Service'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      'Order Status', _isCancelled ? 'Cancelled' : 'Completed',
                      valueColor: _isCancelled
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Booked Date', _formattedDate),
                  const SizedBox(height: 12),
                  if (data['selectedTimeSlot'] != null &&
                      data['selectedTimeSlot'].toString().isNotEmpty)
                    _buildDetailRow('Time slot', data['selectedTimeSlot']),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Need to re-schedule or have questions? Contact our support team directly through the chat or call.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Book Again Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => ServiceDetailsPage(
                        category: data['serviceCategory'] ?? 'Service',
                        serviceName: data['serviceName'] ?? 'Service',
                        rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
                        originalPrice: data['price'] ?? '0',
                        discount: '0',
                        image: data['image'] ?? '',
                        discountPrice: data['price'] ?? '0',
                        serviceId: data['serviceId'],
                        providerId: data['providerId'],
                        providerName: data['providerName'],
                        providerPhone: data['providerPhone'],
                        estimatedDuration: data['estimatedDuration'],
                      ));
                },
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text('Book Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}

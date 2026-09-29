import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../User_Dashboard/user_Dashboard.dart';

class ConfirmedBookingDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final Future<void> Function(String) onCancel;

  const ConfirmedBookingDetails({
    super.key,
    required this.data,
    required this.bookingId,
    required this.onCancel,
  });

  String get _formattedDate {
    try {
      return DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(data['selectedDate'] ?? ''));
    } catch (_) {
      return data['selectedDate'] ?? '';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
          'Booking Summary',
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
            // Success Icon
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x33059669),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            if (data['providerId'] != null &&
                data['providerId'].toString().trim().isNotEmpty &&
                data['providerId'].toString().trim().toLowerCase() !=
                    'null') ...[
              const Text(
                "We've assigned a top-rated professional for your service.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Provider Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipOval(
                            child: data['image'] != null &&
                                    data['image'].toString().isNotEmpty
                                ? Image.network(data['image'],
                                    fit: BoxFit.cover)
                                : Icon(Icons.person,
                                    color: Colors.grey.shade400, size: 30),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['providerName'] ?? 'Provider Name',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Top Rated',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data['serviceCategory'] != null
                                    ? '${_capitalize(data['serviceCategory'])} Service'
                                    : 'Professional',
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFF059669), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${data['rating'] ?? '4.9'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    '(120+ reviews)',
                                    style: TextStyle(
                                        color: Colors.black45, fontSize: 11),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.call,
                                size: 16, color: Colors.white),
                            label: Text(
                              data['providerPhone']?.toString().isNotEmpty ==
                                      true
                                  ? data['providerPhone']
                                  : 'Call Now',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 16, color: Color(0xFF0F2E5A)),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                  color: Color(0xFF0F2E5A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF0F2E5A)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
            if (data['providerId'] == null ||
                data['providerId'].toString().trim().isEmpty ||
                data['providerId'].toString().trim().toLowerCase() ==
                    'null') ...[
              const Text(
                "Your booking is confirmed. We are assigning a top-rated professional for your service soon.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]),
                child: const Column(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Waiting for Worker',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Insured & Verified Service',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87)),
                        SizedBox(height: 2),
                        Text(
                            'All professionals undergo rigorous background checks.',
                            style:
                                TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Details
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('ID: ${bookingId.toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.bolt, 'Service Type',
                      data['serviceName'] ?? 'Service'),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      Icons.calendar_today_outlined,
                      'Scheduled For',
                      '$_formattedDate${(data['selectedTimeSlot'] != null && data['selectedTimeSlot'].toString().trim().isNotEmpty && data['selectedTimeSlot'].toString().trim().toLowerCase() != 'null') ? ', ${data['selectedTimeSlot']}' : ''}'),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      Icons.location_on_outlined,
                      'Address',
                      [
                        if (data['houseBuildingNumber'] != null &&
                            data['houseBuildingNumber']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          data['houseBuildingNumber'],
                        if (data['addressSubtitle'] != null &&
                            data['addressSubtitle']
                                .toString()
                                .trim()
                                .isNotEmpty &&
                            data['addressSubtitle']
                                    .toString()
                                    .trim()
                                    .toLowerCase() !=
                                'null')
                          data['addressSubtitle']
                        else if (data['addressTitle'] != null &&
                            data['addressTitle']
                                    .toString()
                                    .trim()
                                    .toLowerCase() !=
                                'null')
                          data['addressTitle']
                        else
                          'Address'
                      ].join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.offAll(() => const user_Dashboard()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Back to Home',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Get.back();
                  onCancel(bookingId);
                },
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Cancel Booking',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}

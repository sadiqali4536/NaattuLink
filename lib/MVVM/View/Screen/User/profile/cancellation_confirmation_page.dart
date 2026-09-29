import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:intl/intl.dart';

class CancellationConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;
  final String selectedReason;
  final String transactionId;

  const CancellationConfirmationPage({
    Key? key,
    required this.bookingData,
    required this.bookingId,
    required this.selectedReason,
    required this.transactionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceName = bookingData['serviceName'] ?? 'Service';
    final requestedOn =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Lottie.asset(
                'assets/lotties/success_animation.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'Cancellation Request\nSuccessful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your booking cancellation has been\nprocessed and will be completed within\n2 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cancellation Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),
                    _buildDetailRow('Service', serviceName),
                    const SizedBox(height: 12),
                    _buildDetailRow('Booking ID', bookingId.toUpperCase()),
                    const SizedBox(height: 12),
                    _buildDetailRow('Cancellation reason', selectedReason),
                    const SizedBox(height: 12),
                    _buildDetailRow('Cancellation fee', '₹150'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Payment ID', transactionId),
                    const SizedBox(height: 12),
                    _buildDetailRow('Requested on', requestedOn),
                    const SizedBox(height: 12),
                    _buildDetailRow('Status', 'Cancellation Processing',
                        statusColor: Colors.orange.shade700),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAll(() => const user_Dashboard());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

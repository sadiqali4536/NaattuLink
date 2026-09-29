import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';

class BookingSuccessPage extends StatefulWidget {
  final String bookingId;
  final String serviceName;
  final DateTime date;
  final String timeSlot;
  final String serviceType;

  const BookingSuccessPage({
    Key? key,
    required this.bookingId,
    required this.serviceName,
    required this.date,
    required this.timeSlot,
    required this.serviceType,
  }) : super(key: key);

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasPlayedSound = false;

  @override
  void initState() {
    super.initState();
    _playSound();
  }

  Future<void> _playSound() async {
    if (_hasPlayedSound) return;
    _hasPlayedSound = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint("Error playing success sound: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lottie success animation
                Transform.scale(
                  scale: 1.8, // visually larger
                  child: Lottie.asset(
                    'assets/lotties/success_animation.json',
                    width: 250,
                    height: 250,
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                ),
                const Text(
                  "Booking Successful!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your booking ID is ${widget.bookingId}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildRow("Service", widget.serviceName),
                      const Divider(height: 24),
                      _buildRow("Service Type", widget.serviceType),
                      const Divider(height: 24),
                      _buildRow("Date",
                          DateFormat('dd MMM yyyy').format(widget.date)),
                      const Divider(height: 24),
                      _buildRow("Time", widget.timeSlot),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Future.delayed(Duration.zero, () {
                        Get.offAll(() => user_Dashboard());
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Back to Home",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'dart:typed_data';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/payment_ocr_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ServicePaymentPage extends StatefulWidget {
  final String bookingId;
  final double totalAmount;
  final String? customerName;
  final bool isCancellationFee;
  final String? cancellationReason;

  const ServicePaymentPage({
    Key? key,
    required this.bookingId,
    required this.totalAmount,
    this.customerName,
    this.isCancellationFee = false,
    this.cancellationReason,
  }) : super(key: key);

  @override
  State<ServicePaymentPage> createState() => _ServicePaymentPageState();
}

class _ServicePaymentPageState extends State<ServicePaymentPage> {
  static const MethodChannel _channel =
      MethodChannel('com.naattulink.upi/payment');
  final TextEditingController _paymentIdController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = false;
  bool _isFetchingUpi = true;
  bool _isExtractingOcr = false;
  String? _platformUpi;
  String? _qrGeneratedTimeStr; // Stores formatted time for UI return

  String? _paymentAttemptId;
  DateTime? _qrGeneratedAt;
  DateTime? _qrExpiresAt;
  bool _isExpired = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUpiDetails();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_qrExpiresAt != null) {
        if (DateTime.now().isAfter(_qrExpiresAt!)) {
          setState(() {
            _isExpired = true;
          });
          _timer?.cancel();
        } else {
          setState(() {}); // Trigger rebuild to update countdown text
        }
      }
    });
  }

  Future<void> _generatePaymentAttempt() async {
    setState(() {
      _isFetchingUpi = true;
      _isExpired = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final newAttemptId =
          "NL-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 5));

      String paidUserName = user?.displayName ?? "NaattuLink User";
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          paidUserName = userDoc.data()?['username'] ?? paidUserName;
        }
      }

      await FirebaseFirestore.instance
          .collection('payment_attempts')
          .doc(newAttemptId)
          .set({
        "paymentAttemptId": newAttemptId,
        "bookingId": widget.bookingId,
        "paymentType": "service",
        "userId": user?.uid,
        "userName": paidUserName,
        "phoneNumber": user?.phoneNumber,
        "amount": widget.totalAmount,
        "qrGeneratedAt": FieldValue.serverTimestamp(),
        "qrStatus": "Active",
        "paymentStatus": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        _paymentAttemptId = newAttemptId;
        _qrGeneratedAt = now;
        _qrExpiresAt = expiresAt;
        _qrGeneratedTimeStr = DateFormat('dd MMM, h:mm a').format(now);
      });
      _startTimer();
    } catch (e) {
      debugPrint("Failed to generate payment attempt: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingUpi = false;
        });
      }
    }
  }

  Future<void> _fetchUpiDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get();

      String? upi;
      if (doc.exists && doc.data() != null) {
        upi = doc.data()!['platform_upi']?.toString();
      }

      if (mounted) {
        setState(() {
          _platformUpi = upi;
        });
        if (upi != null) {
          _generatePaymentAttempt();
        } else {
          setState(() {
            _isFetchingUpi = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch UPI: $e");
      if (mounted) {
        setState(() {
          _isFetchingUpi = false;
        });
      }
    }
  }

  Future<void> _submitPaymentId() async {
    final paymentId = _paymentIdController.text.trim();
    if (paymentId.isEmpty) {
      CherryToast.warning(
        title: const Text('Required',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Please enter your Transaction ID.'),
      ).show(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      String paidUserName = user?.displayName ?? "NaattuLink User";
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          paidUserName = userDoc.data()?['username'] ?? paidUserName;
        }
      }
      final now = DateTime.now();
      final formattedNow = DateFormat('dd MMM, h:mm a').format(now);
      final dateTimeStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

      final batch = FirebaseFirestore.instance.batch();

      final serviceBookingRef = FirebaseFirestore.instance
          .collection('service_bookings')
          .doc(widget.bookingId);
      if (widget.isCancellationFee) {
        batch.update(serviceBookingRef, {
          'cancellationRequested': true,
          'cancellationReason': widget.cancellationReason,
          'cancellationFee': 150,
          'cancellationPaymentId': paymentId,
          'cancellationPaymentStatus': 'Paid',
          'cancellationRequestedAt': FieldValue.serverTimestamp(),
          'cancellationStatus': 'Processing'
        });

        final paymentsRef = FirebaseFirestore.instance
            .collection('payments')
            .doc('CANCEL_${widget.bookingId}_$paymentId');
        batch.set(paymentsRef, {
          'bookingId': widget.bookingId,
          'transactionId': paymentId,
          'paymentId': paymentId,
          'paymentMode': 'UPI',
          'status': 'Paid',
          'amount': 150,
          'dateTime': dateTimeStr,
          'itemName': 'Cancellation Convenience Fee',
          'paymentType': 'ServiceCancellation',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(serviceBookingRef, {
          'paymentId': paymentId,
          'paymentStatus': 'Paid',
          'status': 'Paid',
          'paidUserName': paidUserName,
          'paymentSubmittedAt': FieldValue.serverTimestamp(),
        });

        final paymentsRef = FirebaseFirestore.instance
            .collection('payments')
            .doc(widget.bookingId);
        batch.set(paymentsRef, {
          'bookingId': widget.bookingId,
          'transactionId': paymentId,
          'paymentId': paymentId,
          'paymentMode': 'UPI',
          'status': 'Paid',
          'amount': '₹${widget.totalAmount.toInt()}',
          'dateTime': dateTimeStr,
          'itemName': 'Service',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (_paymentAttemptId != null) {
        final attemptRef = FirebaseFirestore.instance
            .collection('payment_attempts')
            .doc(_paymentAttemptId);
        batch.update(attemptRef, {
          'transactionId': paymentId,
          'paidUserName': paidUserName,
          'paymentStatus': 'Paid',
          'screenshotSubmittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      Get.back(result: {
        'paymentId': paymentId,
        'paidUserName': paidUserName,
        'paymentTime': formattedNow,
        'qrGeneratedTime': _qrGeneratedTimeStr ?? formattedNow,
      });
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('Failed to submit payment ID.'),
        ).show(context);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOcrUpload() async {
    setState(() {
      _isExtractingOcr = true;
    });

    final extractedId = await PaymentOcrService.extractTransactionId();

    setState(() {
      _isExtractingOcr = false;
    });

    if (extractedId != null && extractedId.isNotEmpty) {
      _paymentIdController.text = extractedId;
      if (mounted) {
        CherryToast.success(
          title: const Text('Success',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('Transaction ID extracted. Please verify.'),
        ).show(context);
      }
    } else {
      if (mounted) {
        CherryToast.warning(
          title: const Text('Not Found',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text(
              'Could not extract a valid Transaction ID. Please enter manually.'),
        ).show(context);
      }
    }
  }

  Future<void> _downloadQR() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        CherryToast.error(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('QR Code not ready yet.'),
        ).show(context);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final String fileName = 'NaattuLink_Payment_QR_${widget.bookingId}.png';
        await _channel.invokeMethod('saveImageToDownloads', {
          'bytes': pngBytes,
          'fileName': fileName,
        });

        if (mounted) {
          setState(() {
            _qrGeneratedTimeStr =
                DateFormat('dd MMM, h:mm a').format(DateTime.now());
          });
        }

        if (mounted) {
          CherryToast.success(
            title: const Text('Downloaded',
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text(
                'QR Code saved to Downloads/NaattuLink. You can now scan it from your UPI app.'),
          ).show(context);
        }
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.message}');
      if (mounted) {
        CherryToast.error(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Failed to save QR: ${e.message}'),
        ).show(context);
      }
    } catch (e) {
      debugPrint('Download QR Error: $e');
      if (mounted) {
        CherryToast.warning(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Failed to save QR code: $e'),
        ).show(context);
      }
    }
  }

  @override
  void dispose() {
    _paymentIdController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _upiString {
    if (_platformUpi == null || _paymentAttemptId == null) return "";
    final amount = widget.totalAmount.toStringAsFixed(2);
    // Standard UPI intent URI format for QRs with dynamic tr and tn
    return "upi://pay?pa=$_platformUpi&pn=NaattuLink&am=$amount&cu=INR&tr=$_paymentAttemptId&tn=${widget.bookingId}";
  }

  Widget _buildStepBadge(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2E5A),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isFetchingUpi
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Amount to Pay",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${widget.totalAmount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_platformUpi != null && _platformUpi!.isNotEmpty)
                          if (_isExpired)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.timer_off,
                                      color: Colors.red.shade400, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "This payment QR has expired.",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Generate a new QR to continue.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _generatePaymentAttempt,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F2E5A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text("Generate New QR",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                RepaintBoundary(
                                  key: _qrKey,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: QrImageView(
                                      data: _upiString,
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_qrExpiresAt != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer,
                                          size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Expires in: ${(_qrExpiresAt!.difference(DateTime.now()).inMinutes).toString().padLeft(2, '0')}:${(_qrExpiresAt!.difference(DateTime.now()).inSeconds % 60).toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        const SizedBox(height: 24),
                        if (!_isExpired)
                          ElevatedButton.icon(
                            onPressed: _downloadQR,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2E5A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.download, size: 20),
                            label: const Text(
                              "Download QR",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (!_isExpired) const SizedBox(height: 16),
                        if (!_isExpired)
                          const Text(
                            "Scan QR with any UPI App",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F2E5A),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Instructions Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "How to pay?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStepBadge(
                            "1", "Tap the 'Download QR' button above"),
                        _buildStepBadge(
                            "2", "Open your UPI App (GPay, PhonePe, etc.)"),
                        _buildStepBadge("3",
                            "Tap 'Scan QR' and select 'Upload from Gallery'"),
                        _buildStepBadge("4",
                            "Pay ₹${widget.totalAmount.toStringAsFixed(2)} to NaattuLink"),
                        _buildStepBadge("5",
                            "Take a screenshot of the Payment Success screen"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  const Text(
                    "After Payment is Complete",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isExtractingOcr)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text(
                            "Extracting Transaction ID...",
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _handleOcrUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F2E5A),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      icon: const Icon(Icons.document_scanner),
                      label: const Text(
                        "Upload Payment Success Screenshot",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    "Or Enter Transaction ID Manually",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paymentIdController,
                    decoration: InputDecoration(
                      hintText: "e.g., TXN123456789",
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPaymentId,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E5A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Submit Payment",
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
    );
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cherry_toast/cherry_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:naattulink/MVVM/utils/payment_verification/ocr/payment_ocr_service.dart';
import 'package:naattulink/MVVM/utils/payment_verification/models/payment_ocr_result.dart';
import 'package:naattulink/MVVM/utils/payment_verification/models/payment_validation_result.dart';
import 'package:naattulink/MVVM/utils/payment_verification/validator/payment_screenshot_validator.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/controller/payment_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;
  final AppLocationModel address;
  final bool isFromCart;

  const PaymentPage({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
    required this.address,
    this.isFromCart = false,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const MethodChannel _channel =
      MethodChannel('com.naattulink.upi/payment');

  late PaymentController controller;

  // Product payment options (fetched live from Firestore)
  Map<String, List<String>> _productPaymentOptions = {};
  bool _loadingOptions = true;

  // UPI / QR state
  bool _isFetchingUpi = false;
  bool _isExtractingOcr = false;
  bool _isSubmitting = false;
  String? _platformUpi;
  String? _paymentAttemptId;
  DateTime? _qrExpiresAt;
  bool _isExpired = false;
  Timer? _timer;
  String? _qrGeneratedTimeStr;
  final GlobalKey _qrKey = GlobalKey();
  final TextEditingController _transactionIdController =
      TextEditingController();
  PaymentOcrResult? _validatedOcrResult;
  PaymentValidationResult? _validatedPaymentResult;
  DateTime? _qrGeneratedAt;
  String? _qrNote;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PaymentController());
    _fetchProductPaymentOptions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transactionIdController.dispose();
    super.dispose();
  }

  // ─── Live product payment option fetch ───────────────────────────────────────

  Future<void> _fetchProductPaymentOptions() async {
    final Map<String, List<String>> result = {};
    final productIds = widget.cartItems.map((e) => e.productId).toSet();
    for (final pid in productIds) {
      if (pid.isEmpty) continue;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('store_products')
            .doc(pid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          final opts = data?['paymentOptions'];
          if (opts != null && opts is List && opts.isNotEmpty) {
            result[pid] = List<String>.from(opts);
          }
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _productPaymentOptions = result;
        _loadingOptions = false;
      });
    }
  }

  bool _isCodAvailable() {
    if (widget.cartItems.isEmpty) return true;
    return widget.cartItems.every((item) {
      final liveOpts = _productPaymentOptions[item.productId];
      if (liveOpts != null && liveOpts.isNotEmpty) {
        return liveOpts.contains('Cash on Delivery') ||
            liveOpts.contains('Cash On Delivery');
      }
      if (item.paymentOptions.isNotEmpty) {
        return item.paymentOptions.contains('Cash on Delivery') ||
            item.paymentOptions.contains('Cash On Delivery');
      }
      return item.isCashOnDelivery ?? true;
    });
  }

  bool _isOnlineAvailable() {
    if (widget.cartItems.isEmpty) return true;
    return widget.cartItems.every((item) {
      final liveOpts = _productPaymentOptions[item.productId];
      if (liveOpts != null && liveOpts.isNotEmpty) {
        return liveOpts.contains('Online Payment');
      }
      if (item.paymentOptions.isNotEmpty) {
        return item.paymentOptions.contains('Online Payment');
      }
      return item.isOnlinePayment ?? true;
    });
  }

  // ─── QR / UPI logic ──────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_qrExpiresAt != null) {
        if (DateTime.now().isAfter(_qrExpiresAt!)) {
          setState(() => _isExpired = true);
          _timer?.cancel();
        } else {
          setState(() {}); // rebuild for countdown
        }
      }
    });
  }

  Future<void> _fetchUpiAndGenerateQr() async {
    setState(() => _isFetchingUpi = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get();
      String? upi;
      if (doc.exists && doc.data() != null) {
        final feeStatus =
            doc.data()!['PlatformFeeStatus']?.toString().toLowerCase();
        if (feeStatus == 'inactive') {
          if (widget.cartItems.isNotEmpty) {
            String? sellerId = widget.cartItems.first.sellerId;
            if (sellerId == null || sellerId.isEmpty) {
              final prodDoc = await FirebaseFirestore.instance
                  .collection('store_products')
                  .doc(widget.cartItems.first.productId)
                  .get();
              if (prodDoc.exists && prodDoc.data() != null) {
                sellerId = prodDoc.data()!['ownerId']?.toString() ??
                    prodDoc.data()!['sellerId']?.toString() ??
                    prodDoc.data()!['storeId']?.toString();
              }
            }

            if (sellerId != null && sellerId.isNotEmpty) {
              final sellerDoc = await FirebaseFirestore.instance
                  .collection('sellers')
                  .doc(sellerId)
                  .get();
              if (sellerDoc.exists && sellerDoc.data() != null) {
                upi = sellerDoc.data()!['upiId']?.toString();
              }
            }
          }
        } else {
          upi = doc.data()!['platform_upi']?.toString();
        }
      }
      if (mounted) {
        setState(() => _platformUpi = upi);
        if (upi != null) {
          await _generatePaymentAttempt();
        } else {
          setState(() => _isFetchingUpi = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingUpi = false);
    }
  }

  Future<void> _generatePaymentAttempt() async {
    setState(() {
      _isFetchingUpi = true;
      _isExpired = false;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final newAttemptId =
          'NL-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 5));
      final noteTimeFormatter = DateFormat('dd-MM-yyyy hh:mm:ss a');
      final currentQrNote =
          'NaattuLink_online_order | ${noteTimeFormatter.format(now)}';

      String paidUserName = user?.displayName ?? 'NaattuLink User';
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          paidUserName =
              (userDoc.data() as Map<String, dynamic>?)?['username'] ??
                  paidUserName;
        }
      }

      final orderId =
          'NL-ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      await FirebaseFirestore.instance
          .collection('payment_attempts')
          .doc(newAttemptId)
          .set({
        'paymentAttemptId': newAttemptId,
        'orderId': orderId,
        'paymentType': 'store_order',
        'userId': user?.uid,
        'userName': paidUserName,
        'phoneNumber': user?.phoneNumber,
        'amount': widget.totalAmount,
        'qrGeneratedAt': Timestamp.fromDate(now),
        'qrNote': currentQrNote,
        'expectedUpiId':
            _platformUpi, // Save the expected UPI ID for validation
        'qrStatus': 'Active',
        'paymentStatus': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _paymentAttemptId = newAttemptId;
        _qrExpiresAt = expiresAt;
        _qrGeneratedAt = now;
        _qrNote = currentQrNote;
        _qrGeneratedTimeStr = DateFormat('dd MMM, h:mm a').format(now);
      });
      _startTimer();
    } catch (e) {
      debugPrint('Failed to generate payment attempt: $e');
    } finally {
      if (mounted) setState(() => _isFetchingUpi = false);
    }
  }

  String get _upiString {
    if (_platformUpi == null || _paymentAttemptId == null) return '';
    final amount = widget.totalAmount.toStringAsFixed(2);
    final note = Uri.encodeComponent(_qrNote ?? 'NaattuLink_Order');
    return 'upi://pay?pa=$_platformUpi&pn=NaattuLink&am=$amount&cu=INR&tr=$_paymentAttemptId&tn=$note';
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
        await _channel.invokeMethod('saveImageToDownloads', {
          'bytes': pngBytes,
          'fileName':
              'NaattuLink_Payment_QR_${_paymentAttemptId ?? 'order'}.png',
        });
        if (mounted) {
          CherryToast.success(
            title: const Text('Downloaded',
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text(
                'QR Code saved to Downloads/NaattuLink. Scan it from your UPI app.'),
          ).show(context);
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Failed to save QR: ${e.message}'),
        ).show(context);
      }
    } catch (e) {
      if (mounted) {
        CherryToast.warning(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Failed to save QR code: $e'),
        ).show(context);
      }
    }
  }

  Future<void> _handleOcrUpload() async {
    setState(() {
      _isExtractingOcr = true;
      _validatedOcrResult = null;
      _validatedPaymentResult = null;
    });
    final ocrResult = await PaymentOcrService.extractPaymentReceipt(
      expectedAmount: widget.totalAmount,
      expectedUpiId: _platformUpi,
    );
    setState(() => _isExtractingOcr = false);

    if (ocrResult == null) return;

    if (_qrGeneratedAt == null || _qrExpiresAt == null) {
      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Payment session has expired or is invalid.'),
      ).show(context);
      return;
    }

    final validationResult = PaymentScreenshotValidator.validate(
      ocrResult: ocrResult,
      expectedAmount: widget.totalAmount,
      qrGeneratedAt: _qrGeneratedAt!,
      qrExpiresAt: _qrExpiresAt!,
      expectedUpiId: _platformUpi,
    );

    if (validationResult.status != PaymentVerificationStatus.valid) {
      setState(() {
        _validatedOcrResult = null;
        _validatedPaymentResult = validationResult;
      });

      String errorMsg =
          'This receipt appears to be invalid or incomplete. Please upload the correct payment screenshot.';
      if (validationResult.reasons
          .contains(PaymentValidationReason.amountMismatch)) {
        errorMsg = 'The amount on the receipt does not match the order total.';
      } else if (validationResult.reasons
          .contains(PaymentValidationReason.paymentBeforeQrCreation)) {
        errorMsg =
            'This payment was made before the QR was generated. It looks like an old payment.';
      }

      CherryToast.error(
        title: const Text('Invalid Receipt',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(errorMsg),
      ).show(context);
      return;
    }

    setState(() {
      _validatedOcrResult = ocrResult;
      _validatedPaymentResult = validationResult;
    });

    if (ocrResult.transactionIds.isNotEmpty) {
      _transactionIdController.text = ocrResult.transactionIds.first;
    } else if (ocrResult.referenceIds.isNotEmpty) {
      _transactionIdController.text = ocrResult.referenceIds.first;
    }

    CherryToast.success(
      title:
          const Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
      description: const Text('Payment verified! Please confirm to proceed.'),
    ).show(context);
  }

  Future<void> _submitUpiPayment({
    required PaymentOcrResult ocrResult,
    required PaymentValidationResult validationResult,
  }) async {
    if (validationResult.status != PaymentVerificationStatus.valid) {
      return;
    }

    final txnId = _transactionIdController.text.trim();
    if (txnId.isEmpty) {
      CherryToast.warning(
        title: const Text('Required',
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Please enter your Transaction ID.'),
      ).show(context);
      return;
    }

    if (_paymentAttemptId == null || _qrGeneratedAt == null) {
      CherryToast.error(
        title:
            const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('No active payment session.'),
      ).show(context);
      return;
    }

    final r = ocrResult;

    // --- 3. PRINT OCR LOGS ---
    debugPrint('\n=============================================');
    debugPrint('          OCR EXTRACTED RESULT               ');
    debugPrint('=============================================');
    debugPrint('[OCR] Extracted Amount        : ₹${r.amount}');
    debugPrint('[OCR] Extracted Date Time     : ${r.paymentDateTime}');
    debugPrint('[OCR] Extracted Receiver UPI  : ${r.receiverUpi}');
    debugPrint('[OCR] Has Success Indicator   : ${r.hasSuccessIndicator}');
    debugPrint('[USER] Entered Txn ID         : $txnId');
    debugPrint('---------------------------------------------');
    debugPrint('[EXPECTED] Order Amount       : ₹${widget.totalAmount}');
    debugPrint('[EXPECTED] QR Generated At    : ${_qrGeneratedAt}');
    debugPrint('[EXPECTED] Receiver UPI       : $_platformUpi');
    debugPrint('=============================================\n');

    // Validation is already handled in _handleOcrUpload via PaymentScreenshotValidator

    // --- 10. ALL CHECKS PASSED ---
    setState(() => _isSubmitting = true);
    try {
      // Duplicate Transaction ID Check
      final existingPayment = await FirebaseFirestore.instance
          .collection('payments')
          .doc(txnId)
          .get();

      if (existingPayment.exists) {
        CherryToast.error(
          title: const Text('Duplicate Transaction',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('This transaction ID has already been used.'),
        ).show(context);
        setState(() => _isSubmitting = false);
        return;
      }

      controller.selectedPaymentMethod.value = PaymentMethod.upi;
      controller.updateTransactionId(txnId);

      if (_paymentAttemptId != null) {
        await FirebaseFirestore.instance
            .collection('payment_attempts')
            .doc(_paymentAttemptId)
            .update({
          'transactionId': txnId,
          'paymentStatus': 'Paid',
          'screenshotSubmittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final paymentDocData = {
        'transactionId': txnId,
        'amount': widget.totalAmount,
        'expectedAmount': widget.totalAmount,
        'paymentAttemptId': _paymentAttemptId,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      };

      paymentDocData.addAll({
        if (r.receiverUpi != null) 'receiverUpi': r.receiverUpi!,
        if (r.paymentDateTime != null)
          'transactionDateTime': r.paymentDateTime!.toIso8601String(),
        'hasSuccessIndicator': r.hasSuccessIndicator,
      });

      final receiptBuffer = StringBuffer();
      receiptBuffer.writeln(
          '# NAATTULINK\n\n### Payment Receipt\n\n**PAYMENT COMPLETED**\n\n---');
      receiptBuffer.writeln(
          '\n### Payment Summary\n\n**Amount Paid**\n\n# ₹${widget.totalAmount.toStringAsFixed(2)}');
      if (txnId.isNotEmpty)
        receiptBuffer.writeln('\n**UPI Transaction ID**\n$txnId');
      if (r.paymentDateTime != null)
        receiptBuffer.writeln('\n**Date & Time**\n${r.paymentDateTime}');
      receiptBuffer.writeln('\n---');

      if (r.receiverUpi != null) {
        receiptBuffer.writeln('\n### Paid To');
        receiptBuffer.writeln('\n**Receiver UPI**\n${r.receiverUpi}');
        receiptBuffer.writeln('\n---');
      }

      receiptBuffer.writeln('\n### Transaction Details');
      receiptBuffer.writeln('\n**Status**\n✓ Completed');
      receiptBuffer.writeln('\n---');

      receiptBuffer.writeln(
          '\n**Payment successfully completed through UPI**\n\nPowered by Unified Payments Interface (UPI)\n\n**NaattuLink**\nYour City, One App');

      paymentDocData['formattedReceipt'] = receiptBuffer.toString();

      await FirebaseFirestore.instance.collection('payments').doc(txnId).set(
          paymentDocData); // Removed merge: true to avoid overwriting blindly if logic somehow gets here

      final Map<String, dynamic> ocrData = {
        'ocrAmountExtracted': r.amount,
        'ocrReceiverUpi': r.receiverUpi,
        'ocrPaymentDateTime': r.paymentDateTime?.toIso8601String(),
        'ocrHasSuccessIndicator': r.hasSuccessIndicator,
        'ocrConfidence': r.confidence,
        'ocrReferenceIds': r.referenceIds,
        'ocrTransactionIds': r.transactionIds,
        'isOcrVerified': true,
      };

      controller.placeOrder(
        cartItems: widget.cartItems,
        totalAmount: widget.totalAmount,
        address: widget.address,
        isFromCart: widget.isFromCart,
        formattedReceipt: receiptBuffer.toString(),
        ocrData: ocrData,
      );
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          description:
              const Text('Failed to submit payment. Please try again.'),
        ).show(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingOptions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const AppBackButton(),
          title: const Text('Payments',
              style: TextStyle(
                  color: Color(0xFF0F2E5A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isCodAvailable = _isCodAvailable();
    final bool isOnlineAvailable = _isOnlineAvailable();

    // Auto-select first available method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isCodAvailable &&
          controller.selectedPaymentMethod.value ==
              PaymentMethod.cashOnDelivery) {
        if (isOnlineAvailable) {
          controller.selectPaymentMethod(PaymentMethod.upi);
        }
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_platformUpi != null) {
          setState(() {
            _platformUpi = null;
            _timer?.cancel();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: AppBackButton(
            onPressed: _platformUpi != null
                ? () {
                    setState(() {
                      _platformUpi = null;
                      _timer?.cancel();
                    });
                  }
                : null,
          ),
          title: const Text(
            'Payments',
            style: TextStyle(
              color: Color(0xFF0F2E5A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Obx(() {
          final isUpi =
              controller.selectedPaymentMethod.value == PaymentMethod.upi;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Amount card ──
                if (_platformUpi == null) ...[
                  _buildTotalAmountCard(),
                  const SizedBox(height: 24),
                ],

                // ── Payment method selection ──
                if (_platformUpi == null) ...[
                  if (isCodAvailable || isOnlineAvailable) ...[
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isCodAvailable) ...[
                    _buildPaymentOption(
                      title: 'Cash on Delivery',
                      method: PaymentMethod.cashOnDelivery,
                      icon: Icons.local_shipping,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isOnlineAvailable) ...[
                    _buildPaymentOption(
                      title: 'Online Payment (UPI)',
                      method: PaymentMethod.upi,
                      icon: Icons.currency_rupee,
                    ),
                  ],
                  if (!isCodAvailable && !isOnlineAvailable)
                    const Text(
                      'No payment methods available for the selected items.',
                      style: TextStyle(color: Colors.red),
                    ),
                ],

                // ── UPI section (full QR flow) ──
                if (isUpi) ...[
                  if (_platformUpi == null) const SizedBox(height: 24),
                  _buildUpiQrSection(),
                ],
              ],
            ),
          );
        }),
        bottomNavigationBar: Obx(() => _buildBottomBar()),
      ),
    );
  }

  // ─── Total amount card ────────────────────────────────────────────────────────

  Widget _buildTotalAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₹${widget.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment method tile ──────────────────────────────────────────────────────

  Widget _buildPaymentOption({
    required String title,
    required PaymentMethod method,
    required IconData icon,
  }) {
    final isSelected = controller.selectedPaymentMethod.value == method;
    return GestureDetector(
      onTap: () => controller.selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF0FF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2956D3) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2956D3)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: const Color(0xFF0F2E5A),
                ),
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: controller.selectedPaymentMethod.value,
              onChanged: (value) {
                if (value != null) controller.selectPaymentMethod(value);
              },
              activeColor: const Color(0xFF2956D3),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Full QR UPI section ──────────────────────────────────────────────────────

  Widget _buildUpiQrSection() {
    if (_isFetchingUpi) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_platformUpi == null) {
      // Not yet loaded — show the "Generate QR" button
      return Center(
        child: ElevatedButton.icon(
          onPressed: _fetchUpiAndGenerateQr,
          icon: const Icon(Icons.qr_code),
          label: const Text('Generate Payment QR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2E5A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Column(
      children: [
        // QR card
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
                'Scan to Pay',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A)),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${widget.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A)),
              ),
              const SizedBox(height: 20),
              if (_isExpired)
                _buildExpiredQr()
              else if (_paymentAttemptId != null)
                _buildActiveQr()
              else
                ElevatedButton.icon(
                  onPressed: _fetchUpiAndGenerateQr,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    foregroundColor: Colors.white,
                  ),
                ),

              // Download button
              if (!_isExpired && _paymentAttemptId != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _downloadQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Download QR',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text('Scan QR with any UPI App',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2E5A))),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // How to pay instructions
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
              const Text('How to pay?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A))),
              const SizedBox(height: 16),
              _buildStepBadge('1', "Tap 'Download QR' button above"),
              _buildStepBadge('2', 'Open your UPI App (GPay, PhonePe, etc.)'),
              _buildStepBadge(
                  '3', "Tap 'Scan QR' and select 'Upload from Gallery'"),
              _buildStepBadge('4',
                  'Pay ₹${widget.totalAmount.toStringAsFixed(2)} to NaattuLink'),
              _buildStepBadge(
                  '5', 'Take a screenshot of the Payment Success screen'),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),

        // After payment section
        const Text('After Payment is Complete',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 16),

        if (_validatedOcrResult != null &&
            _validatedPaymentResult?.status ==
                PaymentVerificationStatus.valid) ...[
          _buildPaymentReceiptUI(),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _validatedOcrResult = null;
                  _validatedPaymentResult = null;
                  _transactionIdController.clear();
                });
              },
              icon: const Icon(Icons.refresh, color: Colors.red),
              label: const Text('Scan Another Receipt or Enter Manually',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ] else ...[
          if (_isExtractingOcr)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Extracting Transaction Details...',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w600)),
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
              label: const Text('Upload Payment Success Screenshot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 24),
          const Text('Or Enter Transaction ID Manually',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 12),
          TextField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              hintText: 'e.g., TXN123456789',
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_isSubmitting ||
                    _validatedOcrResult == null ||
                    _validatedPaymentResult == null ||
                    _validatedPaymentResult!.status !=
                        PaymentVerificationStatus.valid)
                ? null
                : () => _submitUpiPayment(
                      ocrResult: _validatedOcrResult!,
                      validationResult: _validatedPaymentResult!,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2E5A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Payment',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActiveQr() {
    return Column(
      children: [
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
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
              const Icon(Icons.timer, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'Expires in: ${(_qrExpiresAt!.difference(DateTime.now()).inMinutes).toString().padLeft(2, '0')}:${(_qrExpiresAt!.difference(DateTime.now()).inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExpiredQr() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_off, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          const Text('This payment QR has expired.',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Generate a new QR to continue.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generatePaymentAttempt,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2E5A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Generate New QR',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: Color(0xFF0F2E5A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Receipt UI Helpers ──────────────────────────────────────────────────────

  Widget _buildPaymentReceiptUI() {
    final r = _validatedOcrResult!;
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F2E5A),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
              ),
              width: double.infinity,
              child: const Column(
                children: [
                  Text('NAATTULINK',
                      style: TextStyle(
                          color: Color(0xFFF5B400),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 2)),
                  SizedBox(height: 4),
                  Text('Payment Receipt',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              )),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 8),
                        Text('Payment Completed',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('₹${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A))),
                    const SizedBox(height: 24),
                    _buildReceiptCard('Payment Summary', [
                      if (r.transactionIds.isNotEmpty)
                        _buildReceiptRow(
                            'Transaction ID', r.transactionIds.first)
                      else if (r.referenceIds.isNotEmpty)
                        _buildReceiptRow('Reference ID', r.referenceIds.first),
                      if (r.paymentDateTime != null)
                        _buildReceiptRow(
                            'Date & Time',
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(r.paymentDateTime!)),
                    ]),
                    if (r.receiverUpi != null) ...[
                      const SizedBox(height: 16),
                      _buildReceiptCard('Paid To', [
                        _buildReceiptRow('Receiver UPI', r.receiverUpi!),
                      ]),
                    ],
                    const SizedBox(height: 16),
                    _buildReceiptCard('Transaction Details', [
                      if (r.hasSuccessIndicator)
                        _buildReceiptRow('Status', '✓ Completed'),
                    ]),
                    const SizedBox(height: 24),
                    const Text('Payment successfully completed through UPI',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    const Text('Powered by Unified Payments Interface (UPI)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('NaattuLink — Your City, One App',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A)),
                        textAlign: TextAlign.center),
                  ]))
        ]));
  }

  Widget _buildReceiptCard(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F2E5A))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  // ─── Bottom bar (COD only) ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isUpi = controller.selectedPaymentMethod.value == PaymentMethod.upi;
    final isPlacingOrder = controller.isPlacingOrder.value;

    // For UPI, submission is handled by the inline "Submit Payment" button
    if (isUpi) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isPlacingOrder
              ? null
              : () {
                  controller.placeOrder(
                    cartItems: widget.cartItems,
                    totalAmount: widget.totalAmount,
                    address: widget.address,
                    isFromCart: widget.isFromCart,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isPlacingOrder ? Colors.grey[400] : const Color(0xFF2956D3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isPlacingOrder
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Place Order',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}

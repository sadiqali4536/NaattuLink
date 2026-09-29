import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/utils/stock_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:naattulink/MVVM/controller/seller/seller_dashboard_controller.dart';

const MethodChannel _slipChannel = MethodChannel('com.naattulink.upi/payment');

class SellerOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const SellerOrderDetailsScreen({super.key, required this.orderData});

  @override
  State<SellerOrderDetailsScreen> createState() =>
      _SellerOrderDetailsScreenState();
}

class _SellerOrderDetailsScreenState extends State<SellerOrderDetailsScreen> {
  late String currentStatus;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    String rawStatus = (widget.orderData['status'] ?? 'pending').toLowerCase();
    switch (rawStatus) {
      case 'pending_verification':
        currentStatus = 'Pending Verification';
        break;
      case 'pending':
        currentStatus = 'Pending';
        break;
      case 'processing':
        currentStatus = 'Processing';
        break;
      case 'shipped':
      case 'dispatched':
        currentStatus = 'Dispatched';
        break;
      case 'cancelled':
        currentStatus = 'Cancelled';
        break;
      case 'rejected':
        currentStatus = 'Rejected';
        break;
      default:
        currentStatus = rawStatus.isNotEmpty
            ? rawStatus[0].toUpperCase() + rawStatus.substring(1)
            : 'Pending';
    }
  }

  void _copyOrderId() {
    Clipboard.setData(
        ClipboardData(text: widget.orderData['orderId'] ?? '#NL1024'));
    toastSuccess("Order ID copied");
  }

  void _showReceiptDialog(String receipt) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0857A0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Payment Receipt",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Receipt content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      receipt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF172033),
                        height: 1.6,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              // Copy button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: receipt));
                      toastSuccess("Receipt copied");
                    },
                    icon: const Icon(Icons.copy, size: 15),
                    label: const Text("Copy Receipt"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0857A0),
                      side: const BorderSide(color: Color(0xFF0857A0)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndPrintPackagingSlip() async {
    setState(() {
      _isDownloadingPdf = true;
    });

    try {
      final order = widget.orderData;
      final String orderId = order['orderId'] ?? 'N/A';
      // Load Unicode-capable fonts (Noto Sans supports all characters)
      final pw.Font fontRegular = await PdfGoogleFonts.notoSansRegular();
      final pw.Font fontBold = await PdfGoogleFonts.notoSansBold();
      final String customerName = order['customerName'] ?? 'N/A';
      final String customerPhone = order['customerPhone'] ?? '';
      final String customerAltPhone = order['customerAltPhone'] ?? '';
      final String customerAddress = order['customerLocation'] ?? 'N/A';
      final String paymentMethod =
          (order['paymentMethod'] ?? 'N/A').toString().toUpperCase();
      final String paymentStatus = order['paymentStatus'] ?? 'N/A';
      final String transactionId = order['transactionId'] ?? '';
      final String status = order['status'] ?? 'N/A';
      final num subtotal =
          num.tryParse(order['subtotal']?.toString() ?? '0') ?? 0;
      final List items = order['items'] is List ? order['items'] : [];
      final String now =
          DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(4 * 72.0, 6 * 72.0,
              marginAll: 10), // 4x6 inches
          build: (pw.Context ctx) {
            final isCod =
                paymentMethod.contains('COD') || paymentMethod.contains('CASH');
            final topText = isCod
                ? 'COD Collect amount : Rs. ${subtotal.toStringAsFixed(2)}'
                : 'PREPAID : Rs. ${subtotal.toStringAsFixed(2)}';

            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.grey300,
                    child: pw.Text(
                      topText,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),

                  // Delivery Address & QR
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Address (Left)
                      pw.Expanded(
                        flex: 6,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                  color: PdfColors.black, width: 0.5),
                              bottom: pw.BorderSide(
                                  color: PdfColors.black, width: 0.5),
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('DELIVERY ADDRESS:',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8)),
                              pw.Text(customerName,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9)),
                              pw.Text(customerAddress,
                                  style: const pw.TextStyle(fontSize: 8)),
                              if (customerPhone.isNotEmpty)
                                pw.Text('Ph: $customerPhone',
                                    style: const pw.TextStyle(fontSize: 8)),
                              if (customerAltPhone.isNotEmpty)
                                pw.Text('Alt: $customerAltPhone',
                                    style: const pw.TextStyle(fontSize: 8)),
                              pw.SizedBox(height: 4),
                              pw.Text('SURFACE',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 2)),
                            ],
                          ),
                        ),
                      ),
                      // QR Code (Right)
                      pw.Expanded(
                        flex: 4,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.black, width: 0.5),
                            ),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: orderId,
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Courier Info
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.black, width: 0.5)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Courier Name: NaattuLink Logistics',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8)),
                            pw.Text('AWB No: $orderId',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Date: ${now.split(',')[0]}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sold By
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.black, width: 0.5)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Sold By: NaattuLink Seller',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 8)),
                        pw.Text('Registered Address',
                            style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),

                  // Products Table
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.black, width: 0.5)),
                    ),
                    child: pw.Table(
                      border: pw.TableBorder.symmetric(
                          inside: const pw.BorderSide(
                              color: PdfColors.black, width: 0.5)),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(5),
                        1: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text('Product',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text('Qty',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8),
                                    textAlign: pw.TextAlign.center)),
                          ],
                        ),
                        ...items.map((item) {
                          final name = item['name']?.toString() ?? 'Product';
                          final qty =
                              num.tryParse(item['qty']?.toString() ?? '1') ?? 1;
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(2),
                                  child: pw.Text(name,
                                      style: const pw.TextStyle(fontSize: 8))),
                              pw.Padding(
                                  padding: const pw.EdgeInsets.all(2),
                                  child: pw.Text('$qty',
                                      style: const pw.TextStyle(fontSize: 8),
                                      textAlign: pw.TextAlign.center)),
                            ],
                          );
                        }).toList(),
                        pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text('Total',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(2),
                                child: pw.Text('${items.length}',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8),
                                    textAlign: pw.TextAlign.center)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Section (Tracking and Barcode)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            color: PdfColors.black,
                            child: pw.Text('Handover to NaattuLink Logistics',
                                style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8)),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Tracking ID: $orderId',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.SizedBox(height: 6),
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.code128(),
                            data: orderId,
                            width: double.infinity,
                            height: 40,
                            drawText: false,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text('Order ID: $orderId',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          pw.Spacer(),
                          pw.Align(
                            alignment: pw.Alignment.bottomRight,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text('Ordered Through',
                                    style: const pw.TextStyle(fontSize: 6)),
                                pw.Text('NaattuLink',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10,
                                        fontStyle: pw.FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      await _slipChannel.invokeMethod('savePdfToDownloads', {
        'bytes': pdfBytes,
        'fileName': 'PackagingSlip_$orderId.pdf',
      });
      toastSuccess('Packaging slip saved to Downloads/NaattuLink');
    } on PlatformException catch (e) {
      toastError('Failed to save slip: ${e.message}');
    } catch (e) {
      toastError('Failed to save slip: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172033)),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Details",
              style: TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Row(
              children: [
                Text(
                  widget.orderData['orderId'] ?? "#NL1024",
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _copyOrderId,
                  child: const Icon(Icons.copy,
                      size: 12, color: Color(0xFF667085)),
                )
              ],
            ),
          ],
        ),
        actions: [
          if (currentStatus != 'Cancelled' &&
              currentStatus != 'Rejected' &&
              currentStatus != 'Dispatched')
            _isDownloadingPdf
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF172033)),
                    ),
                  )
                : IconButton(
                    tooltip: 'Download Packaging Slip',
                    icon: const Icon(Icons.download_outlined,
                        color: Color(0xFF172033)),
                    onPressed: _generateAndPrintPackagingSlip,
                  ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(),
                    if (widget.orderData['Refuned']?.toString() == '1' ||
                        widget.orderData['Refuned']?.toString().toLowerCase() ==
                            'true' ||
                        widget.orderData['Refuned'] == true ||
                        widget.orderData['Refuned'] == 1)
                      _buildRefundStatusBanner(),
                    const SizedBox(height: 16),
                    _buildCustomerDetails(),
                    const SizedBox(height: 16),
                    _buildOrderedItems(),
                    const SizedBox(height: 16),
                    _buildPaymentSummary(),
                    const SizedBox(height: 16),
                    _buildOrderTimeline(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundStatusBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Refund Processed Successfully",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "The refund for this order has been marked as completed.",
                  style: TextStyle(
                    color: Colors.green.shade600,
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

  Widget _buildStatusBanner() {
    final bool isDispatched = currentStatus == 'Dispatched';
    final bool isPending =
        currentStatus == 'Pending' || currentStatus == 'Pending Verification';
    final bool isCancelled = currentStatus == 'Cancelled';
    final bool isRejected = currentStatus == 'Rejected';

    final Color bgColor = isDispatched
        ? const Color(0xFFDCFCE7)
        : isPending
            ? Colors.orange.withOpacity(0.15)
            : (isCancelled || isRejected)
                ? Colors.red.withOpacity(0.15)
                : const Color(0xFFEAF3FF);

    final Color textColor = isDispatched
        ? const Color(0xFF16A34A)
        : isPending
            ? Colors.orange.shade800
            : (isCancelled || isRejected)
                ? Colors.red.shade800
                : const Color(0xFF0857A0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
              (isCancelled || isRejected)
                  ? Icons.cancel
                  : isDispatched
                      ? Icons.check_circle
                      : Icons.circle,
              size: (isDispatched || isCancelled || isRejected) ? 18 : 10,
              color: textColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentStatus == 'Pending' ? "Order Confirmed" : currentStatus,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 2),
                Text(
                  "Action required",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (isCancelled || isRejected) ...[
                const SizedBox(height: 6),
                Text(
                  isCancelled
                      ? "User cancelled the order"
                      : "Seller rejected the order",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.orderData['cancellationReason'] != null &&
                    widget.orderData['cancellationReason']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${widget.orderData['cancellationReason']}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (widget.orderData['cancellationComment'] != null &&
                    widget.orderData['cancellationComment']
                        .toString()
                        .isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Comment: ${widget.orderData['cancellationComment']}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CUSTOMER DETAILS",
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.orderData['customerName'] ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFF667085)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.orderData['customerLocation'] ?? "Kozhikode",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Handle phone call
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone,
                              size: 14, color: Color(0xFF0857A0)),
                          const SizedBox(width: 6),
                          Text(
                            widget.orderData['customerPhone'] ??
                                "+91 98*** **123",
                            style: const TextStyle(
                              color: Color(0xFF0857A0),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.orderData['customerAltPhone'] != null &&
                      widget.orderData['customerAltPhone']
                          .toString()
                          .isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // Handle alt phone call
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              widget.orderData['customerAltPhone'],
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return "0";
    final num val = num.tryParse(amount.toString()) ?? 0;
    return val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  Widget _buildOrderedItems() {
    final List items = widget.orderData['items'] ??
        [
          {
            'name': 'Farm Fresh Cow Milk',
            'qty': 2,
            'price': 60,
            'image': null,
          },
          {
            'name': 'Organic Mixed Veggies',
            'qty': 1,
            'price': 120,
            'image': null,
          }
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Items",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172033),
              ),
            ),
            Text(
              "${items.length} items",
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.map((item) {
              final int idx = items.indexOf(item);
              final isLast = idx == items.length - 1;
              final num qty = num.tryParse(item['qty'].toString()) ?? 1;
              final num price = num.tryParse(item['price'].toString()) ?? 0;
              final num lineTotal = qty * price;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: item['image'] != null &&
                                item['image'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(item['image'].toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(Icons.broken_image_outlined,
                                            color: Color(0xFF94A3B8))),
                              )
                            : const Icon(Icons.image_outlined,
                                color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 12),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF172033),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${item['qty']} × ₹${_formatAmount(item['price'])}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Total
                      Text(
                        "₹${_formatAmount(lineTotal)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final num subtotal =
        num.tryParse(widget.orderData['subtotal']?.toString() ?? '240') ?? 240;
    final num deliveryFee =
        num.tryParse(widget.orderData['deliveryFee']?.toString() ?? '40') ?? 40;
    final num total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal",
                  style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
              Text("₹${_formatAmount(subtotal)}",
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF667085))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Delivery Fee",
                  style: TextStyle(fontSize: 13, color: Color(0xFF667085))),
              Text("₹${_formatAmount(deliveryFee)}",
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF667085))),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033)),
              ),
              Text(
                "₹${_formatAmount(total)}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0857A0)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFB9D5FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.orderData['paymentMethod']
                                    ?.toString()
                                    .toLowerCase() ==
                                'upi'
                            ? Icons.currency_rupee
                            : Icons.money,
                        size: 12,
                        color: const Color(0xFF0857A0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.orderData['paymentMethod']
                                    ?.toString()
                                    .toLowerCase() ==
                                'upi'
                            ? 'UPI'
                            : (widget.orderData['paymentMethod'] ??
                                'Cash on Delivery'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0857A0),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.orderData['paymentMethod']
                            ?.toString()
                            .toLowerCase() ==
                        'upi' &&
                    (widget.orderData['paymentStatus']
                                ?.toString()
                                .toLowerCase() ==
                            'completed' ||
                        widget.orderData['paymentStatus']
                                ?.toString()
                                .toLowerCase() ==
                            'paid' ||
                        widget.orderData['paymentStatus']
                                ?.toString()
                                .toLowerCase() ==
                            'success')) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'PAID',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.orderData['transactionId'] != null &&
              widget.orderData['transactionId'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("🆔 ", style: TextStyle(fontSize: 12)),
                      const Text(
                        "Transaction ID: ",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085)),
                      ),
                      Expanded(
                        child: Text(
                          '${widget.orderData['transactionId']}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.orderData['ocrPaymentDateTime'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: Color(0xFF667085)),
                        const SizedBox(width: 5),
                        Text(
                          () {
                            try {
                              final dt = DateTime.parse(
                                  widget.orderData['ocrPaymentDateTime']);
                              return DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(dt.toLocal());
                            } catch (_) {
                              return widget.orderData['ocrPaymentDateTime']
                                  .toString();
                            }
                          }(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.orderData['formattedReceipt'] != null &&
                      widget.orderData['formattedReceipt']
                          .toString()
                          .isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showReceiptDialog(
                          widget.orderData['formattedReceipt'].toString()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0857A0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 13, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              "View Payment Receipt",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Timeline",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentStatus == 'Cancelled' ||
                  currentStatus == 'Rejected') ...[
                _buildTimelineStep(
                  title: "Order Confirmed",
                  subtitle: "Order placed successfully",
                  isCompleted: true,
                  isLast: false,
                ),
                _buildTimelineStep(
                  title: currentStatus == 'Cancelled'
                      ? "Order Cancelled"
                      : "Order Rejected",
                  subtitle: () {
                    final paymentMethod =
                        (widget.orderData['paymentMethod'] ?? '')
                            .toString()
                            .toLowerCase();
                    final transactionId =
                        (widget.orderData['transactionId'] ?? '').toString();
                    final isOnline = paymentMethod.contains('online') ||
                        paymentMethod.contains('upi') ||
                        transactionId.isNotEmpty;

                    if (isOnline) {
                      return "Refund amount will process within 2 days";
                    }

                    return currentStatus == 'Cancelled'
                        ? "The order was cancelled by the buyer"
                        : "You rejected this order";
                  }(),
                  isCompleted: false,
                  isError: true,
                  isLast: true,
                ),
              ] else ...[
                _buildTimelineStep(
                  title: "Order Confirmed",
                  subtitle: "Order placed successfully",
                  isCompleted: true,
                  isLast: false,
                ),
                _buildTimelineStep(
                  title: "Processing",
                  subtitle: currentStatus == 'Processing' ||
                          currentStatus == 'Dispatched'
                      ? "Your order is being processed"
                      : "Waiting for seller",
                  isCompleted: currentStatus == 'Processing' ||
                      currentStatus == 'Dispatched',
                  isLast: false,
                ),
                _buildTimelineStep(
                  title: "Order Dispatched",
                  subtitle: currentStatus == 'Dispatched'
                      ? "Your order has been dispatched"
                      : "Waiting",
                  isCompleted: currentStatus == 'Dispatched',
                  isLast: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    bool isError = false,
  }) {
    Color activeColor = isError ? Colors.red : const Color(0xFF16A34A);
    Color borderColor = isError
        ? Colors.red
        : (isCompleted ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isCompleted || isError) ? activeColor : Colors.white,
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : (isError
                        ? const Icon(Icons.close, color: Colors.white, size: 12)
                        : null),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: (isCompleted || isError)
                        ? activeColor
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? const Color(0xFF172033)
                          : const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isRefunded = widget.orderData['Refuned']?.toString() == '1' ||
        widget.orderData['Refuned']?.toString().toLowerCase() == 'true' ||
        widget.orderData['Refuned'] == true ||
        widget.orderData['Refuned'] == 1;

    final paymentMethod =
        widget.orderData['paymentMethod']?.toString().toLowerCase() ?? '';
    final transactionId = widget.orderData['transactionId']?.toString() ?? '';
    final isOnline = paymentMethod.contains('online') ||
        paymentMethod.contains('upi') ||
        transactionId.isNotEmpty;

    final isFromRefundScreen = widget.orderData['isFromRefundScreen'] == true;

    final isRefundPending = isFromRefundScreen &&
        (currentStatus == 'Cancelled' || currentStatus == 'Rejected') &&
        isOnline &&
        !isRefunded;

    if (currentStatus != 'Pending' &&
        currentStatus != 'Pending Verification' &&
        currentStatus != 'Processing' &&
        !isRefundPending) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStatus == 'Pending' ||
              currentStatus == 'Pending Verification') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showAcceptDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0857A0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Accept Order",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: _showRejectDialog,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF172033),
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Reject Order",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ] else if (currentStatus == 'Processing') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showDispatchDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF16A34A), // Green color for dispatch
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Dispatch Order",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (isRefundPending) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showRefundCompletedDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Refund Completed",
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRefundCompletedDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Confirm Refund",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you have completed the refund for this order? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // close dialog
                        Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false);

                        try {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(widget.orderData['docId'])
                              .update({
                            'Refuned': true,
                            'refundedAt': FieldValue.serverTimestamp(),
                          });

                          Get.back(); // close loader
                          setState(() {
                            widget.orderData['Refuned'] = true;
                          });
                          toastSuccess("Order marked as refunded");

                          if (Get.isRegistered<SellerDashboardController>()) {
                            Get.find<SellerDashboardController>()
                                .fetchDashboardMetrics();
                          }

                          Get.back(); // return to previous screen
                        } catch (e) {
                          Get.back(); // close loader
                          toastError("Failed to update refund status");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDispatchDialog() {
    final TextEditingController trackingController = TextEditingController();
    String? errorMessage;

    Get.dialog(
      StatefulBuilder(builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Dispatch Order",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tracking URL",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: trackingController,
                  decoration: InputDecoration(
                    hintText: "https://...",
                    errorText: errorMessage,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                  ),
                  onChanged: (val) {
                    if (errorMessage != null)
                      setState(() => errorMessage = null);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFD0D5DD)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(color: Color(0xFF172033))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final url = trackingController.text.trim();
                          if (url.isEmpty) {
                            setState(() =>
                                errorMessage = "Tracking URL is required");
                            return;
                          }
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            setState(() => errorMessage =
                                "Enter a valid URL (http/https)");
                            return;
                          }
                          Get.back();
                          _updateOrderStatus('Dispatched', trackingUrl: url);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Confirm",
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showAcceptDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Accept Order?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033)),
              ),
              const SizedBox(height: 12),
              Text(
                "Confirm that you want to accept order ${widget.orderData['orderId'] ?? '#NL1024'}.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(color: Color(0xFF172033))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _updateOrderStatus('Accepted');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0857A0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Accept",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Reject Order?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033)),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to reject order ${widget.orderData['orderId'] ?? '#NL1024'}?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD0D5DD)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Keep Order",
                          style: TextStyle(color: Color(0xFF172033))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _updateOrderStatus('Rejected');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFDC2626), // Destructive Red
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Reject",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String status, {String? trackingUrl}) async {
    String uiStatus = status;
    String dbStatus = status.toLowerCase();

    if (status == 'Accepted') {
      uiStatus = 'Processing';
      dbStatus = 'processing';
    } else if (status == 'Rejected') {
      uiStatus = 'Cancelled';
      dbStatus = 'cancelled';
    } else if (status == 'Dispatched') {
      uiStatus = 'Dispatched';
      dbStatus = 'dispatched';
    }

    // Show loading dialog
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
      ),
      barrierDismissible: false,
    );

    // Show immediate update
    setState(() {
      currentStatus = uiStatus;
    });

    try {
      final orderId = widget.orderData['orderId'];
      final docId = widget.orderData['docId'] ?? orderId;
      if (docId != null) {
        final Map<String, dynamic> updateData = {
          'status': dbStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (status == 'Accepted') {
          updateData['acceptedAt'] = FieldValue.serverTimestamp();
        } else if (status == 'Dispatched') {
          updateData['dispatchedAt'] = FieldValue.serverTimestamp();
          if (trackingUrl != null && trackingUrl.isNotEmpty) {
            updateData['trackingUrl'] = trackingUrl;
          }
        }

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .update(updateData);

        if (dbStatus == 'cancelled') {
          try {
            final data = widget.orderData;
            final productId = data['productId'];
            final variantId = data['variantId'];
            final variantName = data['variantName'];
            final quantityStr = data['quantity']?.toString() ?? '1';
            final quantity = int.tryParse(quantityStr) ?? 1;

            if (productId != null) {
              await StockManager.restoreStock(
                bookingId: docId ?? orderId,
                productId: productId.toString(),
                quantity: quantity,
                variantId: variantId?.toString(),
                variantName: variantName?.toString(),
              );
            }
          } catch (e) {
            debugPrint("Error restoring stock on seller rejection: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating order: $e");
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close the loading dialog
      }
    }

    if (status == 'Accepted') {
      toastSuccess("Order Accepted");
    } else if (status == 'Rejected') {
      toastError("Order Rejected");
      // Go back to orders list after rejection so it refreshes
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Get.back();
    } else if (status == 'Dispatched') {
      toastSuccess("Order Dispatched");
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Get.back();
    } else {
      toastSuccess("Order status updated");
    }
  }
}

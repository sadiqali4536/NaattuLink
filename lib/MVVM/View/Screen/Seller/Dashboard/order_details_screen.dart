import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class SellerOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const SellerOrderDetailsScreen({super.key, required this.orderData});

  @override
  State<SellerOrderDetailsScreen> createState() =>
      _SellerOrderDetailsScreenState();
}

class _SellerOrderDetailsScreenState extends State<SellerOrderDetailsScreen> {
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    String rawStatus = widget.orderData['status'] ?? 'Pending';
    if (rawStatus.isNotEmpty) {
      currentStatus =
          rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
    } else {
      currentStatus = 'Pending';
    }
  }

  void _copyOrderId() {
    Clipboard.setData(
        ClipboardData(text: widget.orderData['orderId'] ?? '#NL1024'));
    toastSuccess("Order ID copied");
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF172033)),
            onPressed: () {},
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

  Widget _buildStatusBanner() {
    final bool isDispatched = currentStatus == 'Dispatched';
    final Color bgColor =
        isDispatched ? const Color(0xFFDCFCE7) : const Color(0xFFEAF3FF);
    final Color textColor =
        isDispatched ? const Color(0xFF16A34A) : const Color(0xFF0857A0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isDispatched ? Icons.check_circle : Icons.circle,
              size: isDispatched ? 18 : 10, color: textColor),
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
              if (currentStatus == 'Pending') ...[
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
                widget.orderData['customerName'] ?? "Rahul Sharma",
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("💵 ", style: TextStyle(fontSize: 12)),
                  Text(
                    widget.orderData['paymentMethod'] ?? "Cash on Delivery",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF172033)),
                  ),
                  if (widget.orderData['paymentStatus'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      widget.orderData['paymentStatus'],
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF667085)),
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
  }) {
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
                  color: isCompleted ? const Color(0xFF16A34A) : Colors.white,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF16A34A)
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
    if (currentStatus != 'Pending' && currentStatus != 'Processing') {
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
          if (currentStatus == 'Pending') ...[
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
          ],
        ],
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

    // Show loading or immediate update
    setState(() {
      currentStatus = uiStatus;
    });

    try {
      final orderId = widget.orderData['orderId'];
      if (orderId != null) {
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
            .doc(orderId)
            .update(updateData);
      }

      if (status == 'Accepted') {
        toastSuccess("Order Accepted");
      } else if (status == 'Rejected') {
        toastError("Order Rejected");
      } else {
        toastSuccess("Order status updated");
      }
    } catch (e) {
      debugPrint("Error updating order: $e");
    }
  }
}

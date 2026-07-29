import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'confirmed_booking_details.dart';
import 'cancelled_booking_details.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  static const _primary = Color(0xFF0F2E5A);
  static const _amber = Color(0xFFFFC107);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final _statusFilters = ['All', 'Confirmed', 'Cancelled', 'Completed'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> get _stream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('service_bookings')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    var list = docs;

    // Status filter
    if (_selectedStatus != 'All') {
      list = list
          .where((d) =>
              (d.data() as Map<String, dynamic>)['status']
                  ?.toString()
                  .toLowerCase() ==
              _selectedStatus.toLowerCase())
          .toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return (data['serviceName']?.toString().toLowerCase().contains(q) ??
                false) ||
            (data['providerName']?.toString().toLowerCase().contains(q) ??
                false);
      }).toList();
    }

    // Sort newest first
    list.sort((a, b) {
      final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (aTs == null || bTs == null) return 0;
      return bTs.compareTo(aTs);
    });

    return list;
  }

  Future<void> _showCancelSheet(String bookingId) async {
    String? selectedReason;
    final commentController = TextEditingController();
    final reasons = [
      'Change of plans',
      'Found a different professional',
      'Service no longer needed',
      'Other',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cancel Booking?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancellations made within 2 hours of the scheduled time may incur a convenience fee of ₹150 as per our service policy.',
                          style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Please select a reason for cancelling:',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 10),
                ...reasons.map((r) {
                  final sel = selectedReason == r;
                  return GestureDetector(
                    onTap: () => setSS(() => selectedReason = r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF059669)
                              : Colors.grey.shade300,
                          width: sel ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: sel ? const Color(0xFFF0FDF4) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: sel
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(r,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.normal,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('Additional comments (Optional)',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Tell us more about why you're cancelling...",
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF0F2E5A), width: 1.5),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: selectedReason == null
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await FirebaseFirestore.instance
                                .collection('service_bookings')
                                .doc(bookingId)
                                .update({
                              'status': 'cancelled',
                              'cancellationReason': selectedReason,
                              'cancellationComment':
                                  commentController.text.trim(),
                              'cancelledAt': FieldValue.serverTimestamp(),
                            });
                          },
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    label: const Text('Confirm Cancellation',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF0F2E5A), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text('Keep Booking',
                        style: TextStyle(
                            color: Color(0xFF0F2E5A),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('My Bookings',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2E5A))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search your bookings',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                                child: const Icon(Icons.close,
                                    color: Colors.grey, size: 18),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status chips
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _statusFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final st = _statusFilters[i];
                        final sel = _selectedStatus == st;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStatus = st),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel ? _primary : Colors.grey.shade300,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              st,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                                color: sel ? _primary : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Booking list ────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF0F2E5A)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final filtered = _filter(snapshot.data?.docs ?? []);

                  if (filtered.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No bookings match "$_searchQuery"'
                              : 'No bookings found',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            Icon(Icons.inbox_outlined,
                                size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 6),
                            Text(
                              'End of your booking history',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      final data =
                          filtered[index].data() as Map<String, dynamic>;
                      return _BookingCard(
                        data: data,
                        bookingId: filtered[index].id,
                        onCancel: _showCancelSheet,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final Future<void> Function(String) onCancel;

  const _BookingCard(
      {required this.data, required this.bookingId, required this.onCancel});

  String get _status => data['status']?.toString().toLowerCase() ?? 'confirmed';

  Color get _statusBgColor {
    switch (_status) {
      case 'confirmed':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'completed':
        return const Color(0xFFDBEAFE);
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _statusTextColor {
    switch (_status) {
      case 'confirmed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel => _status[0].toUpperCase() + _status.substring(1);

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
    final isConfirmed = _status == 'confirmed';

    return isConfirmed ? _fullCard(context) : _compactCard(context);
  }

  // ── Full card (Confirmed) ────────────────────────────────────────────────────
  Widget _fullCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['serviceName'] ?? 'Service',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Provider + price
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _serviceImage(48),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.storefront_outlined,
                            size: 13, color: Colors.black45),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['providerName'] ?? 'Provider',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        data['serviceCategory'] != null
                            ? '${_capitalize(data['serviceCategory'])} Service'
                            : 'Professional Service',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TOTAL PRICE',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.black45,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '₹${data['price'] ?? '0'}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // Date + Time
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.black45),
                const SizedBox(width: 6),
                Text(_formattedDate,
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                if (data['selectedTimeSlot'] != null &&
                    data['selectedTimeSlot'].toString().isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 14, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['selectedTimeSlot'],
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => ConfirmedBookingDetails(
                              data: data,
                              bookingId: bookingId,
                              onCancel: onCancel,
                            ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                      ),
                      child: const Text('View Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => onCancel(bookingId),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFDC2626), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact card (Cancelled / Completed) ─────────────────────────────────────
  Widget _compactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Service image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _serviceImage(60),
            ),
            const SizedBox(width: 12),

            // Title + category + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['serviceName'] ?? 'Service',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Builder(builder: (context) {
                    if (_status == 'cancelled') {
                      final isRefunded = data['Refuned']?.toString() == '1' ||
                          data['Refuned']?.toString().toLowerCase() == 'true' ||
                          data['Refuned'] == true ||
                          data['Refuned'] == 1;
                      return Row(
                        children: [
                          Text(
                            isRefunded ? 'REFUNDED: ' : 'REFUND: ',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            isRefunded ? '₹${data['price'] ?? '0'}' : 'Pending',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          const Text(
                            'PRICE: ',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${data['price'] ?? '0'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                  const SizedBox(height: 6),
                  _statusBadge(),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // View Details button (vertical)
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () {
                  Get.to(() => CancelledBookingDetails(
                        data: data,
                        bookingId: bookingId,
                      ));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _statusTextColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  'View Details',
                  style: TextStyle(
                      color: _statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────
  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _status == 'confirmed'
                ? Icons.check_circle
                : _status == 'cancelled'
                    ? Icons.cancel
                    : Icons.done_all,
            color: _statusTextColor,
            size: 11,
          ),
          const SizedBox(width: 3),
          Text(
            _statusLabel,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _statusTextColor),
          ),
        ],
      ),
    );
  }

  Widget _serviceImage(double size) {
    if (data['image'] != null && (data['image'] as String).isNotEmpty) {
      return Image.network(
        data['image'],
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderIcon(size),
      );
    }
    return _placeholderIcon(size);
  }

  Widget _placeholderIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.home_repair_service,
          color: Color(0xFF0F2E5A), size: 24),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

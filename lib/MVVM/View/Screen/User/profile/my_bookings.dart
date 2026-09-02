import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'confirmed_booking_details.dart';
import 'cancelled_booking_details.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/confirmed_booking_details.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/order_details_page.dart';
import 'package:naattulink/MVVM/utils/order_status_utils.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';

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
  final Rx<MyBookingSection> selectedSection = MyBookingSection.bookings.obs;

  int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        setState(() {
          _limit += 10;
        });
      }
    });
  }

  List<String> get _statusFilters {
    if (selectedSection.value == MyBookingSection.orders) {
      return ['All', 'Pending', 'Cancelled', 'Completed'];
    }
    return ['All', 'Confirmed', 'Cancelled', 'Completed'];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> get serviceBookingsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('service_bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots();
  }

  Stream<QuerySnapshot> get ordersStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    var list = docs;

    // Status filter
    if (_selectedStatus != 'All') {
      list = list.where((d) {
        final status =
            ((d.data() as Map<String, dynamic>)['status']?.toString() ?? '')
                .toLowerCase();
        final sel = _selectedStatus.toLowerCase();
        if (sel == 'pending' &&
            (status == 'pending' || status == 'pending_verification')) {
          return true;
        }
        return status == sel;
      }).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final isProduct = data['bookingType'] == 'Product Order';
        final title = isProduct ? data['serviceTitle'] : data['serviceName'];
        final provider = isProduct ? 'NaattuLink' : data['providerName'];
        return (title?.toString().toLowerCase().contains(q) ?? false) ||
            (provider?.toString().toLowerCase().contains(q) ?? false);
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, // Dark icons for white background
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => Text(
                              selectedSection.value == MyBookingSection.bookings
                                  ? 'My Bookings'
                                  : 'My Orders',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F2E5A)))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Top Selector (Bookings / Orders)
                      Obx(() => Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedSection.value !=
                                          MyBookingSection.bookings) {
                                        selectedSection.value =
                                            MyBookingSection.bookings;
                                        setState(() {
                                          _selectedStatus = 'All';
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selectedSection.value ==
                                                MyBookingSection.bookings
                                            ? const Color(0xFF0F2E5A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CustomCalendarIcon(),
                                          const SizedBox(width: 8),
                                          Text(
                                            'BOOKINGS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: selectedSection.value ==
                                                      MyBookingSection.bookings
                                                  ? Colors.white
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (selectedSection.value !=
                                          MyBookingSection.orders) {
                                        selectedSection.value =
                                            MyBookingSection.orders;
                                        setState(() {
                                          _selectedStatus = 'All';
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selectedSection.value ==
                                                MyBookingSection.orders
                                            ? const Color(0xFF0F2E5A)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '📦',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ORDERS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: selectedSection.value ==
                                                      MyBookingSection.orders
                                                  ? Colors.white
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),

                      // Search bar
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Obx(() => TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: selectedSection.value ==
                                        MyBookingSection.bookings
                                    ? 'Search your bookings'
                                    : 'Search your orders',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 14),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.grey, size: 20),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () => setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        }),
                                        child: const Icon(Icons.close,
                                            color: Colors.grey, size: 18),
                                      )
                                    : Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Icon(Icons.filter_list,
                                            color: Colors.grey.shade600),
                                      ),
                              ),
                            )),
                      ),
                      const SizedBox(height: 10),
                      // Status chips
                      SizedBox(
                        height: 38,
                        child: Obx(() => ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _statusFilters.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final st = _statusFilters[i];
                                final sel = _selectedStatus == st;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedStatus = st),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? Color(0xFF0F2E5A).withOpacity(0.15)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sel
                                            ? Color(0xFF0F2E5A)
                                            : Colors.grey.shade200,
                                        width: sel ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      st,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: sel
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: sel
                                            ? Color(0xFF0F2E5A)
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
                      ),
                    ],
                  ),
                ),

                // ── Booking list ────────────────────────────────────────────────
                Expanded(
                  child: Container(
                    color: const Color(0xFFF5F6FA),
                    child: Obx(() {
                      final stream =
                          selectedSection.value == MyBookingSection.bookings
                              ? serviceBookingsStream
                              : ordersStream;
                      final isBookings =
                          selectedSection.value == MyBookingSection.bookings;

                      return StreamBuilder<QuerySnapshot>(
                        stream: stream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0F2E5A)));
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }

                          final filtered = _filter(snapshot.data?.docs ?? []);

                          if (filtered.isEmpty) {
                            return EmptyStateWidget(
                              title:
                                  isBookings ? 'No Bookings Yet' : 'No Orders',
                              searchQuery: _searchQuery,
                              defaultMessage: isBookings
                                  ? "Your upcoming and past bookings\nwill appear here."
                                  : "You haven't placed any orders yet.",
                              buttonText: isBookings
                                  ? 'Browse Services'
                                  : 'Continue Shopping',
                              targetIndex: isBookings ? 1 : 0,
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: filtered.length + 1,
                            itemBuilder: (context, index) {
                              if (index == filtered.length) {
                                return Column(
                                  children: [
                                    if (snapshot.connectionState == ConnectionState.active && (snapshot.data?.docs.length ?? 0) == _limit)
                                      const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Center(child: CircularProgressIndicator()),
                                      ),
                                    const SizedBox(height: 24),
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isBookings
                                          ? 'End of your booking history'
                                          : 'End of your order history',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isBookings
                                          ? "You've reached the end. Check back later for\nmore bookings."
                                          : "You've reached the end. Check back later for\nmore orders.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }
                              final data = filtered[index].data()
                                  as Map<String, dynamic>;
                              return _BookingCard(
                                data: data,
                                bookingId: filtered[index].id,
                                onCancel: _showCancelSheet,
                              );
                            },
                          );
                        },
                      );
                    }),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

// ── Booking Card ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingId;
  final Future<void> Function(String) onCancel;

  const _BookingCard(
      {required this.data, required this.bookingId, required this.onCancel});

  bool get isProductOrder => data['bookingType'] == 'Product Order';

  String get _title => isProductOrder
      ? data['serviceTitle']?.toString() ?? 'Product'
      : data['serviceName']?.toString() ?? 'Service';

  String get _provider => isProductOrder
      ? data['workerName']?.toString() ?? 'NaattuLink'
      : data['providerName']?.toString() ?? 'Provider';

  String _formatPrice(dynamic raw) {
    if (raw == null) return '0';
    double price = double.tryParse(raw.toString()) ?? 0.0;
    if (price == price.toInt()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  String get _price {
    if (isProductOrder) {
      return _formatPrice(data['totalAmount'] ?? data['discountPrice']);
    }
    return _formatPrice(data['price']);
  }

  String get _category {
    if (isProductOrder) return 'Product Order';
    return data['serviceCategory'] != null
        ? '${_capitalize(data['serviceCategory'])} Service'
        : 'Professional Service';
  }

  String get _status => data['status']?.toString().toLowerCase() ?? 'confirmed';

  Color get _statusBgColor {
    switch (_status) {
      case 'confirmed':
      case 'dispatched':
        return const Color(0xFFD1FAE5);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'completed':
        return const Color(0xFFDBEAFE);
      case 'pending':
        return const Color(0xFFE0F2FE);
      case 'pending_verification':
      case 'processing':
        return const Color(0xFFFEF3C7);
      default:
        return Colors.grey.shade200;
    }
  }

  Color get _statusTextColor {
    switch (_status) {
      case 'confirmed':
      case 'dispatched':
        return const Color(0xFF059669);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF2563EB);
      case 'pending':
        return const Color(0xFF0284C7);
      case 'pending_verification':
      case 'processing':
        return const Color(0xFFD97706);
      default:
        return Colors.grey.shade700;
    }
  }

  String get _statusLabel {
    if (isProductOrder) {
      return OrderStatusUtils.getOrderStatusTitle(_status);
    }
    return _capitalize(_status.replaceAll('_', ' '));
  }

  String get _formattedDate {
    if (isProductOrder) {
      if (data['createdAt'] is Timestamp) {
        return DateFormat('dd-MMM-yyyy')
            .format((data['createdAt'] as Timestamp).toDate());
      }
      return '';
    }
    try {
      return DateFormat('dd-MMM-yyyy')
          .format(DateTime.parse(data['selectedDate'] ?? ''));
    } catch (_) {
      return data['selectedDate'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isProductOrder) return _orderCard(context);
    final isConfirmed = _status == 'confirmed';
    return isConfirmed ? _fullCard(context) : _compactCard(context);
  }

  // ── Order Card (Product Orders) ─────────────────────────────────────────────
  Widget _orderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _serviceImage(70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            _formattedDate,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Order ID
                  Text(
                    'Order ID: #${bookingId.length > 6 ? bookingId.substring(0, 6).toUpperCase() : bookingId.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Row(
                    children: [
                      const Text(
                        'PRICE: ',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹$_price',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Badge + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusBadge(),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.to(() => OrderDetailsPage(
                                  bookingId: bookingId,
                                ));
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF0F2E5A), width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                                color: Color(0xFF0F2E5A),
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                    _title,
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
                            _provider,
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
                        _category,
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
                      '₹$_price',
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
                if (!isProductOrder &&
                    data['selectedTimeSlot'] != null &&
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
                    _title,
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
                            isRefunded ? '₹$_price' : 'Pending',
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
                            '₹$_price',
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
            (_status == 'confirmed' || _status == 'dispatched')
                ? Icons.check_circle
                : (_status == 'cancelled' || _status == 'rejected')
                    ? Icons.cancel
                    : (_status == 'processing')
                        ? Icons.autorenew
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

enum MyBookingSection { bookings, orders }

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String searchQuery;
  final String defaultMessage;
  final String buttonText;
  final int targetIndex;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.searchQuery,
    required this.defaultMessage,
    required this.buttonText,
    required this.targetIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Image.asset(
            'assets/icons/my_bookings.png', // Assuming asset exists
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.event_busy, size: 120, color: Colors.blue.shade100),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            searchQuery.isNotEmpty
                ? 'No matches for "$searchQuery"'
                : defaultMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => user_Dashboard(
                          initialHomeCategoryIndex: targetIndex)),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 212, 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.black87, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, color: Colors.black87, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Custom Calendar Icon ──────────────────────────────────────────────────────
class CustomCalendarIcon extends StatelessWidget {
  const CustomCalendarIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main body
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1))
                ],
              ),
              child: Column(
                children: [
                  // Red header
                  Container(
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935), // Red
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3)),
                    ),
                  ),
                  // Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (row) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (col) {
                              return Container(
                                width: 2,
                                height: 1.5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(0.5),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Left ring
          Positioned(
            top: -1,
            left: 3,
            child: Container(
              width: 2,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Right ring
          Positioned(
            top: -1,
            right: 3,
            child: Container(
              width: 2,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/utils/order_status_utils.dart';
import 'order_details_screen.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'New', 'Processing', 'Dispatched'];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Not logged in"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF0F2E5A)),
          onPressed: () {},
        ),
        title: const Text(
          'Orders',
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: Color(0xFF0F2E5A)),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('sellerId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Orders Stream Error: ${snapshot.error}");
            return Center(
                child: Text("Error loading orders: ${snapshot.error}"));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final allOrders = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['bookingType'] == 'Product Order';
          }).toList();

          final newOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status =
                (data['status'] ?? 'pending').toString().toLowerCase();
            return status == 'pending' || status == 'pending_verification';
          }).toList();

          final processingOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            return status == 'processing';
          }).toList();

          final dispatchedOrders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            return status == 'shipped' || status == 'dispatched';
          }).toList();

          List<QueryDocumentSnapshot> displayedOrders = [];
          if (selectedFilter == 'All') {
            displayedOrders = allOrders;
          } else if (selectedFilter == 'New') {
            displayedOrders = newOrders;
          } else if (selectedFilter == 'Processing') {
            displayedOrders = processingOrders;
          } else if (selectedFilter == 'Dispatched') {
            displayedOrders = dispatchedOrders;
          }

          // Sort by creation date descending
          displayedOrders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(allOrders.length),
                const SizedBox(height: 16),
                _buildSummaryCards(newOrders.length, processingOrders.length,
                    dispatchedOrders.length),
                const SizedBox(height: 20),
                _buildFilterChips(),
                const SizedBox(height: 20),
                if (displayedOrders.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No orders found in this category.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
                  ...displayedOrders.map((doc) => _buildOrderCard(doc)),
                const SizedBox(height: 80), // Space for bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Manage your customer orders',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          '$totalCount orders',
          style: const TextStyle(
            color: Color(0xFF0F2E5A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int newCount, int prepCount, int completedCount) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            newCount.toString(),
            'New Orders',
            const Color(0xFFE2E8F0),
            const Color(0xFF0F2E5A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            prepCount.toString(),
            'Processing',
            Colors.white,
            Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            completedCount.toString(),
            'Dispatched',
            Colors.white,
            Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String count, String label, Color bgColor, Color countColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: Chip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor:
                    isSelected ? const Color(0xFF0F2E5A) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF0F2E5A)
                        : Colors.grey.shade300,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawStatus = data['status'] ?? 'pending';

    // Using OrderStatusUtils for consistent naming
    final statusTitle = OrderStatusUtils.getOrderStatusTitle(rawStatus);

    String displayStatus = statusTitle.toUpperCase();
    IconData statusIcon = Icons.push_pin;
    Color statusColor = const Color(0xFF0F2E5A);
    Color statusBgColor = const Color(0xFFE2E8F0);

    if (rawStatus == 'processing') {
      displayStatus = 'PROCESSING';
      statusIcon = Icons.circle;
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    } else if (rawStatus == 'shipped' || rawStatus == 'dispatched') {
      displayStatus = 'DISPATCHED';
      statusIcon = Icons.local_shipping;
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
    }

    final price =
        data['totalAmount'] ?? data['price'] ?? data['discountPrice'] ?? 0;

    final orderId =
        data['orderId']?.toString() ?? doc.id.substring(0, 8).toUpperCase();
    final customerName = data['deliveryAddress']?['receiverName'] ??
        data['userId'] ??
        'Customer';

    // Quantity
    final itemsCount = data['quantity'] ?? 1;

    String timeString = '';
    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt != null) {
      timeString = DateFormat('MMM d, h:mm a').format(createdAt.toDate());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                displayStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2E5A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#$orderId',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$customerName • $itemsCount items',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final mappedData = {
                            'orderId': doc.id,
                            'customerName': customerName,
                            'customerLocation': data['deliveryAddress']
                                    ?['formattedAddress'] ??
                                'Unknown Location',
                            'customerPhone':
                                data['deliveryAddress']?['receiverPhone'] ?? '',
                            'customerAltPhone': data['deliveryAddress']
                                    ?['alternatePhone'] ??
                                '',
                            'status': rawStatus,
                            'subtotal': price,
                            'deliveryFee': 0,
                            'paymentMethod': data['paymentMethod'] ?? 'Unknown',
                            'paymentStatus': data['paymentStatus'] ?? 'Pending',
                            'items': [
                              {
                                'name': data['serviceTitle'] ?? 'Product',
                                'qty': data['quantity'] ?? 1,
                                'price': data['discountPrice'] ??
                                    data['originalPrice'] ??
                                    price,
                                'image': data['image'],
                              }
                            ],
                          };
                          Get.to(() =>
                              SellerOrderDetailsScreen(orderData: mappedData));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F2E5A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View Order Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

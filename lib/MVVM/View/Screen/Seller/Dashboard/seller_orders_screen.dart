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
  
  final ScrollController _scrollController = ScrollController();
  
  List<QueryDocumentSnapshot> _orders = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  
  int _totalCount = 0;
  int _newCount = 0;
  int _processingCount = 0;
  int _dispatchedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _fetchOrders();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        _fetchMoreOrders();
      }
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchCounts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final baseQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('sellerId', isEqualTo: currentUser.uid)
        .where('bookingType', isEqualTo: 'Product Order');
        
    try {
      final totalSnap = await baseQuery.count().get();
      final newSnap = await baseQuery.where('status', whereIn: ['pending', 'pending_verification']).count().get();
      final processingSnap = await baseQuery.where('status', isEqualTo: 'processing').count().get();
      final dispatchedSnap = await baseQuery.where('status', whereIn: ['shipped', 'dispatched']).count().get();
      
      if (mounted) {
        setState(() {
          _totalCount = totalSnap.count ?? 0;
          _newCount = newSnap.count ?? 0;
          _processingCount = processingSnap.count ?? 0;
          _dispatchedCount = dispatchedSnap.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching counts: $e");
    }
  }

  Query _buildQuery() {
    final currentUser = FirebaseAuth.instance.currentUser;
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('sellerId', isEqualTo: currentUser?.uid)
        .where('bookingType', isEqualTo: 'Product Order');

    if (selectedFilter == 'New') {
      query = query.where('status', whereIn: ['pending', 'pending_verification']);
    } else if (selectedFilter == 'Processing') {
      query = query.where('status', isEqualTo: 'processing');
    } else if (selectedFilter == 'Dispatched') {
      query = query.where('status', whereIn: ['shipped', 'dispatched']);
    }

    return query.orderBy('createdAt', descending: true).limit(10);
  }

  Future<void> _fetchOrders() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _orders = [];
      _lastDocument = null;
      _hasMoreData = true;
    });

    try {
      final snapshot = await _buildQuery().get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _orders = snapshot.docs;
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _buildQuery().startAfterDocument(_lastDocument!).get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _orders.addAll(snapshot.docs);
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      debugPrint("Error fetching more orders: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

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
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchCounts();
          await _fetchOrders();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(_totalCount),
              const SizedBox(height: 16),
              _buildSummaryCards(_newCount, _processingCount, _dispatchedCount),
              const SizedBox(height: 20),
              _buildFilterChips(),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_orders.isEmpty)
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
                ..._orders.map((doc) => _buildOrderCard(doc)),
              
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_hasMoreData && _orders.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      "No more orders",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
                
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
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
                if (selectedFilter != filter) {
                  setState(() {
                    selectedFilter = filter;
                  });
                  _fetchOrders();
                }
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
    
    final numPrice = num.tryParse(price.toString()) ?? 0;
    final displayPrice = numPrice == numPrice.toInt() ? numPrice.toInt().toString() : numPrice.toString();

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
                              '₹$displayPrice',
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

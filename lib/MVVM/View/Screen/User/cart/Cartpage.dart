import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/model/models/cart_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/booking_confirm.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/confirm_details_page.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:get/get.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isDialogShown = false;
  bool _isPriceDetailsExpanded = true;
  final TextEditingController _promoController = TextEditingController();

  static const Color _navy = Color(0xFF0F2E5A);
  static const Color _lightBg = Color(0xFFEEF3FB);
  static const Color _amber = Color(0xFFFFCA28);

  // ── Loading Dialog ────────────────────────────────────────────────────────

  void showLoadingDialog(BuildContext context) {
    if (_isDialogShown) return;
    _isDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: const [
            CircularProgressIndicator(color: _navy),
            SizedBox(width: 20),
            Text("Booking your services...",
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ).then((_) => _isDialogShown = false);
  }

  void hideLoadingDialog() {
    if (_isDialogShown) {
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogShown = false;
    }
  }

  // ── Booking Logic ─────────────────────────────────────────────────────────

  Future<void> _processBooking(List<QueryDocumentSnapshot> cartDocs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (cartDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("🛒 Cart is empty. Add services before booking."),
      ));
      return;
    }

    showLoadingDialog(context);

    try {
      List<Map<String, dynamic>> bookedItems = [];

      for (var doc in cartDocs) {
        final data = doc.data() as Map<String, dynamic>;

        String? finalSellerId = data['sellerId'];
        if (finalSellerId == null || finalSellerId.isEmpty) {
          final productId = data['productId'];
          if (productId != null) {
            try {
              final productDoc = await FirebaseFirestore.instance
                  .collection('store_products')
                  .doc(productId)
                  .get();
              if (productDoc.exists) {
                final pData = productDoc.data();
                finalSellerId = pData?['sellerId'] ??
                    pData?['ownerId'] ??
                    pData?['storeId'];
              }
            } catch (e) {
              debugPrint("Failed to fetch product for sellerId: $e");
            }
          }
        }

        final bookingData = {
          'userId': user.uid,
          'productId': data['productId'],
          'serviceTitle': data['productName'] ?? data['service_name'] ?? '',
          'image': data['productImage'] ?? data['image'] ?? '',
          'originalPrice': data['price']?.toString() ??
              data['original_price']?.toString() ??
              '',
          'discountPrice':
              data['offerPrice']?.toString() ?? data['price']?.toString() ?? '',
          'discount': data['discount']?.toString() ?? '',
          'rating': data['rating'] ?? 0,
          'category': data['category'] ?? '',
          'serviceType': data['service_type'] ?? '',
          'bookingType': 'Product Order',
          'status': 'pending',
          'workerId': null,
          'workerName': null,
          'sellerId': finalSellerId,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);

        if (finalSellerId != null && finalSellerId.isNotEmpty) {
          final productName =
              data['productName'] ?? data['service_name'] ?? 'Product';
          await FirebaseFirestore.instance
              .collection('seller_notifications')
              .add({
            'sellerId': finalSellerId,
            'title': 'New Order Received',
            'message': 'You have received a new order for $productName',
            'type': 'order',
            'created_at': FieldValue.serverTimestamp(),
            'is_read': false,
          });
        }
        await doc.reference.delete();
        bookedItems.add(bookingData);
      }

      hideLoadingDialog();
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BookingConfirmationModal(bookedItems: bookedItems),
        ),
      );
    } catch (e) {
      hideLoadingDialog();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("⚠️ Failed to book service: ${e.toString()}"),
      ));
    }
  }

  Future<void> _removeItem(DocumentReference docRef) async {
    await docRef.delete();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Item removed from cart"),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
      ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _lightBg,
        appBar: _buildAppBar(),
        body: _buildEmptyCart(),
      );
    }

    return Scaffold(
      backgroundColor: _lightBg,
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _navy));
          }

          final cartDocs = snapshot.data?.docs ?? [];

          if (cartDocs.isEmpty) {
            return _buildEmptyCart();
          }

          // Totals
          double totalPrice = 0;
          double totalOriginal = 0;
          double cancelledTotal = 0;

          for (int i = 0; i < cartDocs.length; i++) {
            final data = cartDocs[i].data() as Map<String, dynamic>;
            int qty = data['quantity'] ?? 1;
            double price = (double.tryParse(data["offerPrice"]?.toString() ??
                        data["price"]?.toString() ??
                        "0") ??
                    0) *
                qty;
            double orig = (double.tryParse(data["price"]?.toString() ??
                        data["original_price"]?.toString() ??
                        "0") ??
                    0) *
                qty;
            if (i == 1 && cartDocs.length > 1) {
              cancelledTotal += price;
            } else {
              totalPrice += price;
              totalOriginal += orig;
            }
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      // Cart items
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: cartDocs.length,
                        itemBuilder: (context, index) {
                          final doc = cartDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final item = CartModel(
                            service_id:
                                data['productId'] ?? data['service_id'] ?? '',
                            service_name: data['productName'] ??
                                data['service_name'] ??
                                '',
                            image: data['productImage'] ?? data['image'] ?? '',
                            original_price: data['price']?.toString() ??
                                data['original_price']?.toString() ??
                                '',
                            price: data['offerPrice']?.toString() ??
                                data['price']?.toString() ??
                                '',
                            discount: data['discount']?.toString() ?? '',
                            rating: data['rating'] ?? 0,
                            category:
                                data['variantName'] ?? data['category'] ?? '',
                            service_type: data['service_type'] ?? '',
                            addedAt: data['addedAt'] as Timestamp? ??
                                Timestamp.now(),
                          );
                          final isCancelled =
                              (index == 1 && cartDocs.length > 1);
                          final int quantity = data['quantity'] ?? 1;
                          return _buildCartItemCard(item, doc.reference,
                              isCancelled: isCancelled, quantity: quantity);
                        },
                      ),
                      const SizedBox(height: 12),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
              _buildPriceDetails(
                itemCount: cartDocs.length,
                totalPrice: totalPrice,
                totalOriginal: totalOriginal,
                cancelledTotal: cancelledTotal,
              ),
              _buildCheckoutBar(
                itemCount: cartDocs.length,
                totalPrice: totalPrice,
                onCheckout: () {
                  final cartItems = cartDocs
                      .map((doc) => CartItemModel.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id))
                      .toList();
                  Get.to(() => ConfirmDetailsPage(
                      cartItems: cartItems, isFromCart: true));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: const Text(
        "My Cart",
        style: TextStyle(
          color: _navy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: _navy),
              ),
              Positioned(
                top: 8,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: _amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "0",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty Cart ────────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Illustration
            Image.asset(
              'assets/icons/my_cart.png',
              height: 220,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 16),

            // Title
            const Text(
              "Your cart is empty",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              "Looks like you haven't added anything yet.\nExplore our services and start booking!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey.shade400,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Browse Services Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const user_Dashboard()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 255, 212, 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, color: Colors.black87, size: 22),
                    SizedBox(width: 12),
                    Text(
                      "Browse Services",
                      style: TextStyle(
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

            const SizedBox(height: 32),

            // Divider row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFDDE3EE),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDDE3EE),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Or continue shopping from",
                    style: TextStyle(
                        fontSize: 13, color: Colors.blueGrey.shade400),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFDDE3EE),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFDDE3EE),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Category shortcuts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryTile(
                  Icons.person_outline,
                  "Workers",
                  "Find verified\nprofessionals",
                  const Color(0xFF8C52FF),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const user_Dashboard(
                              initialHomeCategoryIndex: 1)),
                      (route) => false,
                    );
                  },
                ),
                // Hidden as requested:
                // _buildCategoryTile(Icons.shopping_cart_outlined, "Groceries",
                //     "Daily essentials\nat your door", const Color(0xFF4CAF50)),
                _buildCategoryTile(
                  Icons.shopping_bag_outlined,
                  "Shopping",
                  "Explore products\n& offers",
                  const Color(0xFF2196F3),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const user_Dashboard(
                              initialHomeCategoryIndex: 4)),
                      (route) => false,
                    );
                  },
                ),
                _buildCategoryTile(
                  Icons.grid_view,
                  "More",
                  "More categories\n& services",
                  const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const user_Dashboard(
                              initialHomeCategoryIndex: 0)),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Safe Secure banner
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFF3F5FC),
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Row(
            //     children: [
            //       Container(
            //         padding: const EdgeInsets.all(12),
            //         decoration: const BoxDecoration(
            //           color: Color(0xFFE8EAF6),
            //           shape: BoxShape.circle,
            //         ),
            //         child: const Icon(Icons.security,
            //             color: Color(0xFF5C6BC0), size: 32),
            //       ),
            //       const SizedBox(width: 16),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             const Text(
            //               "Safe. Secure. Reliable.",
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.bold,
            //                 color: _navy,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               "Your bookings and payments\nare 100% safe with us.",
            //               style: TextStyle(
            //                 fontSize: 12,
            //                 color: Colors.blueGrey.shade400,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      IconData icon, String label, String subLabel, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.blueGrey.shade400,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ── Cart Item Card ────────────────────────────────────────────────────────

  Widget _buildCartItemCard(CartModel item, DocumentReference docRef,
      {bool isCancelled = false, int quantity = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.image.isNotEmpty
                    ? item.image
                    : "https://via.placeholder.com/150"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Delete
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.service_name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          decoration:
                              isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCancelled)
                      Container(
                        margin: const EdgeInsets.only(left: 6, right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("CANCELLED",
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeItem(docRef),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitles
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      item.category.isNotEmpty
                          ? item.category
                          : "Expert Service",
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  "Professional Service",
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 12),

                // Price & Quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${item.price}",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isCancelled ? Colors.red : _navy,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _lightBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (quantity > 1) {
                                docRef.update({'quantity': quantity - 1});
                              } else {
                                _removeItem(docRef);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Icon(Icons.remove,
                                  size: 16, color: Colors.black87),
                            ),
                          ),
                          Text(
                            "$quantity",
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          InkWell(
                            onTap: () {
                              docRef.update({'quantity': quantity + 1});
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Icon(Icons.add,
                                  size: 16, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Promo Code ────────────────────────────────────────────────────────────

  Widget _buildPromoCodeSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.local_offer_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _promoController,
              decoration: const InputDecoration(
                hintText: "Apply promo code",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFDDE3EE))),
            ),
            child: const Center(
              child: Text(
                "Apply",
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Price Details ─────────────────────────────────────────────────────────

  Widget _buildPriceDetails({
    required int itemCount,
    required double totalPrice,
    required double totalOriginal,
    required double cancelledTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isPriceDetailsExpanded = !_isPriceDetailsExpanded;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: _navy, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Price Details",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy),
                  ),
                ),
                Icon(
                  _isPriceDetailsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _navy,
                ),
              ],
            ),
          ),
          if (_isPriceDetailsExpanded) ...[
            const SizedBox(height: 16),
            _priceRow(
                "Item Total ($itemCount item)",
                "₹${(totalOriginal + cancelledTotal).toStringAsFixed(0)}",
                Colors.black87),
            const SizedBox(height: 10),
            if (cancelledTotal > 0) ...[
              _priceRow("Cancelled Items (1 item)",
                  "- ₹${cancelledTotal.toStringAsFixed(0)}", Colors.red),
              const SizedBox(height: 10),
            ],
            _priceRow("Delivery Charge", "₹0", Colors.black87),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFDDE3EE), thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navy)),
                Text(
                  "₹${totalPrice.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _navy),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: valueColor)),
      ],
    );
  }

  // ── Checkout Bar ──────────────────────────────────────────────────────────

  Widget _buildCheckoutBar({
    required int itemCount,
    required double totalPrice,
    required VoidCallback onCheckout,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A68),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 28),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          itemCount.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$itemCount Item${itemCount > 1 ? 's' : ''}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "₹${totalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: const Color(0xFF0F2E5A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  Text(
                    "Proceed to Checkout",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

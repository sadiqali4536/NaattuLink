import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naattulink/MVVM/model/user/cart_item_model.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/View/Screen/location/location_selection_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/checkout/payment_page.dart';

class ConfirmDetailsPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final bool isFromCart;

  const ConfirmDetailsPage({
    Key? key,
    required this.cartItems,
    this.isFromCart = false,
  }) : super(key: key);

  @override
  State<ConfirmDetailsPage> createState() => _ConfirmDetailsPageState();
}

class _ConfirmDetailsPageState extends State<ConfirmDetailsPage> {
  bool _isLoading = false;
  final Rxn<AppLocationModel> _deliveryAddress = Rxn<AppLocationModel>();

  @override
  void initState() {
    super.initState();
    _fetchDefaultAddress();
  }

  Future<void> _fetchDefaultAddress() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('delivery_addresses')
            .where('isDefault', isEqualTo: 1)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          _deliveryAddress.value = AppLocationModel(
            id: query.docs.first.id,
            latitude: data['latitude']?.toDouble() ?? 0.0,
            longitude: data['longitude']?.toDouble() ?? 0.0,
            formattedAddress: data['address'] ?? '',
            city: data['city'],
            district: data['district'] ?? '',
            state: data['state'],
            pincode: data['pincode'],
            zoneId: data['zoneId'],
            zoneName: data['zoneName'],
            isPrimary: true,
            addressType: data['addressType'],
            receiverName: data['name'],
            receiverPhone: data['phone'],
            alternatePhone: data['alternativeNumber'],
            landmark: data['buildingName'],
          );
        }
      } catch (e) {
        debugPrint("Error fetching default address: $e");
      }
    }

    if (_deliveryAddress.value == null) {
      _deliveryAddress.value = LocationController.to.currentLocationModel.value;
    }

    setState(() => _isLoading = false);
  }

  double get _totalAmount {
    return widget.cartItems
        .fold(0.0, (sum, item) => sum + (item.offerPrice * item.quantity));
  }

  Future<void> _showLocationBottomSheet() async {
    final before = LocationController.to.currentLocationModel.value;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const LocationSelectionPage(requireZone: false),
        ),
      ),
    );
    final after = LocationController.to.currentLocationModel.value;
    if (after != null && after != before) {
      _deliveryAddress.value = after;
    }
  }

  Future<void> _confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'Please log in to continue.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    final loc = _deliveryAddress.value;
    if (loc == null) {
      Get.snackbar('Error', 'Please select a delivery address.',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    Get.to(
      () => PaymentPage(
        cartItems: widget.cartItems,
        totalAmount: _totalAmount,
        address: loc,
        isFromCart: widget.isFromCart,
      ),
    );
  }

  String _buildFullAddress(AppLocationModel loc) {
    List<String> parts = [];
    if (loc.landmark != null && loc.landmark!.trim().isNotEmpty) {
      parts.add(loc.landmark!.trim());
    }
    parts.add(loc.formattedAddress);
    if (loc.city != null &&
        loc.city!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.city!)) {
      parts.add(loc.city!.trim());
    }
    if (loc.district.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.district)) {
      parts.add(loc.district.trim());
    }
    if (loc.state != null &&
        loc.state!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.state!)) {
      parts.add(loc.state!.trim());
    }
    if (loc.pincode != null &&
        loc.pincode!.trim().isNotEmpty &&
        !loc.formattedAddress.contains(loc.pincode!)) {
      parts.add(loc.pincode!.trim());
    }
    return parts.join(', ');
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
          'Confirm Details',
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2956D3)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressCard(),
                  const SizedBox(height: 16),
                  _buildProductList(),
                  const SizedBox(height: 16),
                  _buildPriceDetails(),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(),
    );
  }

  Widget _buildAddressCard() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              TextButton(
                onPressed: _showLocationBottomSheet,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2956D3),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Change',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final loc = _deliveryAddress.value;
            if (loc == null) {
              return const Text(
                'No address selected',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF2956D3), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loc.receiverName != null &&
                          loc.receiverName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            loc.receiverName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2E5A),
                            ),
                          ),
                        ),
                      Text(
                        _buildFullAddress(loc),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      if (loc.receiverPhone != null &&
                          loc.receiverPhone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                loc.receiverPhone!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: widget.cartItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.productImage.isNotEmpty
                    ? Image.network(
                        item.productImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.variantName != null &&
                        item.variantName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.variantName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qty: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          '₹${item.offerPrice.toStringAsFixed(0)}',
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
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceDetails() {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item Total',
                  style: TextStyle(color: Color(0xFF64748B))),
              Text('₹${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, color: Color(0xFF0F2E5A))),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery Fee', style: TextStyle(color: Color(0xFF64748B))),
              Text('Free',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          onPressed: _confirmOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2956D3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Confirm Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

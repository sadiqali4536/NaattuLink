import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pet_Bookingpage.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/model/models/cart_model.dart';
import 'package:naattulink/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

class Cartservicecard extends StatefulWidget {
  final CartModel cartItem;
  final VoidCallback? onRemove;

  const Cartservicecard({
    super.key,
    required this.cartItem,
    this.onRemove,
  });

  @override
  State<Cartservicecard> createState() => _CartservicecardState();
}

class _CartservicecardState extends State<Cartservicecard> {
  String formatPrice(dynamic price) {
    if (price == null) return "0";
    if (price is int) return price.toString();
    if (price is double) return price.toInt().toString();
    if (price is String) {
      try {
        final parsed = double.parse(price);
        return parsed.toInt().toString();
      } catch (_) {
        return "0";
      }
    }
    return "0";
  }

  Future<void> _removeItemFromCart() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('cartItems')
          .doc(widget.cartItem.service_id)
          .delete();

      if (!mounted) return;
      CustomSnackBar.show(
          iconcolor: erroriconcolor,
          icon: Icons.delete,
          context: context,
          message: "Item removed from cart",
          color: const Color.fromARGB(255, 249, 246, 246));

      widget.onRemove?.call();
    } catch (e) {
      log("Error removing item: $e");
      if (!mounted) return;
      CustomSnackBar.show(
          iconcolor: erroriconcolor,
          icon: Icons.delete,
          context: context,
          message: 'Failed to remove item: $e',
          color: const Color.fromARGB(255, 249, 246, 246));
    }
  }

  Future<void> _showRemoveBottomSheet() async {
    String? selectedReason;
    final commentController = TextEditingController();

    final reasons = [
      'No longer needed',
      'Found a better service',
      'Changed my mind',
      'Other',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
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
                    // Handle bar
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

                    // Title
                    const Text(
                      'Remove from Cart?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Warning banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.info_outline,
                              color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Removing this item will delete it from your cart. You can always re-add it from the services page.',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reason label
                    const Text(
                      'Please select a reason for removing:',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

                    // Reason radio options
                    ...reasons.map((reason) {
                      final selected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedReason = reason),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF059669)
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: selected
                                ? const Color(0xFFF0FDF4)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF059669)
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: selected
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
                              Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Optional comments
                    const Text(
                      'Additional comments (Optional)',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Tell us more about why you're removing...",
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.all(14),
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
                          borderSide: const BorderSide(
                              color: Color(0xFF0F2E5A), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Remove button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: selectedReason == null
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                await _removeItemFromCart();
                              },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Confirm Remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Keep in Cart button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFF0F2E5A), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Keep in Cart',
                          style: TextStyle(
                            color: Color(0xFF0F2E5A),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItem = widget.cartItem;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        child: Card(
          color: primary.c,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    cartItem.image,
                    height: 120,
                    width: 95.5,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: 95.5,
                      color: primary.c,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.service_name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: cartItem.rating?.toDouble() ?? 0.0,
                            itemBuilder: (_, __) =>
                                const Icon(Icons.star, color: gradientgreen2.c),
                            itemCount: 5,
                            itemSize: 23.0,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            cartItem.rating.toString(),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward,
                              size: 15, color: gradientgreen2.c),
                          Text(
                            "${cartItem.discount}%",
                            style: TextStyle(
                                color: gradientgreen2.c, fontSize: 14),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "₹${formatPrice(cartItem.original_price)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "₹${formatPrice(cartItem.price)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (cartItem.service_type == "Hour")
                            const Text("/hour",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showRemoveBottomSheet,
                              child: Container(
                                height: 30,
                                color: primary.c,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/icons/can.png",
                                        height: 20, width: 20),
                                    const SizedBox(width: 10),
                                    const Text("Remove",
                                        style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: const Color.fromARGB(255, 200, 200, 200),
                            height: 32,
                            width: 1.5,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final cartSnapshot = await FirebaseFirestore
                                    .instance
                                    .collection('carts')
                                    .doc(user.uid)
                                    .collection('cartItems')
                                    .get();

                                if (cartSnapshot.docs.isEmpty) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.white,
                                      content: Text(
                                        "🛒 Cart is empty. Add services before booking.",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                for (var doc in cartSnapshot.docs) {
                                  final data = doc.data();

                                  try {
                                    final category = data['category'] ?? '';

                                    final bookingData = {
                                      'userId': user.uid,
                                      'serviceTitle': data['serviceName'] ?? '',
                                      'image': data['image'] ?? '',
                                      'originalPrice':
                                          data['original_price'] ?? '',
                                      'discountPrice': data['price'] ?? '',
                                      'discount': data['discount'] ?? '',
                                      'rating': data['rating'] ?? 0,
                                      'category': category,
                                      'serviceType': data['serviceType'] ?? '',
                                      'bookingType': 'Exterior',
                                      'status': 'pending', // not yet assigned
                                      'workerId': null,
                                      'workerName': null,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    };

                                    // Add booking to Firestore
                                    await FirebaseFirestore.instance
                                        .collection('bookings')
                                        .add(bookingData);

                                    // Remove the item from cart
                                    await doc.reference.delete();

                                    // Show success message
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.white,
                                        content: Text(
                                          "✅ Booking request for ${data['serviceName']} submitted.",
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print("Booking error: $e");

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color.fromARGB(
                                            255, 204, 175, 175),
                                        content: Text(
                                          "⚠️ Failed to book ${data['serviceName']}.",
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                height: 30,
                                color: primary.c,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/icons/booking.png",
                                        height: 20, width: 20),
                                    const SizedBox(width: 10),
                                    const Text("Book now"),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

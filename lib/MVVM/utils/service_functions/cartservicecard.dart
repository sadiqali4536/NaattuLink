import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Exterior_Bookingpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Home_Booking_Page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Interior_Booking_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pet_Bookingpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/vehicle_booking_page.dart';
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

  void _navigateToBookingPage() {
    final cartItem = widget.cartItem;
    Widget? targetPage;

    switch (cartItem.category) {
      case 'Exterior':
        targetPage = ExteriorBookingpage(
          category: cartItem.category,
          serviceName: cartItem.service_name,
          rating: cartItem.rating,
          originalPrice: cartItem.original_price,
          discount: cartItem.discount,
          image: cartItem.image,
          discountPrice: cartItem.price,
          serviceType: cartItem.service_type,
        );
        break;
      case 'Interior':
        targetPage = InteriorBookingPage(
          category: cartItem.category,
          serviceName: cartItem.service_name,
          rating: cartItem.rating,
          originalPrice: cartItem.original_price,
          discount: cartItem.discount,
          image: cartItem.image,
          discountPrice: cartItem.price,
          serviceType: cartItem.service_type,
        );
        break;
      case 'Vehicle':
        targetPage = VehicleBookingPage(
          category: cartItem.category,
          serviceName: cartItem.service_name,
          rating: cartItem.rating,
          originalPrice: cartItem.original_price,
          discount: cartItem.discount,
          image: cartItem.image,
          discountPrice: cartItem.price,
          serviceType: cartItem.service_type,
        );
        break;
      case 'Pet':
        targetPage = PetCleaning(
          category: cartItem.category,
          serviceName: cartItem.service_name,
          rating: cartItem.rating,
          originalPrice: cartItem.original_price,
          discount: cartItem.discount,
          image: cartItem.image,
          discountPrice: cartItem.price,
          serviceType: cartItem.service_type,
        );
        break;
      case 'Home':
        targetPage = HomeBookingPage(
          category: cartItem.category,
          serviceName: cartItem.service_name,
          rating: cartItem.rating,
          originalPrice: cartItem.original_price,
          discount: cartItem.discount,
          image: cartItem.image,
          discountPrice: cartItem.price,
          serviceType: cartItem.service_type,
        );
        break;
    }

    if (targetPage != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItem = widget.cartItem;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: _navigateToBookingPage,
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
                              onTap: _removeItemFromCart,
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

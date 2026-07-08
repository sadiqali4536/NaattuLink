// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get_navigation/src/extension_navigation.dart';
// import 'package:naattulink/MVVM/View/Screen/User/Booking_page/booking_confirm.dart';
// import 'package:naattulink/MVVM/utils/Constants/colors.dart';
// import 'package:naattulink/MVVM/utils/service_functions/cartservicecard.dart';
// import 'package:naattulink/MVVM/model/models/cart_model.dart';
// import 'package:naattulink/MVVM/utils/service_functions/servicecard2.dart';

// class CartPage extends StatefulWidget {
//   String? serviceName;
//   String? image;
//   String? originalPrice;
//   String? discountPrice;
//   String? discount;
//   int? rating;
//   String? category;
//   String? serviceType;

//   CartPage({
//     Key? key,
//     this.serviceName,
//     this.image,
//     this.originalPrice,
//     this.discountPrice,
//     this.discount,
//     this.rating,
//     this.category,
//     this.serviceType,
//   }) : super(key: key);

//   @override
//   _CartPageState createState() => _CartPageState();
// }

// class _CartPageState extends State<CartPage> {
//   bool isExpanded = false;

//   bool _isDialogShown = false;

//   void showLoadingDialog(BuildContext context) {
//     if (_isDialogShown) return; // Prevent multiple dialogs

//     _isDialogShown = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return AlertDialog(
//           content: Row(
//             children: const [
//               CircularProgressIndicator(color: Colors.green),
//               SizedBox(width: 20),
//               Text("Booking..."),
//             ],
//           ),
//         );
//       },
//     ).then((_) {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text("My Cart", style: TextStyle(color: Colors.white)),
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color.fromARGB(255, 102, 214, 10),
//                   Color.fromARGB(255, 113, 191, 4),
//                   Color.fromARGB(255, 26, 159, 6),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: const Center(
//           child: Text('Please log in to view your cart.'),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color.fromRGBO(246, 246, 246, 1),
//       body: Stack(
//         children: [
//           StreamBuilder(
//             stream: FirebaseFirestore.instance
//                 .collection('carts')
//                 .doc(user.uid)
//                 .collection('cartItems')
//                 .orderBy('addedAt', descending: true)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (snapshot.hasError) {
//                 if (kDebugMode) {
//                   print('Firestore Stream Error: ${snapshot.error}');
//                 }
//                 return Center(
//                     child: Text('Error loading cart: ${snapshot.error}'));
//               }

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                 return SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildHeader(),
//                       const SizedBox(height: 150),
//                       Center(
//                           child: Image.asset("assets/icons/emptycart.jpeg",
//                               scale: 3.5)),
//                     ],
//                   ),
//                 );
//               }

//               final cartItems = snapshot.data!.docs.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>? ?? {};
//                 return CartModel.fromFirestore(data);
//               }).toList();

//               return SingleChildScrollView(
//                 padding: const EdgeInsets.only(bottom: 280),
//                 child: Column(
//                   children: [
//                     _buildHeader(),
//                     const SizedBox(height: 10),
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: cartItems.length,
//                       itemBuilder: (context, index) {
//                         final cartItem = cartItems[index];
//                         return Cartservicecard(cartItem: cartItem);
//                       },
//                     ),
//                     Servicecard2(category: "interior"),
//                   ],
//                 ),
//               );
//             },
//           ),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 700),
//                     curve: Curves.easeInOut,
//                     height: isExpanded ? 270 : 0,
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(15),
//                         topRight: Radius.circular(15),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           blurRadius: 6,
//                           offset: const Offset(0, -2),
//                         ),
//                       ],
//                     ),
//                     child: isExpanded
//                         ? StreamBuilder<QuerySnapshot>(
//                             stream: FirebaseFirestore.instance
//                                 .collection('carts')
//                                 .doc(user.uid)
//                                 .collection('cartItems')
//                                 .snapshots(),
//                             builder: (context, snapshot) {
//                               double currentTotalPrice = 0;
//                               double currentTotalOriginalPrice = 0;
//                               int currentServiceCount = 0;

//                               if (snapshot.hasData &&
//                                   snapshot.data!.docs.isNotEmpty) {
//                                 currentServiceCount =
//                                     snapshot.data!.docs.length;
//                                 for (var doc in snapshot.data!.docs) {
//                                   final data =
//                                       doc.data() as Map<String, dynamic>? ?? {};
//                                   currentTotalPrice += double.tryParse(
//                                           data["price"]?.toString() ?? "0") ??
//                                       0;
//                                   currentTotalOriginalPrice += double.tryParse(
//                                           data["original_price"]?.toString() ??
//                                               "0") ??
//                                       0;
//                                 }
//                               }

//                               double currentDiscount =
//                                   currentTotalOriginalPrice - currentTotalPrice;

//                               return Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: SingleChildScrollView(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const SizedBox(height: 5),
//                                       const Center(
//                                         child: Text(
//                                           "Price Details",
//                                           style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(
//                                               "Price ($currentServiceCount Bookings)",
//                                               style: const TextStyle(
//                                                   fontSize: 15)),
//                                           Text(
//                                             "₹${currentTotalOriginalPrice.toStringAsFixed(0)}",
//                                             style:
//                                                 const TextStyle(fontSize: 15),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 5),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           const Text("Discount",
//                                               style: TextStyle(fontSize: 15)),
//                                           Text(
//                                             "-₹${currentDiscount.toStringAsFixed(0)}",
//                                             style: TextStyle(
//                                                 fontSize: 15,
//                                                 color: gradientgreen2.c),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           const Text("Total Amount",
//                                               style: TextStyle(
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.bold)),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             children: [
//                                               if (currentDiscount > 0)
//                                                 Text(
//                                                   "₹${currentTotalOriginalPrice.toStringAsFixed(0)}",
//                                                   style: const TextStyle(
//                                                     decoration: TextDecoration
//                                                         .lineThrough,
//                                                     color: Colors.grey,
//                                                   ),
//                                                 ),
//                                               Text(
//                                                 "₹${currentTotalPrice.toStringAsFixed(0)}",
//                                                 style: const TextStyle(
//                                                     fontSize: 18,
//                                                     fontWeight:
//                                                         FontWeight.bold),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 40),
//                                       Center(
//                                         child: SizedBox(
//                                           height: 40,
//                                           width: 150,
//                                           child: ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               backgroundColor: gradientgreen2.c,
//                                             ),
//                                             onPressed: () async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;

//   final cartSnapshot = await FirebaseFirestore.instance
//       .collection('carts')
//       .doc(user.uid)
//       .collection('cartItems')
//       .get();

//   if (cartSnapshot.docs.isEmpty) {
//     if (!context.mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         backgroundColor: Colors.white,
//         content: Text(
//           "🛒 Cart is empty. Add services before booking.",
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//     );
//     return;
//   }

//   showLoadingDialog(context);

//   List<Map<String, dynamic>> bookedItems = [];

//   try {
//     for (var doc in cartSnapshot.docs) {
//       final data = doc.data();

//       final bookingData = {
//         'userId': user.uid,
//         'serviceTitle': data['service_name'] ?? '',
//         'image': data['image'] ?? '',
//         'originalPrice': data['original_price'] ?? '',
//         'discountPrice': data['price'] ?? '',
//         'discount': data['discount'] ?? '',
//         'rating': data['rating'] ?? 0,
//         'category': data['category'] ?? '',
//         'serviceType': data['serviceType'] ?? '',
//         'bookingType': 'Exterior',
//         'status': 'pending',
//         'workerId': null,
//         'workerName': null,
//         'createdAt': FieldValue.serverTimestamp(),
//       };

//       await FirebaseFirestore.instance.collection('bookings').add(bookingData);
//       await doc.reference.delete();

//       bookedItems.add({
//         // 'serviceTitle': data['service_name'] ?? '',
//         // 'image': data['image'] ?? '',
//         // 'discountPrice': data['price'] ?? '',
//         // 'category': data['category'] ?? '',
//         // 'serviceType': data['serviceType'] ?? '',
//         'userId': user.uid,
//         'serviceTitle': data['service_name'] ?? '',
//         'image': data['image'] ?? '',
//         'originalPrice': data['original_price'] ?? '',
//         'discountPrice': data['price'] ?? '',
//         'discount': data['discount'] ?? '',
//         'rating': data['rating'] ?? 0,
//         'category': data['category'] ?? '',
//         'serviceType': data['serviceType'] ?? '',
//         'bookingType': 'Exterior',
//         'status': 'pending',
//         'workerId': null,
//         'workerName': null,
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//     }
//   } catch (e) {
//     if (!context.mounted) return;
//     if (_isDialogShown) {
//       Navigator.of(context, rootNavigator: true).pop();
//       _isDialogShown = false;
//     }
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: const Color.fromARGB(255, 204, 175, 175),
//         content: const Text(
//           "⚠️ Failed to book service.",
//           style: TextStyle(color: Colors.black),
//         ),
//       ),
//     );
//   }

//   await Future.delayed(const Duration(milliseconds: 300));

//   if (bookedItems.isNotEmpty && context.mounted) {
//     if (_isDialogShown) {
//       Navigator.of(context, rootNavigator: true).pop();
//       _isDialogShown = false;
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       isDismissible: false,
//       enableDrag: false,
//       backgroundColor: Colors.transparent,
//       builder: (_) => BookingConfirmationModal(
//         bookedItems: bookedItems,
//         onDonePressed: () {
//           Navigator.of(context).pop();
//         },
//       ),
//     );
//   }
// },

//                                             child: const Text("Book Now",
//                                                 style: TextStyle(
//                                                     color: Colors.white)),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           )
//                         : const SizedBox(),
//                   ),
//                   const SizedBox(height: 80),
//                 ],
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 15,
//             right: 10,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 80),
//               child: FloatingActionButton.small(
//                 backgroundColor: gradientgreen2.c,
//                 onPressed: () {
//                   setState(() {
//                     isExpanded = !isExpanded;
//                   });
//                 },
//                 child: Icon(
//                   isExpanded
//                       ? Icons.keyboard_arrow_down
//                       : Icons.keyboard_arrow_up,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       height: 80,
//       width: double.infinity,
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//         gradient: LinearGradient(
//           colors: [
//             Color.fromARGB(255, 102, 214, 10),
//             Color.fromARGB(255, 113, 191, 4),
//             Color.fromARGB(255, 26, 159, 6),
//           ],
//         ),
//       ),
//       padding: const EdgeInsets.only(top: 30),
//       child: const Center(
//         child: Text(
//           "My Cart",
//           style: TextStyle(
//             fontSize: 20,
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/booking_confirm.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/service_functions/cartservicecard.dart';
import 'package:naattulink/MVVM/model/models/cart_model.dart';
import 'package:naattulink/MVVM/utils/service_functions/servicecard2.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class CartPage extends StatefulWidget {
  String? serviceName;
  String? image;
  String? originalPrice;
  String? discountPrice;
  String? discount;
  int? rating;
  String? category;
  String? serviceType;

  CartPage({
    Key? key,
    this.serviceName,
    this.image,
    this.originalPrice,
    this.discountPrice,
    this.discount,
    this.rating,
    this.category,
    this.serviceType,
  }) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isExpanded = false;
  bool _isDialogShown = false;

  void showLoadingDialog(BuildContext context) {
    if (_isDialogShown) return;

    _isDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 20),
              Text("Booking..."),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Cart", style: TextStyle(color: Colors.white)),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 102, 214, 10),
                  Color.fromARGB(255, 113, 191, 4),
                  Color.fromARGB(255, 26, 159, 6),
                ],
              ),
            ),
          ),
        ),
        body: const Center(
          child: Text('Please log in to view your cart.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(246, 246, 246, 1),
      body: Stack(
        children: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('carts')
                .doc(user.uid)
                .collection('cartItems')
                .orderBy('addedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                if (kDebugMode) {
                  print('Firestore Stream Error: ${snapshot.error}');
                }
                return Center(
                    child: Text('Error loading cart: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ServiceCardListSkeleton();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 150),
                      Center(
                        child: Image.asset(
                          "assets/icons/emptycart.jpeg",
                          scale: 3.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final cartItems = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return CartModel.fromFirestore(data);
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 280),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        return Cartservicecard(cartItem: cartItem);
                      },
                    ),
                    const SizedBox(height: 10),
                    Servicecard2(category: "interior"),
                  ],
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    height: isExpanded ? 270 : 0,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: isExpanded
                        ? StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('carts')
                                .doc(user.uid)
                                .collection('cartItems')
                                .snapshots(),
                            builder: (context, snapshot) {
                              double currentTotalPrice = 0;
                              double currentTotalOriginalPrice = 0;
                              int currentServiceCount = 0;

                              if (snapshot.hasData &&
                                  snapshot.data!.docs.isNotEmpty) {
                                currentServiceCount =
                                    snapshot.data!.docs.length;
                                for (var doc in snapshot.data!.docs) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  currentTotalPrice += double.tryParse(
                                          data["price"]?.toString() ?? "0") ??
                                      0;
                                  currentTotalOriginalPrice += double.tryParse(
                                          data["original_price"]?.toString() ??
                                              "0") ??
                                      0;
                                }
                              }

                              double currentDiscount =
                                  currentTotalOriginalPrice - currentTotalPrice;

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          "Price Details",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              "Price ($currentServiceCount Bookings)",
                                              style: const TextStyle(
                                                  fontSize: 15)),
                                          Text(
                                            "₹${currentTotalOriginalPrice.toStringAsFixed(0)}",
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Discount",
                                              style: TextStyle(fontSize: 15)),
                                          Text(
                                            "-₹${currentDiscount.toStringAsFixed(0)}",
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: gradientgreen2.c),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Total Amount",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              if (currentDiscount > 0)
                                                Text(
                                                  "₹${currentTotalOriginalPrice.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Text(
                                                "₹${currentTotalPrice.toStringAsFixed(0)}",
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 40),
                                      Center(
                                        child: SizedBox(
                                          height: 40,
                                          width: 150,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              backgroundColor: gradientgreen2.c,
                                            ),
                                            onPressed: () async {
                                              final user = FirebaseAuth
                                                  .instance.currentUser;
                                              if (user == null) return;

                                              final cartSnapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('carts')
                                                      .doc(user.uid)
                                                      .collection('cartItems')
                                                      .get();

                                              if (cartSnapshot.docs.isEmpty) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Colors.white,
                                                    content: Text(
                                                      "🛒 Cart is empty. Add services before booking.",
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              showLoadingDialog(context);

                                              List<Map<String, dynamic>>
                                                  bookedItems = [];

                                              try {
                                                for (var doc
                                                    in cartSnapshot.docs) {
                                                  final data = doc.data();
                                                  final category =
                                                      data['category']
                                                              ?.toString()
                                                              .toLowerCase() ??
                                                          '';

                                                  String bookingType =
                                                      switch (category) {
                                                    'garden' => 'Garden',
                                                    'home' => 'Home',
                                                    'room' => 'Room',
                                                    'vehicle' => 'Vehicle',
                                                    'pet' => 'Pet',
                                                    'interior' => 'Interior',
                                                    'exterior' => 'Exterior',
                                                    _ => 'Custom',
                                                  };

                                                  final bookingData = {
                                                    'userId': user.uid,
                                                    'serviceId':
                                                        data['service_id'] ??
                                                            '',
                                                    'serviceTitle':
                                                        data['service_name'] ??
                                                            '',
                                                    'image':
                                                        data['image'] ?? '',
                                                    'originalPrice': data[
                                                            'original_price'] ??
                                                        '',
                                                    'discountPrice':
                                                        data['price'] ?? '',
                                                    'discount':
                                                        data['discount'] ?? '',
                                                    'rating':
                                                        data['rating'] ?? 0,
                                                    'category':
                                                        data['category'] ?? '',
                                                    'serviceType':
                                                        data['service_type'] ??
                                                            '',
                                                    'bookingType': bookingType,
                                                    'status': 'pending',
                                                    'workerId': null,
                                                    'workerName': null,
                                                    'addedAt': data[
                                                            'addedAt'] ??
                                                        FieldValue
                                                            .serverTimestamp(),
                                                    'createdAt': FieldValue
                                                        .serverTimestamp(),
                                                    'selectedDate':
                                                        data['selectedDate'] ??
                                                            '',
                                                    'selectedTime':
                                                        data['selectedTime'] ??
                                                            '',
                                                  };

                                                  // Add conditional data for category-specific fields
                                                  if (category == 'garden') {
                                                    bookingData['gardenSize'] =
                                                        data['gardenSize'] ??
                                                            '';
                                                  } else if (category ==
                                                      'home') {
                                                    bookingData['homeSize'] =
                                                        data['homeSize'] ?? '';
                                                  } else if (category ==
                                                      'room') {
                                                    bookingData['roomType'] =
                                                        data['roomType'] ?? '';
                                                  } else if (category ==
                                                      'vehicle') {
                                                    bookingData[
                                                            'vehicleCleaningType'] =
                                                        data['vehicleCleaningType'] ??
                                                            '';
                                                    bookingData['vehicleType'] =
                                                        data['vehicleType'] ??
                                                            '';
                                                    bookingData[
                                                            'vehicleCategory'] =
                                                        data['vehicleCategory'] ??
                                                            '';
                                                  } else if (category ==
                                                      'pet') {
                                                    bookingData['petType'] =
                                                        data['petType'] ?? '';
                                                    bookingData['petCount'] =
                                                        data['petCount'] ?? '';
                                                  }

                                                  // Add the booking to Firestore
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('bookings')
                                                      .add(bookingData);

                                                  // Remove from cart
                                                  await doc.reference.delete();

                                                  // Track for confirmation modal
                                                  bookedItems.add(bookingData);
                                                }
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                if (_isDialogShown) {
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                  _isDialogShown = false;
                                                }
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor:
                                                        Color.fromARGB(
                                                            255, 204, 175, 175),
                                                    content: Text(
                                                      "⚠️ Failed to book service.",
                                                      style: TextStyle(
                                                          color: Colors.black),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 300));

                                              if (bookedItems.isNotEmpty &&
                                                  context.mounted) {
                                                if (_isDialogShown) {
                                                  Navigator.of(context,
                                                          rootNavigator: true)
                                                      .pop();
                                                  _isDialogShown = false;
                                                }

                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  isDismissible: false,
                                                  enableDrag: false,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (_) =>
                                                      BookingConfirmationModal(
                                                    bookedItems: bookedItems,
                                                    onDonePressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text("Book Now",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const SizedBox(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 10,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.small(
                backgroundColor: gradientgreen2.c,
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 102, 214, 10),
            Color.fromARGB(255, 113, 191, 4),
            Color.fromARGB(255, 26, 159, 6),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 30),
      child: const Center(
        child: Text(
          "My Cart",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:swiftclean_project/MVVM/View/Screen/User/cart/cart_service.dart';
// import 'package:swiftclean_project/MVVM/View/Screen/User/cart/cart_service.dart' as CartService;
// import 'package:swiftclean_project/MVVM/model/models/cart_model.dart';
// import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
// import 'package:swiftclean_project/MVVM/utils/widget/backbutton/custombackbutton.dart';
// import 'package:swiftclean_project/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

// class HomeBookingPage extends StatefulWidget {
//   final String? serviceId;
//   String? serviceName;
//   String? image;
//   String? originalPrice;
//   String? discountPrice;
//   String? discount;
//   int? rating;
//   String? category;
//   String? serviceType;
//   HomeBookingPage({
//     super.key,
//     this.serviceId,
//     this.serviceName,
//     this.image,
//     this.originalPrice,
//     this.discountPrice,
//     this.discount,
//     this.rating,
//     this.category,
//     this.serviceType,
//   });

//   @override
//   State<HomeBookingPage> createState() => _HomeBookingPageState();
// }

// class _HomeBookingPageState extends State<HomeBookingPage> {
//    final TextEditingController _homeSizeController = TextEditingController();
//   DateTime selectedDate = DateTime.now();
//   int selectedIndex = 0;
//   bool isAddedToCart = false;

//   int hour = DateTime.now().hour % 12;
//   int minute = DateTime.now().minute;
//   String meridiem = 'AM';

//   @override
//   void initState() {
//     super.initState();
//     checkIfServiceInCart();
//   }
//    @override
//   void dispose() {
//     _homeSizeController.dispose();
//     super.dispose();
//   }

//   bool isBookingFormComplete() {
//     if (widget.serviceName == null ||
//         widget.category == null ||
//         widget.serviceType == null ||
//         widget.discountPrice == null ||
//         (_homeSizeController.text.isEmpty ||
//             int.tryParse(_homeSizeController.text) == null) ||
//         hour < 1 ||
//         hour > 12 ||
//         minute < 0 ||
//         minute > 59 ||
//         meridiem.isEmpty) {
//       return false;
//     }

//     int convertedHour = hour;
//     if (meridiem == 'PM' && hour != 12) convertedHour += 12;
//     if (meridiem == 'AM' && hour == 12) convertedHour = 0;

//     DateTime selectedDateTime = DateTime(
//       selectedDate.year,
//       selectedDate.month,
//       selectedDate.day,
//       convertedHour,
//       minute,
//     );

//     return selectedDateTime.isAfter(DateTime.now());
//   }

//   Future<void> checkIfServiceInCart() async {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) return;

//     final cartRef = FirebaseFirestore.instance
//         .collection('carts')
//         .doc(userId)
//         .collection('cartItems');

//     final existing = await cartRef
//         .where('serviceName', isEqualTo: widget.serviceName)
//         .where('category', isEqualTo: widget.category)
//         .where('serviceType', isEqualTo: widget.serviceType)
//         .get();

//     if (mounted) {
//       setState(() {
//         isAddedToCart = existing.docs.isNotEmpty;
//       });
//     }
//   }

//   /// Get next 30 dates
//   List<DateTime> getWeekDates() {
//     final today = DateTime.now();
//     return List.generate(30, (index) => today.add(Duration(days: index)));
//   }

//   /// Convert numeric month to name
//   String _getMonthName(int month) {
//     const monthNames = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December'
//     ];
//     return monthNames[month - 1];
//   }

//   /// Time controls
//   void incrementHour() {
//     setState(() {
//       if (hour == 11) {
//         hour = 12;
//         meridiem = meridiem == 'AM' ? 'PM' : 'AM';
//       } else if (hour == 12) {
//         hour = 1;
//       } else {
//         hour++;
//       }
//     });
//   }

//   void decrementHour() {
//     setState(() {
//       if (hour == 12) {
//         hour = 11;
//       } else if (hour == 1) {
//         hour = 12;
//         meridiem = meridiem == 'AM' ? 'PM' : 'AM';
//       } else {
//         hour--;
//       }
//     });
//   }

//   void incrementMinute() {
//     setState(() {
//       minute += 5;
//       if (minute >= 60) {
//         minute = 0;
//         incrementHour();
//       }
//     });
//   }

//   void decrementMinute() {
//     setState(() {
//       minute -= 5;
//       if (minute < 0) {
//         minute = 59;
//         decrementHour();
//       }
//     });
//   }

//   void toggleMeridiem(String value) {
//     setState(() {
//       meridiem = value;
//     });
//   }

//   /// Format date/time for display
//   String get formattedDate {
//     final date = selectedDate;
//     return '${DateFormat.E().format(date)}, ${DateFormat.MMMd().format(date)}';
//   }

//   String get formattedTime {
//     return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
//   }

//  @override
// Widget build(BuildContext context) {
//   final weekDates = getWeekDates();

//   return Scaffold(
//     body: Stack(
//       children: [
//         SingleChildScrollView(
//           child: Column(
//             children: [
//               Image.asset("assets/image/home_cleaning.png",
//                   width: double.infinity),
//               Container(
//                 width: 440,
//                 decoration: BoxDecoration(
//                   color: const Color.fromARGB(255, 250, 249, 249),
//                 ),
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Home Size",
//                           style: TextStyle(
//                               fontSize: 20, fontWeight: FontWeight.w500)),

//                       TextFormField(
//                           controller: _homeSizeController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             hintText: "Enter home area in sq.ft",
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                           ),
//                         ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text("Select Date",
//                               style: TextStyle(
//                                   fontSize: 20, fontWeight: FontWeight.w500)),
//                           TextButton(
//                             onPressed: () async {
//                               final pickedDate = await showDatePicker(
//                                 context: context,
//                                 initialDate: selectedDate,
//                                 firstDate: DateTime.now(),
//                                 lastDate:
//                                     DateTime.now().add(Duration(days: 365)),
//                               );
//                               if (pickedDate != null) {
//                                 setState(() {
//                                   selectedDate = pickedDate;
//                                 });
//                               }
//                             },
//                             child: Text("Custom Date",
//                                 style: TextStyle(
//                                     fontSize: 14, color: gradientgreen2.c)),
//                           ),
//                         ],
//                       ),
//                       SizedBox(
//                         height: 100,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: weekDates.length,
//                           itemBuilder: (context, index) {
//                             final date = weekDates[index];
//                             final isSelected = index == selectedIndex;
//                             final monthName = _getMonthName(date.month);
//                             return GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   selectedIndex = index;
//                                   selectedDate = date;
//                                 });
//                               },
//                               child: Container(
//                                 margin: EdgeInsets.symmetric(horizontal: 4),
//                                 padding: EdgeInsets.symmetric(
//                                     horizontal: 18, vertical: 14),
//                                 decoration: BoxDecoration(
//                                   color: isSelected
//                                       ? gradientgreen2.c
//                                       : const Color.fromRGBO(229, 229, 229, 1),
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                                 child: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       DateFormat.E().format(date),
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: isSelected
//                                             ? Colors.white
//                                             : Colors.black,
//                                       ),
//                                     ),
//                                     SizedBox(height: 5),
//                                     Text(
//                                       '${date.day}',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: isSelected
//                                             ? Colors.white
//                                             : Colors.black,
//                                       ),
//                                     ),
//                                     SizedBox(height: 5),
//                                     Text(
//                                       monthName,
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: isSelected
//                                             ? Colors.white
//                                             : Colors.black,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Text("Select Time",
//                           style: TextStyle(
//                               fontSize: 20, fontWeight: FontWeight.w500)),
//                       const SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           // Hour
//                           Column(
//                             children: [
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(30),
//                                 child: IconButton(
//                                   icon: Icon(Icons.add,
//                                       color: gradientgreen2.c),
//                                   onPressed: incrementHour,
//                                 ),
//                               ),
//                               SizedBox(height: 15),
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 14, vertical: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     boxShadow: [
//                                       BoxShadow(
//                                           color: Colors.grey.shade300,
//                                           blurRadius: 4)
//                                     ],
//                                   ),
//                                   child: Text(
//                                       hour.toString().padLeft(2, '0'),
//                                       style: TextStyle(fontSize: 18)),
//                                 ),
//                               ),
//                               SizedBox(height: 15),
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(30),
//                                 child: IconButton(
//                                   icon: Icon(Icons.remove,
//                                       color: gradientgreen2.c),
//                                   onPressed: decrementHour,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(width: 10),
//                           Text(":", style: TextStyle(fontSize: 22)),
//                           SizedBox(width: 10),
//                           // Minute
//                           Column(
//                             children: [
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(30),
//                                 child: IconButton(
//                                   icon: Icon(Icons.add,
//                                       color: gradientgreen2.c),
//                                   onPressed: incrementMinute,
//                                 ),
//                               ),
//                               SizedBox(height: 15),
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Container(
//                                   padding: EdgeInsets.symmetric(
//                                       horizontal: 14, vertical: 10),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     boxShadow: [
//                                       BoxShadow(
//                                           color: Colors.grey.shade300,
//                                           blurRadius: 4)
//                                     ],
//                                   ),
//                                   child: Text(
//                                       minute.toString().padLeft(2, '0'),
//                                       style: TextStyle(fontSize: 18)),
//                                 ),
//                               ),
//                               SizedBox(height: 15),
//                               Material(
//                                 elevation: 6,
//                                 borderRadius: BorderRadius.circular(30),
//                                 child: IconButton(
//                                   icon: Icon(Icons.remove,
//                                       color: gradientgreen2.c),
//                                   onPressed: decrementMinute,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(width: 30),
//                           TextButton(
//                             style: TextButton.styleFrom(
//                               backgroundColor: meridiem == 'AM'
//                                   ? gradientgreen2.c
//                                   : const Color.fromARGB(255, 231, 231, 231),
//                               foregroundColor: meridiem == 'AM'
//                                   ? Colors.white
//                                   : Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               minimumSize: const Size(52, 42),
//                             ),
//                             onPressed: () => toggleMeridiem('AM'),
//                             child: const Text("AM"),
//                           ),
//                           SizedBox(width: 13),
//                           TextButton(
//                             style: TextButton.styleFrom(
//                               backgroundColor: meridiem == 'PM'
//                                   ? gradientgreen2.c
//                                   : const Color.fromARGB(255, 231, 231, 231),
//                               foregroundColor: meridiem == 'PM'
//                                   ? Colors.white
//                                   : Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               minimumSize: const Size(52, 42),
//                             ),
//                             onPressed: () => toggleMeridiem('PM'),
//                             child: const Text("PM"),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 100), // Space for FAB
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // Back Button
//         Positioned(
//           top: 10,
//           left: 15,
//           child: SafeArea(
//             child: customBackbutton1(
//               onpress: () => Navigator.pop(context),
//             ),
//           ),
//         ),
//         // Cart Button
//         Positioned(
//           top: 330,
//           left: 320,
//           child: IconButton(
//             icon: isAddedToCart
//                 ? const Icon(Icons.check_circle,
//                     color: gradientgreen2.c, size: 30)
//                 : const Icon(Icons.add_shopping_cart_outlined),
//             onPressed: () async {
//               if (isAddedToCart) return;

//               final userId = FirebaseAuth.instance.currentUser?.uid;
//               if (userId == null) return;

//               final cartRef = FirebaseFirestore.instance
//                   .collection('carts')
//                   .doc(userId)
//                   .collection('cartItems');

//               final existing = await cartRef
//                   .where('serviceName', isEqualTo: widget.serviceName)
//                   .where('category', isEqualTo: widget.category)
//                   .where('serviceType', isEqualTo: widget.serviceType)
//                   .limit(1)
//                   .get();

//               if (existing.docs.isNotEmpty) {
//                 CustomSnackBar.show(
//                   icon: Icons.library_add_check,
//                   iconcolor: Colors.amberAccent,
//                   context: context,
//                   message: "Item already in cart",color: Colors.white);

//                 return;
//               }

//               await CartService.addToCart(
//                 context: context,
//                 serviceName: widget.serviceName,
//                 image: widget.image,
//                 originalPrice: widget.originalPrice,
//                 discountPrice: widget.discountPrice,
//                 discount: widget.discount,
//                 rating: widget.rating,
//                 category: widget.category,
//                 serviceType: widget.serviceType,
//               );

//               setState(() => isAddedToCart = true);

//             },

//           ),
//         ),
//       ],
//     ),
//     floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     floatingActionButton: Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Row(
//         children: [
//           Text("₹", style: TextStyle(color: Colors.white, fontSize: 30)),
//           SizedBox(width: 5),
//           Text("${widget.discountPrice}",
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 30,
//                   fontWeight: FontWeight.bold)),
//           Text("/Day",
//               style: TextStyle(color: Colors.grey[400], fontSize: 20)),
//           Spacer(),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: gradientgreen2.c,
//               minimumSize: Size(160, 57),
//             ),
//            onPressed: () async {
//                 final user = FirebaseAuth.instance.currentUser;
//                 if (user == null || !isBookingFormComplete()) return;

//                 try {
//                   final bookingData = {
//                     'userId': user.uid,
//                     'serviceTitle': widget.serviceName ?? '',
//                     'image': widget.image ?? '',
//                     'originalPrice': widget.originalPrice ?? '',
//                     'discountPrice': widget.discountPrice ?? '',
//                     'discount': widget.discount ?? '',
//                     'rating': widget.rating ?? 0,
//                     'category': widget.category ?? '',
//                     'serviceType': widget.serviceType ?? '',
//                     'homeSizeSqFt': int.tryParse(_homeSizeController.text) ?? 0,
//                     'selectedDate': selectedDate,
//                     'selectedTime': formattedTime,
//                     'bookingType': 'Interior',
//                     'status': 'booked',
//                     'createdAt': FieldValue.serverTimestamp(),
//                   };

//                   await FirebaseFirestore.instance.collection('bookings').add(bookingData);
//                   if (!mounted) return;
//                   CustomSnackBar.show(
//                     useTick: true,
//                     context: context,
//                     message: "Booking request for ${widget.serviceName} submitted.",
//                     color: Colors.white,
//                   );
//                 } catch (e) {
//                   if (!mounted) return;
//                   CustomSnackBar.show(
//                     icon: Icons.error,
//                     context: context,
//                     message: "Failed to book ${widget.serviceName}.",
//                     color: Colors.white,
//                   );
//                 }
//               },
//             child: Text("Book Now",
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.bold)),
//           )
//         ],
//       ),
//     ),
//   );
// }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/cart/cart_service.dart'
    as CartService;
import 'package:swiftclean_project/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:swiftclean_project/MVVM/model/models/cart_model.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:swiftclean_project/MVVM/utils/widget/custom_message_dialog/customsnakbar.dart';

class HomeBookingPage extends StatefulWidget {
  final String? serviceId;
  String? serviceName;
  String? image;
  String? originalPrice;
  String? discountPrice;
  String? discount;
  int? rating;
  String? category;
  String? serviceType;
  HomeBookingPage({
    super.key,
    this.serviceId,
    this.serviceName,
    this.image,
    this.originalPrice,
    this.discountPrice,
    this.discount,
    this.rating,
    this.category,
    this.serviceType,
  });

  @override
  State<HomeBookingPage> createState() => _HomeBookingPageState();
}

class _HomeBookingPageState extends State<HomeBookingPage> {
  final TextEditingController _homeSizeController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int selectedIndex = 0;
  bool isAddedToCart = false;

  int hour = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int minute = DateTime.now().minute;
  String meridiem = DateTime.now().hour >= 12 ? 'PM' : 'AM';

  @override
  void initState() {
    super.initState();
    checkIfServiceInCart();
    RecommendationController.to.trackProductView(widget.serviceId ?? widget.serviceName ?? '');
  }

  @override
  void dispose() {
    _homeSizeController.dispose();
    super.dispose();
  }

  bool isBookingFormComplete() {
    if (widget.serviceName == null ||
        widget.category == null ||
        widget.serviceType == null ||
        widget.discountPrice == null ||
        _homeSizeController.text.isEmpty ||
        int.tryParse(_homeSizeController.text) == null) {
      return false;
    }

    int? parsedSize = int.tryParse(_homeSizeController.text);
    if (parsedSize == null || parsedSize <= 0) {
      return false;
    }

    if (hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59 ||
        meridiem.isEmpty) {
      return false;
    }

    int convertedHour = hour;
    if (meridiem == 'PM' && hour != 12) convertedHour += 12;
    if (meridiem == 'AM' && hour == 12) convertedHour = 0;

    DateTime selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      convertedHour,
      minute,
    );

    if (selectedDateTime.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  Future<void> checkIfServiceInCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('cartItems');

    final existing = await cartRef
        .where('serviceName', isEqualTo: widget.serviceName)
        .where('category', isEqualTo: widget.category)
        .where('serviceType', isEqualTo: widget.serviceType)
        .get();

    if (mounted) {
      setState(() {
        isAddedToCart = existing.docs.isNotEmpty;
      });
    }
  }

  List<DateTime> getWeekDates() {
    final today = DateTime.now();
    return List.generate(30, (index) => today.add(Duration(days: index)));
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  void incrementHour() {
    setState(() {
      if (hour == 11) {
        hour = 12;
        meridiem = meridiem == 'AM' ? 'PM' : 'AM';
      } else if (hour == 12) {
        hour = 1;
      } else {
        hour++;
      }
    });
  }

  void decrementHour() {
    setState(() {
      if (hour == 12) {
        hour = 11;
      } else if (hour == 1) {
        hour = 12;
        meridiem = meridiem == 'AM' ? 'PM' : 'AM';
      } else {
        hour--;
      }
    });
  }

  void incrementMinute() {
    setState(() {
      minute += 5;
      if (minute >= 60) {
        minute = 0;
        incrementHour();
      }
    });
  }

  void decrementMinute() {
    setState(() {
      minute -= 5;
      if (minute < 0) {
        minute = 59;
        decrementHour();
      }
    });
  }

  void toggleMeridiem(String value) {
    setState(() {
      meridiem = value;
    });
  }

  String get formattedDate {
    final date = selectedDate;
    return '${DateFormat.E().format(date)}, ${DateFormat.MMMd().format(date)}';
  }

  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = getWeekDates();

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/image/home_cleaning.png",
                    width: double.infinity),
                Container(
                  width: 440,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 250, 249, 249),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Home Size",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500)),
                            IconButton(
                              icon: isAddedToCart
                                  ? const Icon(Icons.check_circle,
                                      color: gradientgreen2.c, size: 30)
                                  : const Icon(
                                      Icons.add_shopping_cart_outlined),
                              onPressed: () async {
                                if (isAddedToCart) return;

                                if (!isBookingFormComplete()) {
                                  CustomSnackBar.show(
                                      iconcolor: erroriconcolor,
                                      icon: Icons.cancel,
                                      context: context,
                                      message:
                                          " Please fill the booking before adding to cart.",
                                      color: const Color.fromARGB(
                                          255, 249, 246, 246));
                                  return;
                                }

                                final userId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (userId == null) return;

                                final cartRef = FirebaseFirestore.instance
                                    .collection('carts')
                                    .doc(userId)
                                    .collection('cartItems');

                                final existing = await cartRef
                                    .where('serviceName',
                                        isEqualTo: widget.serviceName)
                                    .where('category',
                                        isEqualTo: widget.category)
                                    .where('serviceType',
                                        isEqualTo: widget.serviceType)
                                    .limit(1)
                                    .get();

                                if (existing.docs.isNotEmpty) {
                                  CustomSnackBar.show(
                                      icon: Icons.library_add_check,
                                      iconcolor: Colors.amberAccent,
                                      context: context,
                                      message: "Item already in cart",
                                      color: Colors.white);
                                  return;
                                }

                                await CartService.addToCart(
                                  context: context,
                                  serviceName: widget.serviceName,
                                  image: widget.image,
                                  originalPrice: widget.originalPrice,
                                  discountPrice: widget.discountPrice,
                                  discount: widget.discount,
                                  rating: widget.rating,
                                  category: widget.category,
                                  serviceType: widget.serviceType,
                                  selectedDate: null,
                                  selectedTime: '',
                                  gardenSize: null,
                                );

                                setState(() => isAddedToCart = true);
                                RecommendationController.to.trackCart(widget.serviceId ?? widget.serviceName ?? '', true);
                              },
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: _homeSizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Enter home area in sq.ft",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Select Date",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weekDates.length,
                            itemBuilder: (context, index) {
                              final date = weekDates[index];
                              final isSelected = index == selectedIndex;
                              final monthName = _getMonthName(date.month);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                    selectedDate = date;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? gradientgreen2.c
                                        : const Color.fromRGBO(
                                            229, 229, 229, 1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(DateFormat.E().format(date),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          )),
                                      SizedBox(height: 5),
                                      Text('${date.day}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          )),
                                      SizedBox(height: 5),
                                      Text(monthName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text("Select Time",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.add,
                                        color: gradientgreen2.c),
                                    onPressed: incrementHour,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Text(hour.toString().padLeft(2, '0'),
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                SizedBox(height: 15),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c),
                                    onPressed: decrementHour,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10),
                            Text(":", style: TextStyle(fontSize: 22)),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.add,
                                        color: gradientgreen2.c),
                                    onPressed: incrementMinute,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey.shade300,
                                            blurRadius: 4)
                                      ],
                                    ),
                                    child: Text(
                                        minute.toString().padLeft(2, '0'),
                                        style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                SizedBox(height: 15),
                                Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(30),
                                  child: IconButton(
                                    icon: Icon(Icons.remove,
                                        color: gradientgreen2.c),
                                    onPressed: decrementMinute,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 30),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: meridiem == 'AM'
                                    ? gradientgreen2.c
                                    : const Color.fromARGB(255, 231, 231, 231),
                                foregroundColor: meridiem == 'AM'
                                    ? Colors.white
                                    : Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size(52, 42),
                              ),
                              onPressed: () => toggleMeridiem('AM'),
                              child: const Text("AM"),
                            ),
                            SizedBox(width: 13),
                            TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: meridiem == 'PM'
                                    ? gradientgreen2.c
                                    : const Color.fromARGB(255, 231, 231, 231),
                                foregroundColor: meridiem == 'PM'
                                    ? Colors.white
                                    : Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size(52, 42),
                              ),
                              onPressed: () => toggleMeridiem('PM'),
                              child: const Text("PM"),
                            ),
                          ],
                        ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            child: SafeArea(
              child: customBackbutton1(onpress: () => Navigator.pop(context)),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Text("₹", style: TextStyle(color: Colors.white, fontSize: 30)),
            SizedBox(width: 5),
            Text("${widget.discountPrice}",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold)),
            Text("/Day",
                style: TextStyle(color: Colors.grey[400], fontSize: 20)),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gradientgreen2.c,
                minimumSize: Size(160, 57),
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                if (!isBookingFormComplete()) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24.0, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: erroriconcolor, size: 40),
                              SizedBox(height: 12),
                              Text(
                                "Please fill the booking before booking.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  return;
                }

                try {
                  final bookingData = {
                    'userId': user.uid,
                    'serviceTitle': widget.serviceName ?? '',
                    'image': widget.image ?? '',
                    'originalPrice': widget.originalPrice ?? '',
                    'discountPrice': widget.discountPrice ?? '',
                    'discount': widget.discount ?? '',
                    'rating': widget.rating ?? 0,
                    'category': widget.category ?? '',
                    'serviceType': widget.serviceType ?? '',
                    'homeSizeSqFt': int.tryParse(_homeSizeController.text) ?? 0,
                    'selectedDate': selectedDate,
                    'selectedTime': formattedTime,
                    'bookingType': 'Interior',
                    'status': 'booked',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .add(bookingData);
                  RecommendationController.to.trackPurchase(
                      [widget.serviceId ?? widget.serviceName ?? ''],
                      double.tryParse(widget.discountPrice ?? '') ?? 0.0);
                  if (!mounted) return;
                  CustomSnackBar.show(
                    useTick: true,
                    context: context,
                    message:
                        "Booking request for ${widget.serviceName} submitted.",
                    color: Colors.white,
                  );
                } catch (e) {
                  if (!mounted) return;
                  CustomSnackBar.show(
                    icon: Icons.error,
                    context: context,
                    message: "Failed to book ${widget.serviceName}.",
                    color: Colors.white,
                  );
                }
              },
              child: Text("Book Now",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

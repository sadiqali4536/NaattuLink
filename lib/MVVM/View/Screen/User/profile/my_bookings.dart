// import 'package:flutter/material.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import 'package:naattulink/MVVM/utils/Constants/colors.dart';
// import 'package:naattulink/MVVM/utils/widget/BottomNavigationbar/BottomNvigationBar.dart';
// import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';

// class MyBookings extends StatelessWidget {
//   const MyBookings({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final maxCardWidth = screenWidth - 32; // 16 padding * 2

//     return Scaffold(
//       body: Column(
//         children: [
//           // Header
//           Container(
//             width: screenWidth,
//             height: 80,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color.fromARGB(255, 102, 214, 10),
//                   Color.fromARGB(255, 113, 191, 4),
//                   Color.fromARGB(255, 26, 159, 6),
//                 ],
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.only(top: 20),
//               child: Row(
//                 children: [
//                   const SizedBox(width: 10),
//                   customBackbutton1(
//                     onpress: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => Bottomnvigationbar()),
//                       );
//                     },
//                   ),
//                   const SizedBox(width: 80),
//                   const Text(
//                     "My Bookings",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 10),

//           // Booking Cards
//           Expanded(
//             child: ListView.builder(
//               itemCount: 2,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               itemBuilder: (context, index) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Material(
//                     elevation: 4,
//                     borderRadius: BorderRadius.circular(10),
//                     child: Container(
//                       height: 145,
//                       width: maxCardWidth,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           // Service Image
//                           Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(10),
//                               child: Image.asset(
//                                 "assets/image/Gardens.png",
//                                 height: 120,
//                                 width: screenWidth * 0.22,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),

//                           // Info Column
//                           Expanded(
//                             child: Padding(
//                               padding: const EdgeInsets.only(top: 25, right: 12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     "Garden",
//                                     style: TextStyle(
//                                       fontSize: 20,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 3),

//                                   // Rating Row
//                                   Row(
//                                     children: [
//                                       RatingBarIndicator(
//                                         rating: 4.8,
//                                         itemBuilder: (_, __) => const Icon(
//                                           Icons.star,
//                                           color: gradientgreen2.c,
//                                         ),
//                                         itemCount: 5,
//                                         itemSize: 20.0,
//                                         direction: Axis.horizontal,
//                                       ),
//                                       const SizedBox(width: 3),
//                                       const Text(
//                                         "4.8",
//                                         style: TextStyle(
//                                           color: gradientgreen2.c,
//                                         ),
//                                       ),
//                                     ],
//                                   ),

//                                   // Price Row
//                                   Row(
//                                     children: const [
//                                       Icon(Icons.arrow_downward,
//                                           size: 15, color: gradientgreen2.c),
//                                       Text("33%", style: TextStyle(color: gradientgreen2.c)),
//                                       SizedBox(width: 5),
//                                       Text(
//                                         "₹299",
//                                         style: TextStyle(
//                                           fontSize: 14,
//                                           color: Colors.grey,
//                                           decoration: TextDecoration.lineThrough,
//                                         ),
//                                       ),
//                                       SizedBox(width: 5),
//                                       Text(
//                                         "₹200",
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       Text("/Hour",
//                                           style: TextStyle(
//                                               fontSize: 16, fontWeight: FontWeight.bold)),
//                                     ],
//                                   ),
//                                   const Text(
//                                     "(Depends on work)",
//                                     style: TextStyle(
//                                         color: Color.fromARGB(255, 139, 138, 138)),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),

//                           // Cancel Button
//                           Padding(
//                             padding: const EdgeInsets.only(top: 1, right: 8, bottom: 15),
//                             child: SizedBox(
//                               width: screenWidth * 0.1,
//                               child: IconButton(
//                                 onPressed: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (BuildContext context) {
//                                       return Dialog(
//                                         shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(20)),
//                                         child: SizedBox(
//                                           height: 240,
//                                           width: 374,
//                                           child: Column(
//                                             mainAxisAlignment: MainAxisAlignment.center,
//                                             children: [
//                                               Container(
//                                                 height: 60,
//                                                 width: 60,
//                                                 decoration: BoxDecoration(
//                                                   color:
//                                                       const Color.fromRGBO(88, 142, 12, 1),
//                                                   borderRadius: BorderRadius.circular(30),
//                                                 ),
//                                                 child: const Icon(
//                                                   Icons.question_mark,
//                                                   size: 32,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 10),
//                                               const Text(
//                                                 "Are you sure you want to",
//                                                 style: TextStyle(
//                                                     fontSize: 20,
//                                                     color: Color.fromRGBO(125, 117, 128, 1),
//                                                     fontWeight: FontWeight.bold),
//                                               ),
//                                               const Text(
//                                                 "cancel this order?",
//                                                 style: TextStyle(
//                                                     fontSize: 20,
//                                                     color: Color.fromRGBO(125, 117, 128, 1),
//                                                     fontWeight: FontWeight.bold),
//                                               ),
//                                               const SizedBox(height: 20),
//                                               Padding(
//                                                 padding: const EdgeInsets.symmetric(
//                                                     horizontal: 20),
//                                                 child: Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.spaceBetween,
//                                                   children: [
//                                                     Expanded(
//                                                       child: Container(
//                                                         height: 50,
//                                                         decoration: BoxDecoration(
//                                                           borderRadius:
//                                                               BorderRadius.circular(20),
//                                                           color: const Color.fromRGBO(
//                                                               217, 217, 217, 1),
//                                                         ),
//                                                         child: TextButton(
//                                                           onPressed: () {
//                                                             Navigator.pop(context);
//                                                           },
//                                                           child: const Text(
//                                                             "No, Keep Order",
//                                                             style: TextStyle(
//                                                               color: Colors.black,
//                                                               fontSize: 15,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 20),
//                                                     Expanded(
//                                                       child: Container(
//                                                         height: 50,
//                                                         decoration: BoxDecoration(
//                                                           borderRadius:
//                                                               BorderRadius.circular(20),
//                                                           color: const Color.fromRGBO(
//                                                               199, 3, 3, 1),
//                                                         ),
//                                                         child: TextButton(
//                                                           onPressed: () {
//                                                             // TODO: Add cancel order logic here
//                                                           },
//                                                           child: const Text(
//                                                             "Yes, Cancel Order",
//                                                             style: TextStyle(
//                                                               color: Colors.white,
//                                                               fontSize: 15,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   );
//                                 },
//                                 icon: Image.asset("assets/icons/trash bin.png"),
//                                 tooltip: 'Cancel Booking',
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class MyBookings extends StatelessWidget {
  const MyBookings({super.key});

  void _confirmCancel(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cancel Booking?"),
          content: const Text("Are you sure you want to cancel this booking?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .delete();
              },
              child: const Text("Yes, Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget buildBookingCard(
      BuildContext context, Map<String, dynamic> data, String bookingId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 145,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    errorBuilder: (context, error, stackTrace) => Image.network(
                        "https://t4.ftcdn.net/jpg/05/17/53/57/360_F_517535712_q7f9QC9X6TQxWi6xYZZbMmw5cnLMr279.jpg"),
                    data['image'] ?? 'null',
                    height: 120,
                    width: MediaQuery.of(context).size.width * 0.02,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 25, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['serviceTitle'] ?? 'Service',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text("Worker: ${data['workerName'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          // Text(formatDate(data['createAt'])),
                          // Text(DateFormat.yMMMd().format((data['date'] as Timestamp).toDate())),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time, size: 16),
                          // Text(data['time']),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("₹${data['discountPrice']}/Hour",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _confirmCancel(context, bookingId),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 102, 214, 10),
                  Color.fromARGB(255, 113, 191, 4),
                  Color.fromARGB(255, 26, 159, 6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  customBackbutton1(
                    onpress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => user_Dashboard()),
                      );
                    },
                  ),
                  const SizedBox(width: 80),
                  const Text(
                    "My Bookings",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const BookingsListSkeleton();
                final bookings = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final data = bookings[index].data() as Map<String, dynamic>;
                    return buildBookingCard(context, data, bookings[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

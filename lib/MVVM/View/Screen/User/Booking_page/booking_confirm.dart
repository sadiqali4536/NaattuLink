// import 'dart:async';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:naattulink/MVVM/utils/Constants/colors.dart';

// class BookingConfirmationModal extends StatefulWidget {
//   final List<Map<String, dynamic>> bookedItems;
//   final VoidCallback? onDonePressed;

//   const BookingConfirmationModal({
//     Key? key,
//     required this.bookedItems,
//     this.onDonePressed,
//   }) : super(key: key);

//   @override
//   State<BookingConfirmationModal> createState() =>
//       _BookingConfirmationModalState();
// }

// class _BookingConfirmationModalState extends State<BookingConfirmationModal> {
//   bool showTick = false;
//   Timer? _autoCloseTimer;

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() {
//           showTick = true;
//         });
//       }
//     });

//     _autoCloseTimer = Timer(const Duration(minutes: 2), () {
//       if (mounted) Navigator.of(context).pop();
//     });
//   }

//   @override
//   void dispose() {
//     _autoCloseTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         height: MediaQuery.of(context).size.height * 0.95,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             showTick
//                 ? const Icon(Icons.check_circle, size: 80, color: Colors.green)
//                 : const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             const Text(
//               "Booking Confirmed!",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             const Divider(),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: widget.bookedItems.length,
//                 itemBuilder: (context, index) {
//                   final item = widget.bookedItems[index];
//                   return ListTile(
//                     leading: item['image'] != null
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               item['image'],
//                               width: 50,
//                               height: 50,
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         : const Icon(Icons.broken_image,size: 50,),
//                     title: Text(item['serviceTitle'] ?? '',
//                         style: const TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: Text("₹${item['discountPrice'] ?? ''}",style: TextStyle(
//                       fontSize: 15,fontWeight: FontWeight.bold
//                     ),),

//                   );
//                 },
//               ),
//             ),
//             Divider(),

//             const SizedBox(height: 10),
//             SizedBox(
//               height: 45,
//               width: 150,
//               child: ElevatedButton(
//                 onPressed: () {
//                   widget.onDonePressed?.call();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: gradientgreen2.c,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text("Done", style: TextStyle(color: Colors.white)),
//               ),
//             ),
//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:naattulink/MVVM/utils/Constants/colors.dart';

// class BookingConfirmationModal extends StatefulWidget {
//   final List<Map<String, dynamic>> bookedItems;
//   final VoidCallback? onDonePressed;

//   const BookingConfirmationModal({
//     Key? key,
//     required this.bookedItems,
//     this.onDonePressed,
//   }) : super(key: key);

//   @override
//   State<BookingConfirmationModal> createState() =>
//       _BookingConfirmationModalState();
// }

// class _BookingConfirmationModalState extends State<BookingConfirmationModal> {
//   bool showTick = false;
//   Timer? _autoCloseTimer;

//   @override
//   void initState() {
//     super.initState();

//     // Show tick after animation
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() {
//           showTick = true;
//         });
//       }
//     });

//     // Auto close modal after 2 minutes
//     _autoCloseTimer = Timer(const Duration(minutes: 2), () {
//       if (mounted) Navigator.of(context).pop();
//     });
//   }

//   @override
//   void dispose() {
//     _autoCloseTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Container(
//         height: MediaQuery.of(context).size.height * 0.95,
//         padding: const EdgeInsets.all(16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//         ),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//             showTick
//                 ? const Icon(Icons.check_circle, size: 80, color: Colors.green)
//                 : const CircularProgressIndicator(),
//             const SizedBox(height: 20),
//             const Text(
//               "Booking Confirmed!",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             const Divider(),

//             // List of booked services
//             Expanded(
//               child: ListView.builder(
//                 itemCount: widget.bookedItems.length,
//                 itemBuilder: (context, index) {
//                   final item = widget.bookedItems[index];
//                   final serviceTitle =
//                       item['serviceTitle'] ?? item['service_name'] ?? 'Service';
//                   return ListTile(
//                     leading: item['image'] != null && item['image'] != ""
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               item['image'],
//                               width: 50,
//                               height: 50,
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         : const Icon(Icons.broken_image, size: 50),
//                     title: Text(
//                       serviceTitle,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       "₹${item['discountPrice'] ?? ''}",
//                       style: const TextStyle(
//                           fontSize: 15, fontWeight: FontWeight.bold),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const Divider(),
//             const SizedBox(height: 10),

//             // Done Button
//             SizedBox(
//               height: 45,
//               width: 150,
//               child: ElevatedButton(
//                 onPressed: () {
//                   widget.onDonePressed?.call();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: gradientgreen2.c,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child:
//                     const Text("Done", style: TextStyle(color: Colors.white)),
//               ),
//             ),
//             const SizedBox(height: 10),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';

class BookingConfirmationModal extends StatefulWidget {
  final List<Map<String, dynamic>> bookedItems;
  final VoidCallback? onDonePressed;

  const BookingConfirmationModal({
    Key? key,
    required this.bookedItems,
    this.onDonePressed,
  }) : super(key: key);

  @override
  State<BookingConfirmationModal> createState() =>
      _BookingConfirmationModalState();
}

class _BookingConfirmationModalState extends State<BookingConfirmationModal> {
  bool showTick = false;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    // Show tick after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showTick = true;
        });
      }
    });

    // Auto close modal after 2 minutes
    _autoCloseTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.95,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            showTick
                ? const Icon(Icons.check_circle, size: 80, color: Colors.green)
                : const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Booking Confirmed!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // List of booked services
            Expanded(
              child: ListView.builder(
                itemCount: widget.bookedItems.length,
                itemBuilder: (context, index) {
                  final item = widget.bookedItems[index];
                  final serviceTitle =
                      item['serviceTitle'] ?? item['service_name'] ?? 'Service';
                  final price = item['discountPrice']?.toString() ?? '0';
                  final image = item['image']?.toString();

                  return ListTile(
                    leading: image != null && image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                            ),
                          )
                        : const Icon(Icons.image_not_supported, size: 50),
                    title: Text(
                      serviceTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₹$price",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const Divider(),
            const SizedBox(height: 10),

            // Done Button
            SizedBox(
              height: 45,
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  widget.onDonePressed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: gradientgreen2.c,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    const Text("Done", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Exterior_Bookingpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Home_Booking_Page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/Interior_Booking_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pet_Bookingpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/vehicle_booking_page.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class Servicecard2 extends StatelessWidget {
  final String category;

  const Servicecard2({super.key, required this.category});

  String formatPrice(dynamic price) {
    try {
      return (double.tryParse(price.toString())?.toInt() ?? 0).toString();
    } catch (_) {
      return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceStream = (category == "All")
        ? FirebaseFirestore.instance.collection('services').snapshots()
        : (category == 'Most popular')
            ? FirebaseFirestore.instance
                .collection('services')
                .orderBy('rating', descending: true)
                .limit(10)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('services')
                .where('category', isEqualTo: category)
                .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: serviceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ServiceCardListSkeleton();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final services = snapshot.data?.docs ?? [];

        if (services.isEmpty) {
          return const Center(child: Text("No services found."));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          itemBuilder: (_, index) {
            final item = services[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                final category = item['category'];
                Widget? targetPage;

                switch (category) {
                  case 'Exterior':
                    targetPage = ExteriorBookingpage(
                      category: item['category'],
                      serviceName: item['service_name'],
                      rating: item['rating'],
                      originalPrice: item['original_price'],
                      discount: item['discount'],
                      image: item['image'],
                      discountPrice: item['price'],
                      serviceType: item['service_type'],
                    );
                    break;
                  case 'Interior':
                    targetPage = InteriorBookingPage(
                      category: item['category'],
                      serviceName: item['service_name'],
                      rating: item['rating'],
                      originalPrice: item['original_price'],
                      discount: item['discount'],
                      image: item['image'],
                      discountPrice: item['price'],
                      serviceType: item['service_type'],
                    );
                    break;
                  case 'Vehicle':
                    targetPage = VehicleBookingPage(
                      category: item['category'],
                      serviceName: item['service_name'],
                      rating: item['rating'],
                      originalPrice: item['original_price'],
                      discount: item['discount'],
                      image: item['image'],
                      discountPrice: item['price'],
                      serviceType: item['service_type'],
                    );
                    break;
                  case 'Pet':
                    targetPage = PetCleaning(
                      category: item['category'],
                      serviceName: item['service_name'],
                      rating: item['rating'],
                      originalPrice: item['original_price'],
                      discount: item['discount'],
                      image: item['image'],
                      discountPrice: item['price'],
                      serviceType: item['service_type'],
                    );
                    break;
                  case 'Home':
                    targetPage = HomeBookingPage(
                      category: item['category'],
                      serviceName: item['service_name'],
                      rating: item['rating'],
                      originalPrice: item['original_price'],
                      discount: item['discount'],
                      image: item['image'],
                      discountPrice: item['price'],
                      serviceType: item['service_type'],
                    );
                    break;
                }

                if (targetPage != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => targetPage!),
                  );
                }
              },
              child: Card(
                elevation: 4,
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item['image'] != null &&
                                item['image'].toString().startsWith('http')
                            ? Image.network(
                                item['image'],
                                height: 120,
                                width: 95.5,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 120,
                                width: 95.5,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["service_name"] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: (item["rating"] ?? 0).toDouble(),
                                  itemBuilder: (_, __) => const Icon(Icons.star,
                                      color: gradientgreen2.c),
                                  itemCount: 5,
                                  itemSize: 20,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 6),
                                Text("${item["rating"] ?? 0}"),
                              ],
                            ),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (item["discount"] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_downward,
                                          size: 15, color: gradientgreen2.c),
                                      Text("${item["discount"]}%",
                                          style: const TextStyle(
                                              color: gradientgreen2.c)),
                                    ],
                                  ),
                                if (item["original_price"] != null)
                                  Text(
                                    "₹${formatPrice(item["original_price"])}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  "₹${formatPrice(item["price"])}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (item["service_type"] == "Hour")
                                  const Text("/hour",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

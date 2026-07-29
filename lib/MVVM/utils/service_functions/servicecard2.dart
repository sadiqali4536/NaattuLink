import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
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

            final String itemCategory = item['category'] ?? '';
            final String serviceName = item['service_name'] ?? '';
            final dynamic rating = item['rating'] ?? 0;
            final dynamic originalPrice = item['original_price'];
            final dynamic discount = item['discount'];
            final String? image = item['image'];
            final dynamic price = item['price'];
            final String? serviceType = item['service_type'];

            return GestureDetector(
              onTap: () {
                Widget? targetPage;

                switch (itemCategory) {
                  case 'plumber':
                  case 'electrician':
                  case 'carpenter':
                  case 'painter':
                    targetPage = ServiceDetailsPage(
                      category: itemCategory,
                      serviceName: serviceName,
                      rating: double.tryParse(rating.toString()) ?? 0.0,
                      originalPrice: originalPrice,
                      discount: discount,
                      image: image ?? '',
                      discountPrice: price,
                      serviceType: serviceType,
                      serviceId: item['id']?.toString() ?? item['serviceId']?.toString() ?? 'Unknown',
                      providerId: item['providerId']?.toString() ?? item['uid']?.toString() ?? 'Unknown',
                      providerName: item['providerName']?.toString() ?? item['workerName']?.toString() ?? 'Unknown',
                      providerPhone: item['providerPhone']?.toString() ?? item['phone']?.toString() ?? '',
                      serviceDescription: item['description']?.toString() ?? item['about']?.toString() ?? '',
                      estimatedDuration: item['duration']?.toString() ?? '1 hr',
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
                        child: image != null &&
                                image.toString().startsWith('http')
                            ? Image.network(
                                image,
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
                              serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating:
                                      double.tryParse(rating.toString()) ?? 0.0,
                                  itemBuilder: (_, __) => const Icon(Icons.star,
                                      color: gradientgreen2.c),
                                  itemCount: 5,
                                  itemSize: 20,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 6),
                                Text("$rating"),
                              ],
                            ),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (discount != null &&
                                    discount.toString().isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.arrow_downward,
                                          size: 15, color: gradientgreen2.c),
                                      Text("$discount%",
                                          style: const TextStyle(
                                              color: gradientgreen2.c)),
                                    ],
                                  ),
                                if (originalPrice != null &&
                                    originalPrice.toString().isNotEmpty)
                                  Text(
                                    "₹${formatPrice(originalPrice)}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                if (price != null &&
                                    price.toString().isNotEmpty)
                                  Text(
                                    "₹${formatPrice(price)}",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                if (serviceType == "Hour")
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

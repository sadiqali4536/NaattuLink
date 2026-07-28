import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/worker_bookings/worker_details_page.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class WorkerCardList extends StatefulWidget {
  const WorkerCardList({super.key});

  @override
  State<WorkerCardList> createState() => _WorkerCardListState();
}

class _WorkerCardListState extends State<WorkerCardList> {
  String _userLocality = '';
  String _userCity = '';
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          if (mounted) {
            setState(() {
              _userLocality = (pm.locality ?? pm.subLocality ?? pm.name ?? '')
                  .toLowerCase();
              _userCity =
                  (pm.subAdministrativeArea ?? pm.locality ?? '').toLowerCase();
            });
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }
    } catch (_) {}
    if (mounted) setState(() => _locationLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_locationLoading) {
      return const ServiceCardListSkeleton();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ServiceCardListSkeleton();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final allWorkers = snapshot.data?.docs ?? [];

        // Filter and sort available workers
        var availableWorkers = allWorkers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          // Adjust status check based on how backend marks them available
          return status == 'approved' ||
              status == 'active' ||
              status == 'available';
        }).toList();

        if (_userLocality.isNotEmpty || _userCity.isNotEmpty) {
          availableWorkers.sort((a, b) {
            final locA = ((a.data() as Map<String, dynamic>)['location'] ?? '')
                .toString()
                .toLowerCase();
            final locB = ((b.data() as Map<String, dynamic>)['location'] ?? '')
                .toString()
                .toLowerCase();

            bool aMatches = locA.contains(_userLocality) ||
                (_userCity.isNotEmpty && locA.contains(_userCity));
            bool bMatches = locB.contains(_userLocality) ||
                (_userCity.isNotEmpty && locB.contains(_userCity));

            if (aMatches && !bMatches) return -1;
            if (!aMatches && bMatches) return 1;
            return 0;
          });
        }

        if (availableWorkers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No available workers found."),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: availableWorkers.length,
          itemBuilder: (_, index) {
            final item = availableWorkers[index].data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerDetailsPage(
                      category: item['category'] ?? 'Worker',
                      serviceName: item['category'] ?? 'Worker',
                      rating: (item['ratings'] ?? 0).toDouble(),
                      originalPrice: 500, // Mock price
                      discount: 0,
                      image: (item['profile_img']?.toString().isNotEmpty ==
                              true)
                          ? item['profile_img']
                          : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80',
                      discountPrice: 500,
                      serviceType: 'Hour',
                    ),
                  ),
                );
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
                        child: item['profile_img']?.toString().isNotEmpty ==
                                true
                            ? Image.network(
                                item['profile_img'],
                                height: 100,
                                width: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 100,
                                  width: 90,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                                ),
                              )
                            : Container(
                                height: 100,
                                width: 90,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person,
                                    size: 40, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["username"] ?? 'Unknown Worker',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (item["category"] ?? '').toString().toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: (item["ratings"] ?? 0).toDouble(),
                                  itemBuilder: (_, __) => const Icon(Icons.star,
                                      color: gradientgreen2.c),
                                  itemCount: 5,
                                  itemSize: 18,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                    "${item["ratings"] ?? 0} (${item["total_reviews"] ?? 0})",
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item["location"] ?? 'Unknown Location',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Exp: ${item['experience'] ?? '0'} years",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2E5A)),
                            )
                          ],
                        ),
                      ),
                      if (item['isVerified'] == 1 || item['isVerified'] == true)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.verified,
                              color: Colors.blue, size: 24),
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

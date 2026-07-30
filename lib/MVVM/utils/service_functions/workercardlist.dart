import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: availableWorkers.length,
          itemBuilder: (_, index) {
            final item = availableWorkers[index].data() as Map<String, dynamic>;
            final imageUrl = (item['profile_img']?.toString().isNotEmpty ==
                    true)
                ? item['profile_img']
                : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80';
            final title = item["username"] ?? 'Unknown Worker';
            final rating = (item["ratings"] ?? 0).toDouble();
            final price = item['hourly_rate'] ?? 299;

            void _handleTap() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailsPage(
                    category: item['category'] ?? 'Worker',
                    serviceName: item['category'] ?? 'Worker',
                    rating: rating,
                    originalPrice: 500, // Mock price
                    discount: 0,
                    image: imageUrl.toString(),
                    discountPrice: 500,
                    serviceType: 'Hour',
                    serviceId: availableWorkers[index].id,
                    providerId: item['uid']?.toString() ?? 'Unknown',
                    providerName: item['name']?.toString() ??
                        item['workerName']?.toString() ??
                        'Unknown',
                    providerPhone: item['phone']?.toString() ?? '',
                    serviceDescription: item['about']?.toString() ??
                        item['description']?.toString() ??
                        '',
                    estimatedDuration: '1 hr',
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: _handleTap,
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top image (expands to fill available space)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          imageUrl.toString(),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF0F2E5A),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFFFBBF24), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF0F2E5A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Starts from ₹$price",
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFFBBF24), // Yellow
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              onPressed: _handleTap,
                              child: const Text(
                                "Book Now",
                                style: TextStyle(
                                  color: Color(0xFF0F2E5A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
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
  }
}

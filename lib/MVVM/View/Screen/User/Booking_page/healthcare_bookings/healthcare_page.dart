import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:naattulink/MVVM/utils/service_functions/distance_service.dart';
import 'package:geocoding/geocoding.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/service_functions/availability_utils.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'healthcare_doctors_page.dart';

// ─────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────
class ClinicListing {
  final String uid;
  final String name;
  final String facilityName;
  final String rating;
  final String status;
  String location;
  final String phone;
  final String imageUrl;
  final String speciality;
  final String availableTime;
  final String quoteText;

  final double? latitude;
  final double? longitude;
  final int totalReviews;
  final bool isVerified;
  final String profession;

  double? roadDistanceKm;
  int? roadEtaMinutes;

  ClinicListing({
    required this.uid,
    required this.name,
    required this.facilityName,
    required this.rating,
    required this.status,
    required this.location,
    required this.phone,
    required this.imageUrl,
    required this.speciality,
    required this.availableTime,
    required this.quoteText,
    required this.profession,
    this.latitude,
    this.longitude,
    this.totalReviews = 0,
    this.isVerified = false,
    this.roadDistanceKm,
    this.roadEtaMinutes,
  });

  double distanceFrom(double userLat, double userLng) {
    if (roadDistanceKm != null) return roadDistanceKm!;
    if (latitude == null || longitude == null) return 999.0;
    return DistanceService.calculateDistanceInKm(
        userLat, userLng, latitude!, longitude!);
  }

  int etaMinutes(double userLat, double userLng) {
    if (roadEtaMinutes != null) return roadEtaMinutes!;
    final d = distanceFrom(userLat, userLng);
    return max(1, (d / 20.0 * 60).round());
  }
}

// ─────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────
class HealthcarePage extends StatefulWidget {
  final String healthcareType;
  final String pageTitle;

  const HealthcarePage({
    Key? key,
    this.healthcareType = 'Clinic',
    this.pageTitle = 'Clinics',
  }) : super(key: key);

  @override
  State<HealthcarePage> createState() => _HealthcarePageState();
}

class _HealthcarePageState extends State<HealthcarePage> {
  // UI state
  String searchQuery = '';
  String selectedTypeFilter = 'All';
  String selectedSmartFilter = 'Nearest';
  double searchRadiusKm = 10.0;

  bool _isLoadingListings = true;

  // Pagination state
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final ScrollController _scrollController = ScrollController();

  // ─── Listings ───────────────────────────────────
  List<ClinicListing> _allListings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isFetchingMore &&
          _hasMore) {
        _loadMoreListings();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingListings = true;
    });

    await _fetchListingsFromFirestore();
  }

  String _getSingular(String plural) {
    if (plural.toLowerCase() == 'pharmacies') return 'pharmacy';
    if (plural.toLowerCase() == 'laboratories') return 'laboratory';
    if (plural.toLowerCase().endsWith('s')) {
      return plural.substring(0, plural.length - 1).toLowerCase();
    }
    return plural.toLowerCase();
  }

  String getMainLocality(String location) {
    return location.trim().toLowerCase().split(',').first.trim();
  }

  String normalizeAddress(String address) {
    return address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool isLocationMatch(String userLocation, String providerAddress) {
    final userLocality = getMainLocality(userLocation);
    final address = normalizeAddress(providerAddress);

    if (userLocality.isEmpty || address.isEmpty) {
      return false;
    }

    return address.contains(userLocality);
  }

  Future<void> _fetchListingsFromFirestore() async {
    try {
      final locationController = LocationController.to;
      while (locationController.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (locationController.locationName.value.isEmpty) {
        await locationController.fetchLocation();
      }

      final snapshot =
          await FirebaseFirestore.instance.collection('healthcare').limit(20).get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      } else {
        _hasMore = false;
      }

      final fetchedListings = await _processSnapshot(snapshot);

      if (mounted) {
        setState(() {
          _allListings = fetchedListings;
          _isLoadingListings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingListings = false;
        });
      }
    }
  }

  Future<void> _loadMoreListings() async {
    if (_isFetchingMore || !_hasMore || _lastDocument == null) return;
    
    setState(() {
      _isFetchingMore = true;
    });
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('healthcare')
          .startAfterDocument(_lastDocument!)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isFetchingMore = false;
        });
        return;
      }
      
      _lastDocument = snapshot.docs.last;
      
      final fetchedListings = await _processSnapshot(snapshot);

      if (mounted) {
        setState(() {
          _allListings.addAll(fetchedListings);
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading more healthcare listings: $e");
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  Future<List<ClinicListing>> _processSnapshot(QuerySnapshot snapshot) async {
    final locationController = LocationController.to;
    final List<ClinicListing> fetchedListings = [];
    final userLocationStr = locationController.locationName.value;
    final selectedHealthcareType = widget.healthcareType;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final addressStr = data['address']?.toString() ?? '';
      final firebaseType =
          (data['profession'] ?? data['healthcare_type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      final categoryStr =
          (data['category'] ?? '').toString().trim().toLowerCase();
      final statusStr =
          (data['status'] ?? '').toString().trim().toLowerCase();

      final selectedType = selectedHealthcareType.trim().toLowerCase();

      final locationMatch = isLocationMatch(userLocationStr, addressStr);
      final typeMatch = firebaseType == selectedType;
      final categoryMatch =
          categoryStr == 'healthcare' || categoryStr.isEmpty;
      final statusMatch = statusStr == 'active' || 
                          statusStr == 'approved' || 
                          statusStr == 'available' || 
                          statusStr == 'pending' || 
                          selectedType == 'emergency services';

      final shouldShow = typeMatch && categoryMatch && statusMatch;

      // Skip if conditions don't match
      if (!shouldShow) {
        continue;
      }

      final rawRating = data['ratings'] ?? 0;
      final totalReviews = data['total_reviews'] ?? 0;
      final ratingStr = "$rawRating ($totalReviews)";

      final isVerifiedFlag =
          data['isVerified'] == 1 || data['isVerified'] == true;

      String address = data['address'] ?? "Kozhikode";
      double? dbLat = double.tryParse(
          data['latitude']?.toString() ?? data['lat']?.toString() ?? '');
      double? dbLng = double.tryParse(data['longitude']?.toString() ??
          data['lng']?.toString() ??
          data['long']?.toString() ??
          '');

      double? lat;
      double? lng;

      if (dbLat != null && dbLng != null && dbLat != 0.0 && dbLng != 0.0) {
        lat = dbLat;
        lng = dbLng;
      } else {
        try {
          // Append context to avoid ambiguous address timeouts
          final searchAddress = "$address";
          List<Location> locations = await locationFromAddress(searchAddress)
              .timeout(const Duration(seconds: 2));

          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (e) {
          print(
              '[HEALTHCARE] Geocoding failed or timed out for "$address": $e');
        }
      }

      final userLat = locationController.latitude.value;
      final userLng = locationController.longitude.value;
      double? distMeters;
      double? distKm;

      if (userLat != null && userLng != null && lat != null && lng != null) {
        distMeters = Geolocator.distanceBetween(userLat, userLng, lat, lng);
        distKm = distMeters / 1000;
      }

      String statusText = (data['status']?.toString() ?? "Pending");
      statusText = statusText.isNotEmpty
          ? statusText[0].toUpperCase() +
              statusText.substring(1).toLowerCase()
          : "Pending";

      String phoneStr = data['phone']?.toString().isNotEmpty == true
          ? data['phone'].toString()
          : (data['contact_number']?.toString() ?? "");

      fetchedListings.add(
        ClinicListing(
          uid: doc.id,
          name: (data['facility_name']?.toString().trim().isEmpty ?? true)
              ? ""
              : (data['username']?.toString().trim().isNotEmpty == true
                  ? data['username']
                  : "Clinic Doctor"),
          facilityName:
              (data['facility_name']?.toString().trim().isNotEmpty == true)
                  ? data['facility_name']
                  : (data['username']?.toString().trim().isNotEmpty == true
                      ? data['username']
                      : "Emergency Service"),
          rating: ratingStr,
          status: statusText,
          location: address,
          phone: phoneStr.isNotEmpty ? "tel:$phoneStr" : "",
          imageUrl: data['profile_img']?.isNotEmpty == true
              ? data['profile_img']
              : "assets/image/hospital_icon.png", // fallback icon
          speciality: data['speciality'] ?? "General",
          availableTime: data['available_time'] ?? "9 AM - 8 PM",
          quoteText: "മികച്ച ചികിത്സ ഉറപ്പ് നൽകുന്നു.",
          latitude: lat,
          longitude: lng,
          totalReviews: int.tryParse(totalReviews.toString()) ?? 0,
          isVerified: isVerifiedFlag,
          profession: firebaseType,
        ),
      );
    }

    // Pre-fetch road distances in bulk from Google Maps API
    if (fetchedListings.isNotEmpty) {
      final destinations = fetchedListings
          .map((e) => <String, double>{
                'lat': e.latitude ?? 0.0,
                'lng': e.longitude ?? 0.0
              })
          .toList();
      final roadResults = await DistanceService.fetchBulkRoadDistances(
          locationController.latitude.value ?? 11.2588,
          locationController.longitude.value ?? 75.7804,
          destinations);

      for (int i = 0; i < fetchedListings.length; i++) {
        if (roadResults[i] != null) {
          fetchedListings[i].roadDistanceKm = roadResults[i]!['distanceKm'];
          fetchedListings[i].roadEtaMinutes = roadResults[i]!['etaMinutes'];
          if (roadResults[i]!['address'] != null) {
            final addrParts = (roadResults[i]!['address'] as String)
                .split(',')
                .map((s) => s.trim())
                .where((s) => !s.contains('+'))
                .toList();
            if (addrParts.isNotEmpty) {
              fetchedListings[i].location = addrParts.first;
            }
          }
        }
      }
    }
    return fetchedListings;
  }

  // ─── Filtered + Ranked list ───────────────────────
  List<ClinicListing> _getRankedListings(
      double userLat, double userLng, String locationName) {
    List<ClinicListing> result = _allListings.where((item) {
      if (selectedTypeFilter != 'All' &&
          !item.speciality
              .toLowerCase()
              .contains(selectedTypeFilter.toLowerCase())) {
        return false;
      }

      final locParts = locationName.split(',');
      final userLocality = locParts.first.trim().toLowerCase();
      final userCity =
          locParts.length > 1 ? locParts.last.trim().toLowerCase() : '';
      final itemLoc = item.location.toLowerCase();

      if (selectedSmartFilter == 'My Location') {
        if (!itemLoc.contains(userLocality) &&
            (userCity.isEmpty || !itemLoc.contains(userCity))) {
          return false;
        }
      }

      final q = searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        return item.name.toLowerCase().contains(q) ||
            item.facilityName.toLowerCase().contains(q) ||
            item.speciality.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.phone.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    result.sort((a, b) {
      final distA = a.distanceFrom(userLat, userLng);
      final distB = b.distanceFrom(userLat, userLng);
      return distA.compareTo(distB);
    });

    // If search is active, bypass the 10km restriction
    if (searchQuery.trim().isNotEmpty) {
      return result;
    }

    // Normal browsing: Show services strictly within 10km
    return result.where((item) {
      final dist = item.distanceFrom(userLat, userLng);
      return dist <= 10.0;
    }).toList();
  }

  String _getSectionImage() {
    switch (widget.healthcareType.toLowerCase()) {
      case 'hospital':
        return 'assets/image/hospital.png';
      case 'clinic':
        return 'assets/image/clinick.png';
      case 'pharmacy':
        return 'assets/image/pharmacy.png';
      case 'laboratory':
        return 'assets/image/laboratory.png';
      case 'emergency services':
        return 'assets/image/ambulance-emergency.jpg';
      default:
        return 'assets/image/hospital.png';
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError("Could not start call.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumAppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Obx(() {
        final locCtrl = LocationController.to;
        final isLoadingLoc = locCtrl.isLoading.value;
        final lat = locCtrl.latitude.value;
        final lng = locCtrl.longitude.value;
        final locName = locCtrl.locationName.value;

        if (isLoadingLoc) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
          );
        }

        if (lat == null || lng == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off_rounded,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Location unavailable',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => locCtrl.fetchLocation(forceRefresh: true),
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: const Text("Retry",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2E5A)),
                )
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationBanner(locName),
            _buildSearchAndRadiusRow(),
            _buildSmartFilterChips(),
            _buildListHeader(lat, lng, locName),
            Expanded(
              child: _isLoadingListings
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F2E5A),
                      ),
                    )
                  : _buildListView(lat, lng, locName),
            ),
          ],
        );
      }),
    ));
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: AppBackButton(),
      ),
      centerTitle: true,
      title: Text(
        widget.pageTitle,
        style: TextStyle(
          color: Color(0xFF0F2E5A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildLocationBanner(String locationName) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Color(0xFF0F2E5A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your location: $locationName',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () =>
                LocationController.to.fetchLocation(forceRefresh: true),
            child:
                const Icon(Icons.refresh, color: Color(0xFF0F2E5A), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndRadiusRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.healthcareType == "Emergency Services"
                      ? "Search emergency services..."
                      : "Search ${widget.pageTitle.toLowerCase()}, specialities...",
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF0F2E5A), size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFilterChips() {
    const filters = [
      'Nearest',
      'My Location',
      'Highest Rated',
      'Available Now'
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: filters.map((f) {
          final active = selectedSmartFilter == f;
          return GestureDetector(
            onTap: () => setState(() => selectedSmartFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF0F2E5A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? const Color(0xFF0F2E5A)
                        : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListHeader(double userLat, double userLng, String locationName) {
    final count = _getRankedListings(userLat, userLng, locationName).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$count ${count == 1 ? _getSingular(widget.pageTitle) : widget.pageTitle.toLowerCase()} found",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(double userLat, double userLng, String locationName) {
    final listings = _getRankedListings(userLat, userLng, locationName);
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No ${widget.pageTitle.toLowerCase()} found in this area",
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: listings.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == listings.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
            ),
          );
        }
        return _buildListingCard(listings[i], userLat, userLng);
      },
    );
  }

  Widget _buildListingCard(ClinicListing item, double userLat, double userLng) {
    final dist = item.distanceFrom(userLat, userLng);
    String distStr = dist < 1
        ? '${(dist * 1000).round()} m away'
        : '${dist.toStringAsFixed(1)} km away';

    Color statusBg;
    Color statusText;

    if (item.status.toLowerCase() == "available" ||
        item.status.toLowerCase() == "active" ||
        item.status.toLowerCase() == "approved") {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
    } else if (item.status.toLowerCase() == "pending") {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFD97706);
    } else {
      statusBg = const Color(0xFFEEF2FF);
      statusText = const Color(0xFF4F46E5);
    }

    return GestureDetector(
        onTap: () {
          if (widget.healthcareType.toLowerCase() == 'pharmacy') {
            return; // No consultation page for pharmacy
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HealthcareDoctorsPage(clinic: item),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2E5A).withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        _getSectionImage(),
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.facilityName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0F2E5A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (item.isVerified)
                              const Icon(Icons.verified_user_rounded,
                                  color: Color(0xFF4F46E5), size: 14),
                          ],
                        ),
                        if (widget.healthcareType.toLowerCase() ==
                            'pharmacy') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  color: Color(0xFF64748B), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                item.phone.replaceAll('tel:', ''),
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.location,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          if (item.name.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.name,
                              style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                          if (widget.healthcareType.toLowerCase() !=
                                  'emergency services' &&
                              item.speciality.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.speciality,
                              style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  item.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          if (!item.rating.startsWith("0 ") &&
                              !item.rating.startsWith("0.0 ")) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFB800), size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    item.rating,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Color(0xFF0F2E5A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (widget.healthcareType.toLowerCase() !=
                      'emergency services')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AvailabilityBadge(scheduleString: item.availableTime),
                      ],
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFF1F5F9), height: 1),
              ),
              // Distance + ETA + Location row
              Row(
                children: [
                  const Icon(Icons.near_me_outlined,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(distStr,
                      style: const TextStyle(
                          color: Color(0xFF0F2E5A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(width: 12),
                  if (widget.healthcareType.toLowerCase() !=
                      'emergency services') ...[
                    Container(
                        width: 1, height: 10, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(item.availableTime,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(item.phone),
                      icon: const Icon(Icons.phone_in_talk,
                          color: Colors.white, size: 16),
                      label: const Text("Call Clinic",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E5A),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ));
  }
}

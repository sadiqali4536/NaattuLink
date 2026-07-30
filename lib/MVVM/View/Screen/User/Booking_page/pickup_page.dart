import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/service_functions/distance_service.dart';
import 'package:naattulink/MVVM/utils/service_functions/location_service.dart';
import 'package:naattulink/MVVM/utils/formatters/distance_formatter.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'vehicles_auto_taxi_bookings/vehicle_details_page.dart';
import 'vehicles_auto_taxi_bookings/agency_packages_page.dart';
import 'vehicles_auto_taxi_bookings/auto_taxi_page.dart';
import 'pickup_map_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────
class PickupListing {
  final String name;
  final String type;
  final bool isAgency;
  final String rating;
  final String experienceOrVehicles;
  final String subtitle;
  final String status;
  final String vehicleDetails;
  final String regNo;
  final String location;
  final String phone;
  final String imageUrl;
  final String seating;
  final String acStatus;
  final String luggage;
  final String minCharge;
  final String aboutDriver;
  final String quoteText;
  // Extended fields for smart ranking
  final double latitude;
  final double longitude;
  final bool isElectric;
  final bool isWomenDriver;
  final int completedTrips;
  final bool isOnline;
  final bool isVerified;
  final int farePerKm;

  PickupListing({
    required this.name,
    required this.type,
    required this.isAgency,
    required this.rating,
    required this.experienceOrVehicles,
    required this.subtitle,
    required this.status,
    required this.vehicleDetails,
    required this.regNo,
    required this.location,
    required this.phone,
    required this.imageUrl,
    required this.seating,
    required this.acStatus,
    required this.luggage,
    required this.minCharge,
    required this.aboutDriver,
    required this.quoteText,
    this.latitude = 11.2588,
    this.longitude = 75.7804,
    this.isElectric = false,
    this.isWomenDriver = false,
    this.completedTrips = 0,
    this.isOnline = true,
    this.isVerified = true,
    this.farePerKm = 15,
  });

  double distanceFrom(double userLat, double userLng) {
    return DistanceService.calculateDistanceInKm(userLat, userLng, latitude, longitude);
  }


  int etaMinutes(double userLat, double userLng) {
    final d = distanceFrom(userLat, userLng);
    // Assume avg 20 km/h city speed
    return max(1, (d / 20.0 * 60).round());
  }

  AutoTaxiListing toAutoTaxiListing() {
    return AutoTaxiListing(
      name: name,
      type: type,
      isAgency: isAgency,
      rating: rating,
      experienceOrVehicles: experienceOrVehicles,
      subtitle: subtitle,
      status: status,
      vehicleDetails: vehicleDetails,
      regNo: regNo,
      location: location,
      phone: phone,
      imageUrl: imageUrl,
      seating: seating,
      acStatus: acStatus,
      luggage: luggage,
      minCharge: minCharge,
      aboutDriver: aboutDriver,
      quoteText: quoteText,
      latitude: latitude,
      longitude: longitude,
      isElectric: isElectric,
      isWomenDriver: isWomenDriver,
      completedTrips: completedTrips,
      isOnline: isOnline,
      isVerified: isVerified,
      farePerKm: farePerKm,
    );
  }
}

// ─────────────────────────────────────────────────
// Smart Ranking Comparator
// ─────────────────────────────────────────────────
int smartRank(PickupListing a, PickupListing b, double userLat,
    double userLng, String userLocality) {
  final dA = a.distanceFrom(userLat, userLng);
  final dB = b.distanceFrom(userLat, userLng);

  // 1. Nearest Pickup stands (comparing distance first, with a small 0.3 km tolerance to allow tie-breaking)
  final distDiff = (dA - dB).abs();
  if (distDiff > 0.3) {
    return dA < dB ? -1 : 1;
  }

  // 2. Same locality
  final sameLocA =
      a.location.toLowerCase().contains(userLocality.toLowerCase()) ||
          userLocality.toLowerCase().contains(a.location.toLowerCase());
  final sameLocB =
      b.location.toLowerCase().contains(userLocality.toLowerCase()) ||
          userLocality.toLowerCase().contains(b.location.toLowerCase());
  if (sameLocA != sameLocB) {
    return sameLocA ? -1 : 1;
  }

  // 3. Highest-rated drivers
  final rA = double.tryParse(a.rating.split(' ').first) ?? 0.0;
  final rB = double.tryParse(b.rating.split(' ').first) ?? 0.0;
  if ((rA - rB).abs() > 0.01) {
    return rB.compareTo(rA);
  }

  // 4. Verified drivers
  if (a.isVerified != b.isVerified) {
    return a.isVerified ? -1 : 1;
  }

  // 5. Available drivers
  final aAvail = a.status.toLowerCase() == 'available' ||
      a.status.toLowerCase() == 'open now';
  final bAvail = b.status.toLowerCase() == 'available' ||
      b.status.toLowerCase() == 'open now';
  if (aAvail != bAvail) {
    return aAvail ? -1 : 1;
  }

  // 6. Most completed trips
  if (a.completedTrips != b.completedTrips) {
    return b.completedTrips.compareTo(a.completedTrips);
  }

  // Absolute distance fallback
  return dA.compareTo(dB);
}

// ─────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────
class PickupPage extends StatefulWidget {
  const PickupPage({Key? key}) : super(key: key);

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage>
    with SingleTickerProviderStateMixin {
  // UI state
  String searchQuery = '';
  String selectedTypeFilter = 'All';
  String selectedSmartFilter = 'Nearest';
  double searchRadiusKm = 10.0;
  bool showMapView = false;

  // Location state
  double _userLat = 11.2588;
  double _userLng = 75.7804;
  bool _locationLoading = true;
  String _locationName = 'Detecting location...';
  bool _isLoadingListings = true;

  // Live simulation timer
  Timer? _liveUpdateTimer;
  final Random _rng = Random();

  // ─── Listings ───────────────────────────────────
  List<PickupListing> _allListings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Simulate live vehicle movement every 5 seconds
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _allListings.isNotEmpty) setState(() => _driftVehicles());
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingListings = true;
      _locationLoading = true;
    });
    
    await _initLocation();
    
    if (!mounted) return;
    if (_locationName == 'Location access denied') {
      setState(() {
        _isLoadingListings = false;
        _allListings = [];
      });
      return;
    }
    
    await _fetchListingsFromFirestore();
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchListingsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transports')
          .where('transport_category', isEqualTo: 'Pickup')
          .get();

      final List<PickupListing> fetchedListings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Extracting rating info safely
        final rawRating = data['ratings'] ?? 0;
        final totalReviews = data['total_reviews'] ?? 0;
        final ratingStr = "$rawRating ($totalReviews)";

        final isAc = data['air_conditioning'] == true ||
            data['air_conditioning'] == "true";
        final isVerifiedFlag =
            data['isVerified'] == 1 || data['isVerified'] == true;

        String mainStand = data['main_stand'] ?? "Kozhikode";
        double lat = 11.2588; // Default Kozhikode
        double lng = 75.7804;

        try {
          List<Location> locations =
              await locationFromAddress("$mainStand, Kerala, India");
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (e) {
          debugPrint("Geocoding failed for $mainStand: $e");
          // Add slight random offset if geocoding fails so they don't all stack on map
          lat += (_rng.nextDouble() - 0.5) * 0.05;
          lng += (_rng.nextDouble() - 0.5) * 0.05;
        }

        fetchedListings.add(
          PickupListing(
            name: data['username'] ?? "Unknown",
            type: data['vehicle_category'] ?? "Pickup",
            isAgency: false, // You can map this if needed
            rating: ratingStr,
            experienceOrVehicles: data['role_with_vehicle'] ?? "Driver",
            subtitle: "Verified Driver", // Adjust based on logic
            status: (data['status'] == 'active' || data['status'] == 'approved')
                ? "Available"
                : "Available", // Simplified status logic
            vehicleDetails: data['vehicle_model'] ?? "Vehicle",
            regNo: data['reg_number'] ?? "N/A",
            location: mainStand,
            phone: "tel:${data['phone'] ?? ''}",
            imageUrl: data['profile_img']?.isNotEmpty == true
                ? data['profile_img']
                : "assets/image/Pickup_car.png",
            seating: "${data['seating_capacity'] ?? '4'} Passengers",
            acStatus: isAc ? "AC" : "Non-AC",
            luggage: data['luggage_capacity'] ?? "Standard",
            minCharge: (data['min_charge'] ?? '0').toString(),
            aboutDriver: "Driver registered via NaattuLink.",
            quoteText: "സുരക്ഷിതമായ യാത്ര ഉറപ്പ് നൽകുന്നു.",
            latitude: lat,
            longitude: lng,
            completedTrips: 0,
            isOnline: true,
            farePerKm:
                int.tryParse(data['min_charge']?.toString() ?? '15') ?? 15,
            isVerified: isVerifiedFlag,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _allListings = fetchedListings;
          _isLoadingListings = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Pickup listings: $e");
      if (mounted) {
        setState(() {
          _isLoadingListings = false;
        });
      }
    }
  }

  // Simulates small GPS drift for live vehicle movement
  void _driftVehicles() {
    _allListings = _allListings.map((v) {
      if (!v.isOnline) return v;
      return PickupListing(
        name: v.name,
        type: v.type,
        isAgency: v.isAgency,
        rating: v.rating,
        experienceOrVehicles: v.experienceOrVehicles,
        subtitle: v.subtitle,
        status: v.status,
        vehicleDetails: v.vehicleDetails,
        regNo: v.regNo,
        location: v.location,
        phone: v.phone,
        imageUrl: v.imageUrl,
        seating: v.seating,
        acStatus: v.acStatus,
        luggage: v.luggage,
        minCharge: v.minCharge,
        aboutDriver: v.aboutDriver,
        quoteText: v.quoteText,
        latitude: v.latitude + (_rng.nextDouble() - 0.5) * 0.0008,
        longitude: v.longitude + (_rng.nextDouble() - 0.5) * 0.0008,
        isElectric: v.isElectric,
        isWomenDriver: v.isWomenDriver,
        completedTrips: v.completedTrips,
        isOnline: v.isOnline,
        isVerified: v.isVerified,
        farePerKm: v.farePerKm,
      );
    }).toList();
  }

  // ─── Location ────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationLoading = false;
          _locationName = 'Location access denied';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String localityName = 'Kallai';
      String cityName = 'Kozhikode';

      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          localityName = pm.locality ?? pm.subLocality ?? pm.name ?? 'Kallai';
          cityName = pm.subAdministrativeArea ?? pm.locality ?? 'Kozhikode';
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationLoading = false;
        _locationName = '$localityName, $cityName';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationName = 'Kallai, Kozhikode';
      });
    }
  }

  // ─── Filtered + Ranked list ───────────────────────
  List<PickupListing> get _rankedListings {
    List<PickupListing> result = _allListings.where((item) {
      // Show ONLY data that matches the user's current location strictly (String match)
      final locParts = _locationName.split(',');
      final userLocality = locParts.first.trim().toLowerCase();
      final userCity =
          locParts.length > 1 ? locParts.last.trim().toLowerCase() : '';

      final itemLoc = item.location.toLowerCase();
      // Enforce strict location filtering based on current location
      // Allow fallback if both are empty (which shouldn't happen unless loading)
      if (userLocality.isNotEmpty || userCity.isNotEmpty) {
        if (!itemLoc.contains(userLocality) &&
            (userCity.isEmpty || !itemLoc.contains(userCity))) {
          // Additional fallback: checking if item distance is within 5km for strictly nearby stands
          // if they used a different spellings.
          final dist = item.distanceFrom(_userLat, _userLng);
          if (dist > 5.0) {
            return false;
          }
        }
      }

      // Radius filter
      final dist = item.distanceFrom(_userLat, _userLng);
      if (searchRadiusKm >= 99) {
        // Entire City: limit to 25 km to exclude neighboring cities/distant stands (e.g. Thalayad)
        if (dist > 25.0) return false;
      } else {
        if (dist > searchRadiusKm) return false;
      }

      // Type filter
      if (selectedTypeFilter != 'All' &&
          item.type.toLowerCase() != selectedTypeFilter.toLowerCase())
        return false;

      // Smart filter
      if (selectedSmartFilter == 'My Location') {
        if (!itemLoc.contains(userLocality) &&
            (userCity.isEmpty || !itemLoc.contains(userCity))) {
          return false;
        }
      }
      if (selectedSmartFilter == 'AC Only' && !item.acStatus.contains('AC'))
        return false;
      if (selectedSmartFilter == 'Electric' && !item.isElectric) return false;
      if (selectedSmartFilter == 'Women Driver' && !item.isWomenDriver)
        return false;
      if (selectedSmartFilter == 'Available Now' &&
          item.status.toLowerCase() != 'available' &&
          item.status.toLowerCase() != 'open now') return false;

      // Search query
      final q = searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        return item.name.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.vehicleDetails.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Sort based on the requested priority chain
    final userLocality = _locationName.split(',').first.trim();
    if (selectedSmartFilter == 'Highest Rated') {
      result.sort((a, b) {
        final ra = double.tryParse(a.rating.split(' ').first) ?? 0;
        final rb = double.tryParse(b.rating.split(' ').first) ?? 0;
        return rb.compareTo(ra);
      });
    } else if (selectedSmartFilter == 'Lowest Fare') {
      result.sort((a, b) => a.farePerKm.compareTo(b.farePerKm));
    } else {
      result.sort((a, b) => smartRank(a, b, _userLat, _userLng, userLocality));
    }
    return result;
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError(
          "Could not start call. Number: ${phoneNumber.replaceFirst('tel:', '')}");
    }
  }

  // ─── Build ───────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationBanner(),
          _buildSearchAndRadiusRow(),
          _buildSmartFilterChips(),
          _buildTypeFilterChips(),
          _buildListHeaderAndViewToggle(),
          Expanded(
            child: _isLoadingListings
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F2E5A),
                    ),
                  )
                : showMapView
                    ? PickupMapView(
                        listings: _rankedListings,
                        userLat: _userLat,
                        userLng: _userLng,
                        onCallTap: _makeCall,
                        onDetailsTap: (item) => _openDetails(item),
                      )
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: const AppBackButton(),
      ),
      centerTitle: true,
      title: const Text(
        "Pickup & Pickup",
        style: TextStyle(
          color: Color(0xFF0F2E5A),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Color(0xFF64748B)),
          onPressed: () => _showInfoDialog(),
        ),
      ],
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _locationLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F2E5A),
                    ),
                  )
                : const Icon(Icons.my_location,
                    color: Color(0xFF0F2E5A), size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _locationLoading
                  ? 'Detecting your location...'
                  : 'Your location: $_locationName',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _initializeData(),
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
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search drivers or agencies...",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: Color(0xFF0F2E5A), size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildRadiusButton(),
        ],
      ),
    );
  }

  Widget _buildRadiusButton() {
    final label =
        searchRadiusKm >= 99 ? 'City' : '${searchRadiusKm.toInt()} km';
    return GestureDetector(
      onTap: _showRadiusSheet,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2E5A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.radar, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFilterChips() {
    const filters = [
      'Nearest',
      'My Location',
      'Highest Rated',
      'Lowest Fare',
      'AC Only',
      'Electric',
      'Women Driver',
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

  Widget _buildTypeFilterChips() {
    const types = ['All', 'Pickup', '4-Wheel Pickup', 'Van'];
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        children: types.map((t) {
          final active = selectedTypeFilter == t;
          return GestureDetector(
            onTap: () => setState(() => selectedTypeFilter = t),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFB800) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? const Color(0xFFFFB800)
                        : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF0F2E5A)
                      : const Color(0xFF64748B),
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

  Widget _buildListHeaderAndViewToggle() {
    final count = _rankedListings.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$count verified ${count == 1 ? 'listing' : 'listings'} found",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 12,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 4),
                Text(
                  'Live',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final listings = _rankedListings;
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "No vehicles found in this area",
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _showRadiusSheet,
              child: const Text(
                "Expand search radius",
                style: TextStyle(
                    color: Color(0xFF0F2E5A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: listings.length,
      itemBuilder: (ctx, i) => _buildListingCard(listings[i]),
    );
  }

  Widget _buildListingCard(PickupListing item) {
    final dist = item.distanceFrom(_userLat, _userLng);
    final eta = item.etaMinutes(_userLat, _userLng);
    final distStr = dist < 1
        ? '${(dist * 1000).round()} m away'
        : '${dist.toStringAsFixed(1)} km away';

    Color statusBg;
    Color statusText;
    if (item.status == "Available" || item.status == "Open Now") {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
    } else if (item.status == "On Trip") {
      statusBg = const Color(0xFFFFEDD5);
      statusText = const Color(0xFFC2410C);
    } else {
      statusBg = const Color(0xFFEEF2FF);
      statusText = const Color(0xFF4F46E5);
    }

    return GestureDetector(
      onTap: () => _openDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          item.isAgency
                              ? Icons.domain_outlined
                              : (item.type == 'Pickup'
                                  ? Icons.electric_rickshaw_outlined
                                  : Icons.construction_outlined),
                          color: const Color(0xFF0F2E5A),
                          size: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.isOnline
                              ? const Color(0xFF059669)
                              : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
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
                              item.name,
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
                          if (item.isElectric)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.bolt,
                                  color: Color(0xFF059669), size: 14),
                            ),
                          if (item.isWomenDriver)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.person_pin_circle,
                                  color: Color(0xFFec4899), size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFFFB800), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            item.rating,
                            style: const TextStyle(
                                color: Color(0xFF0F2E5A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 1,
                              height: 10,
                              color: const Color(0xFFCBD5E1)),
                          const SizedBox(width: 8),
                          const Icon(Icons.place_outlined,
                              size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              item.location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(item.status,
                          style: TextStyle(
                              color: statusText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${item.farePerKm}/km',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
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
                Container(width: 1, height: 10, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 12),
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('ETA ~$eta min',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
                const Spacer(),
                const Icon(Icons.place_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Actions
            if (item.isAgency)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AgencyPackagesPage(
                                      agency: AutoTaxiListing(
                                    name: item.name,
                                    type: item.type,
                                    isAgency: item.isAgency,
                                    rating: item.rating,
                                    experienceOrVehicles:
                                        item.experienceOrVehicles,
                                    subtitle: item.subtitle,
                                    status: item.status,
                                    vehicleDetails: item.vehicleDetails,
                                    regNo: item.regNo,
                                    location: item.location,
                                    phone: item.phone,
                                    imageUrl: item.imageUrl,
                                    seating: item.seating,
                                    acStatus: item.acStatus,
                                    luggage: item.luggage,
                                    minCharge: item.minCharge,
                                    aboutDriver: item.aboutDriver,
                                    quoteText: item.quoteText,
                                    latitude: item.latitude,
                                    longitude: item.longitude,
                                    isElectric: item.isElectric,
                                    isWomenDriver: item.isWomenDriver,
                                    completedTrips: item.completedTrips,
                                    isOnline: item.isOnline,
                                    isVerified: item.isVerified,
                                    farePerKm: item.farePerKm,
                                  )))),
                      icon: const Icon(Icons.playlist_add_check,
                          color: Color(0xFF0F2E5A), size: 16),
                      label: const Text("View Packages",
                          style: TextStyle(
                              color: Color(0xFF0F2E5A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _callIconButton(item),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _makeCall(item.phone),
                      icon: const Icon(Icons.phone_in_talk,
                          color: Colors.white, size: 16),
                      label: const Text("Call Now",
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
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _openDetails(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      elevation: 0,
                      minimumSize: const Size(44, 40),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF0F2E5A), size: 14),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _callIconButton(PickupListing item) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => _makeCall(item.phone),
        icon: const Icon(Icons.phone_outlined,
            color: Color(0xFFFFB800), size: 18),
      ),
    );
  }

  void _openDetails(PickupListing item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => VehicleDetailsPage(listing: item.toAutoTaxiListing())));
  }

  void _showRadiusSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        const radii = [2.0, 5.0, 10.0, 20.0, 99.0];
        const labels = [
          'Within 2 km',
          'Within 5 km',
          'Within 10 km',
          'Within 20 km',
          'Entire City'
        ];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Search Radius",
                  style: TextStyle(
                      color: Color(0xFF0F2E5A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 12),
              ...List.generate(radii.length, (i) {
                final selected = searchRadiusKm == radii[i];
                return ListTile(
                  leading: Icon(Icons.radar,
                      color: selected
                          ? const Color(0xFF0F2E5A)
                          : const Color(0xFF94A3B8)),
                  title: Text(labels[i],
                      style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? const Color(0xFF0F2E5A)
                              : const Color(0xFF475569))),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF059669))
                      : null,
                  onTap: () {
                    setState(() => searchRadiusKm = radii[i]);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pickup & Pickup Guide",
            style: TextStyle(
                color: Color(0xFF0F2E5A), fontWeight: FontWeight.bold)),
        content: const Text(
          "Vehicles are ranked by proximity, rating, and availability. "
          "Use filters to find Women Drivers, Electric vehicles, or AC-only cabs. "
          "Switch to Map view to see vehicles live on a radar. "
          "Use the radar button to change your search radius.",
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it",
                style: TextStyle(color: Color(0xFF0F2E5A))),
          ),
        ],
      ),
    );
  }
}

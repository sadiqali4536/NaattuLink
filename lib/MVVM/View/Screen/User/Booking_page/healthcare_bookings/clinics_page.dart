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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clinic_doctors_page.dart';

// ─────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────
class ClinicListing {
  final String name;
  final String facilityName;
  final String rating;
  final String status;
  final String location;
  final String phone;
  final String imageUrl;
  final String speciality;
  final String availableTime;
  final String quoteText;

  final double latitude;
  final double longitude;
  final int totalReviews;
  final bool isVerified;

  ClinicListing({
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
    this.latitude = 11.2588,
    this.longitude = 75.7804,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  double distanceFrom(double userLat, double userLng) {
    return DistanceService.calculateDistanceInKm(userLat, userLng, latitude, longitude);
  }


  int etaMinutes(double userLat, double userLng) {
    final d = distanceFrom(userLat, userLng);
    return max(1, (d / 20.0 * 60).round());
  }
}

// ─────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────
class ClinicsPage extends StatefulWidget {
  final String healthcareType;
  final String pageTitle;

  const ClinicsPage({
    Key? key,
    this.healthcareType = 'Clinic',
    this.pageTitle = 'Clinics',
  }) : super(key: key);

  @override
  State<ClinicsPage> createState() => _ClinicsPageState();
}

class _ClinicsPageState extends State<ClinicsPage> {
  // UI state
  String searchQuery = '';
  String selectedTypeFilter = 'All';
  String selectedSmartFilter = 'Nearest';
  double searchRadiusKm = 10.0;

  // Location state
  double _userLat = 11.2588;
  double _userLng = 75.7804;
  bool _locationLoading = true;
  String _locationName = 'Detecting location...';
  bool _isLoadingListings = true;

  final Random _rng = Random();

  // ─── Listings ───────────────────────────────────
  List<ClinicListing> _allListings = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
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

  Future<void> _fetchListingsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('healthcare')
          .where('healthcare_type', isEqualTo: widget.healthcareType)
          .get();

      final List<ClinicListing> fetchedListings = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['status']?.toString().toLowerCase() != 'active') {
          continue;
        }

        final rawRating = data['ratings'] ?? 0;
        final totalReviews = data['total_reviews'] ?? 0;
        final ratingStr = "$rawRating ($totalReviews)";

        final isVerifiedFlag =
            data['isVerified'] == 1 || data['isVerified'] == true;

        String address = data['address'] ?? "Kozhikode";
        double lat = 11.2588;
        double lng = 75.7804;

        try {
          List<Location> locations =
              await locationFromAddress("$address, Kerala, India");
          if (locations.isNotEmpty) {
            lat = locations.first.latitude;
            lng = locations.first.longitude;
          }
        } catch (e) {
          lat += (_rng.nextDouble() - 0.5) * 0.05;
          lng += (_rng.nextDouble() - 0.5) * 0.05;
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
            name: data['username'] ?? "Clinic Doctor",
            facilityName: data['facility_name'] ?? "Clinic",
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
      if (mounted) {
        setState(() {
          _isLoadingListings = false;
        });
      }
    }
  }

  // ─── Location ────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
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
        // ignore
      }

      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
        _locationLoading = false;
        _locationName = '$localityName, $cityName';
      });
    } catch (_) {
      setState(() {
        _locationLoading = false;
        _locationName = 'Kallai, Kozhikode';
      });
    }
  }

  // ─── Filtered + Ranked list ───────────────────────
  List<ClinicListing> get _rankedListings {
    List<ClinicListing> result = _allListings.where((item) {
      final locParts = _locationName.split(',');
      final userLocality = locParts.first.trim().toLowerCase();
      final userCity =
          locParts.length > 1 ? locParts.last.trim().toLowerCase() : '';

      final itemLoc = item.location.toLowerCase();
      if (userLocality.isNotEmpty || userCity.isNotEmpty) {
        if (!itemLoc.contains(userLocality) &&
            (userCity.isEmpty || !itemLoc.contains(userCity))) {
          final dist = item.distanceFrom(_userLat, _userLng);
          if (dist > 5.0) {
            return false;
          }
        }
      }

      final dist = item.distanceFrom(_userLat, _userLng);
      if (searchRadiusKm >= 99) {
        if (dist > 25.0) return false;
      } else {
        if (dist > searchRadiusKm) return false;
      }

      if (selectedTypeFilter != 'All' &&
          !item.speciality
              .toLowerCase()
              .contains(selectedTypeFilter.toLowerCase())) {
        return false;
      }

      if (selectedSmartFilter == 'My Location') {
        if (!itemLoc.contains(userLocality) &&
            (userCity.isEmpty || !itemLoc.contains(userCity))) {
          return false;
        }
      }

      final q = searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        return item.name.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.facilityName.toLowerCase().contains(q) ||
            item.speciality.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    result.sort((a, b) {
      return a
          .distanceFrom(_userLat, _userLng)
          .compareTo(b.distanceFrom(_userLat, _userLng));
    });

    return result;
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError("Could not start call.");
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
          _buildListHeader(),
          Expanded(
            child: _isLoadingListings
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F2E5A),
                    ),
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
                  hintText: "Search clinics, specialities...",
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon:
                      Icon(Icons.search, color: Color(0xFF0F2E5A), size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
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

  Widget _buildListHeader() {
    final count = _rankedListings.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$count ${count == 1 ? 'clinic' : 'clinics'} found",
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
              "No clinics found in this area",
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
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

  Widget _buildListingCard(ClinicListing item) {
    final dist = item.distanceFrom(_userLat, _userLng);
    final distStr = dist < 1
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicDoctorsPage(clinic: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(
                    0.03), // Will leave withOpacity to avoid Flutter version compatibility issues if withAlpha isn't perfectly supported in this version's Color API.
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
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_hospital_outlined,
                    color: Color(0xFF0F2E5A),
                    size: 28,
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
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.speciality,
                      style: const TextStyle(
                          color: Color(0xFF059669),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(item.status,
                        style: TextStyle(
                            color: statusText,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
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
              const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(item.availableTime,
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
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

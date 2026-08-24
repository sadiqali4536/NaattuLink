import 'dart:ui';
import 'dart:math';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get_storage/get_storage.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/vehicles_auto_taxi_bookings/auto_taxi_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/education_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/public_services_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/transportation_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/shops_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/healthcare_bookings/healthcare_categories_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/helpline_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/tuition_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/food_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/internet_cafe_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pickup_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/jcbs_page.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/recommendation_controller.dart';
import 'package:naattulink/MVVM/model/models/product_model.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/service_functions/ServiceCardwith map.dart';
import 'package:naattulink/MVVM/utils/widget/button/Scrollable/scrollable_horizontal_buttons.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/notifications_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:naattulink/MVVM/View/Screen/location/location_selection_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => HomepageState();
}

// Public so user_Dashboard can call resetToForYou() via GlobalKey
class HomepageState extends State<Homepage> {
  final NotchBottomBarController _controller = NotchBottomBarController(
    index: 0,
  );

  int? _safeRating(dynamic rating) {
    if (rating is num) return rating.toInt();
    return null;
  }

  String? username;
  int selectedCategoryIndex = 0;
  int _shuffleSeed = 0;
  int activeBannerIndex = 0;
  String searchQuery = "";
  double _minRating = 0;
  String _sortBy = 'None';
  late TextEditingController _searchController;
  Stream<QuerySnapshot>? _servicesStream;
  Stream<QuerySnapshot>? _advertisementsStream;
  Stream<DocumentSnapshot>? _globalContactStream;
  Stream<QuerySnapshot>? _notificationsStream;
  Stream<List<Map<String, dynamic>>>? _busSchedulesStream;
  Stream<List<Map<String, dynamic>>>? _busSchedulesStream2;

  // Bus tab state variables
  String selectedBusFilter = "All Types";
  String _selectedDistrict = "All Districts";
  String? _currentDistrict;
  bool _districtLoading = false;
  late TextEditingController _fromBusController;
  late TextEditingController _toBusController;
  final Set<String> _favoriteBuses = {};
  late Box _routesBox;
  final List<Map<String, String>> _savedRoutes = [];

  // Local Ads filter state
  String _selectedAdCategory = "All";

  // Home page scroll controller (for scroll-to-top & reset)
  final ScrollController _homeScrollController = ScrollController();

  // Scroll key for Upcoming Schedules section
  final GlobalKey _scheduleKey = GlobalKey();

  void _scrollToSchedule() {
    final ctx = _scheduleKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  final List<String> categoryList = [
    "For You",
    "Workers",
    "Bus",
    "Local Ads",
    "Online Shops",
  ];

  String get selectedCategory => categoryList[selectedCategoryIndex];

  @override
  void initState() {
    super.initState();
    _shuffleSeed = DateTime.now().millisecondsSinceEpoch;
    _searchController = TextEditingController();
    final String currentLoc = LocationController.to.currentLocation.value;
    final String defaultFrom = currentLoc.split(',').first.trim();
    _fromBusController = TextEditingController(text: defaultFrom);
    _toBusController = TextEditingController(text: "");
    loadUsername();
    _servicesStream =
        FirebaseFirestore.instance.collection('services').snapshots();
    _advertisementsStream = FirebaseFirestore.instance
        .collection('advertisements')
        .where('isActive', isEqualTo: true)
        .snapshots();
    _globalContactStream = FirebaseFirestore.instance
        .collection('advertisements')
        .doc('global_contact')
        .collection('ads_contact')
        .doc('contact')
        .snapshots();
    _notificationsStream =
        FirebaseFirestore.instance.collection('notifications').snapshots();

    // Initialize saved routes from Hive
    _routesBox = Hive.box('saved_routes_box');
    if (_routesBox.get('routes') == null) {
      _routesBox.put('routes', []);
    }

    // Fix: Initialize notification state on fresh install to prevent old notifications from triggering unread badge
    if (_routesBox.get('app_install_time') == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _routesBox.put('app_install_time', now);
      _routesBox.put('last_notification_read_time', now);
    }

    _loadSavedRoutes();

    _detectUserDistrict();
  }

  Future<void> _detectUserDistrict() async {
    String? savedDistrict = GetStorage().read<String>('selected_district');

    try {
      await LocationController.to.fetchLocation();

      String district = LocationController.to.district.value;
      if (district.isEmpty) {
        district = "Unknown";
      }

      if (mounted) {
        setState(() {
          _currentDistrict = district;
          _selectedDistrict = savedDistrict ?? "All Districts";
          _districtLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error detecting district: $e");
    }

    if (mounted) {
      setState(() {
        _selectedDistrict = savedDistrict ?? "All Districts";
        _districtLoading = false;
      });
    }
  }

  void _loadSavedRoutes() {
    final rawRoutes = _routesBox.get('routes');
    if (rawRoutes is List) {
      _savedRoutes.clear();
      for (var item in rawRoutes) {
        if (item is Map) {
          _savedRoutes.add({
            "from": (item['from'] ?? '').toString(),
            "to": (item['to'] ?? '').toString(),
          });
        }
      }
    }
  }

  void _clearBusSearch() {
    _fromBusController.clear();
    _toBusController.clear();
  }

  Future<void> loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final collections = ['users', 'healthcare'];
      Map<String, dynamic>? data;

      for (String collection in collections) {
        final doc = await getUserDocument(user, collection);
        if (doc != null && doc.exists) {
          data = doc.data() as Map<String, dynamic>?;
          break;
        }
      }

      if (data != null && mounted) {
        setState(() {
          username = data!['username'] ?? data!['facility_name'] ?? '----';
        });
      } else if (mounted) {
        setState(() {
          username = 'User';
        });
      }
    } else if (mounted) {
      setState(() {
        username = 'User';
      });
    }
  }

  int notificationCount = 0;

  void addNotification() {
    setState(() {
      notificationCount++;
    });
  }

  void clearNotifications() {
    setState(() {
      notificationCount = 0;
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _searchController.dispose();
    _fromBusController.dispose();
    _toBusController.dispose();
    super.dispose();
  }

  /// Called by user_Dashboard via GlobalKey when the Home tab is tapped.
  /// Resets the top category to "For You" and smoothly scrolls to the top.
  void resetToForYou() {
    loadUsername(); // Refresh the username
    setState(() {
      selectedCategoryIndex = 0;
      _selectedAdCategory = 'All';
      _clearBusSearch();
      _shuffleSeed = DateTime.now().millisecondsSinceEpoch;
    });
    if (_homeScrollController.hasClients) {
      _homeScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Fetches a service by [serviceId] from Firestore and navigates to
  /// [ServiceDetailsPage]. Shows a snackbar if the service is missing or inactive.
  Future<void> _openServiceFromBanner(
      BuildContext context, String? serviceId) async {
    if (serviceId == null || serviceId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This service is no longer available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show a loading dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId.trim())
          .get();

      // Dismiss loading
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This service is no longer available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'inactive') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This service is no longer available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final name = (data['service_name'] ?? 'Service').toString();
      final category = (data['category'] ?? '').toString();
      final image = (data['image_url'] ?? data['image'] ?? '').toString();
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(
              category: category,
              serviceName: name,
              rating: rating,
              originalPrice: data['original_price'] ?? 0,
              discount: data['discount'] ?? 0,
              image: image,
              discountPrice: data['discount_price'] ?? data['price'] ?? 0,
              serviceType: data['service_type'],
              businessLat: (data['businessLat'] as num?)?.toDouble(),
              businessLng: (data['businessLng'] as num?)?.toDouble(),
              businessAddress: data['businessAddress'] as String?,
              businessMapsUrl: data['businessMapsUrl'] as String?,
              serviceId: doc.id,
              providerId: data['providerId']?.toString() ??
                  data['uid']?.toString() ??
                  'Unknown',
              providerName: data['providerName']?.toString() ??
                  data['workerName']?.toString() ??
                  'Unknown',
              providerPhone: data['providerPhone']?.toString() ??
                  data['phone']?.toString() ??
                  '',
              serviceDescription: data['description']?.toString() ??
                  data['about']?.toString() ??
                  '',
              estimatedDuration: data['duration']?.toString() ?? '1 hr',
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading if still showing
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This service is no longer available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error opening service from banner: $e');
    }
  }

  Future<void> _openInAppPageFromBanner(
      BuildContext context, String? inAppPageId) async {
    if (inAppPageId == null || inAppPageId.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This page is currently unavailable.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final id = inAppPageId.trim().toLowerCase();

    switch (id) {
      case 'home':
      case 'for_you':
        setState(() {
          selectedCategoryIndex = 0;
        });
        break;
      case 'workers':
        setState(() {
          selectedCategoryIndex = 1;
        });
        break;
      case 'bus':
        setState(() {
          selectedCategoryIndex = 2;
        });
        break;
      case 'shopping':
        setState(() {
          selectedCategoryIndex = 4;
        });
        break;
      case 'healthcare':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const HealthcareCategoriesPage()));
        break;
      case 'taxi':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AutoTaxiPage()));
        break;
      case 'truck_jcb':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const JcbsPage()));
        break;
      case 'notifications':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const NotificationsPage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This page is currently unavailable.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  /// Fetches a product by [productId] from Firestore and navigates to
  /// [ServiceDetailsPage] (as a fallback). Shows a snackbar if the product is missing or inactive.
  Future<void> _openProductFromBanner(
      BuildContext context, String? productId) async {
    if (productId == null || productId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is no longer available.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show a loading dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId.trim())
          .get();

      // Dismiss loading
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (!doc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This product is no longer available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'inactive') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This product is no longer available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final name =
          (data['title'] ?? data['productName'] ?? 'Product').toString();
      final category = (data['category'] ?? '').toString();
      final image = (data['image'] ?? data['image_url'] ?? '').toString();
      final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final price = data['price'] ?? 0;

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(
              category: category,
              serviceName: name,
              rating: rating,
              originalPrice: price,
              discount: 0,
              image: image,
              discountPrice: price,
              serviceType: 'Product',
              businessLat: null,
              businessLng: null,
              businessAddress: null,
              businessMapsUrl: null,
              serviceId: doc.id,
              providerId: data['sellerId']?.toString() ?? 'Unknown',
              providerName: 'Seller',
              providerPhone: '',
              serviceDescription: data['description']?.toString() ?? '',
              estimatedDuration: '',
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading if still showing
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is no longer available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error opening product from banner: $e');
    }
  }

  void _showGlobalContactSheet(
      BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Banner Image
              // if (data['bannerImageUrl'] != null &&
              //     data['bannerImageUrl'].toString().isNotEmpty)
              //   ClipRRect(
              //     borderRadius:
              //         const BorderRadius.vertical(top: Radius.circular(16)),
              //     child: Image.network(
              //       data['bannerImageUrl'],
              //       width: double.infinity,
              //       height: 150,
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Need to publish an advertisement?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      "Contact our support team to publish your advertisement through a phone call or WhatsApp.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Two large action buttons — numbers are NOT displayed
                    Column(
                      children: [
                        // WhatsApp Button
                        if (data['whatsappNumber'] != null &&
                            data['whatsappNumber'].toString().isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final phone =
                                    "${data['whatsappCountryCode'] ?? ''}${data['whatsappNumber']}"
                                        .replaceAll('+', '')
                                        .replaceAll(' ', '');
                                final uri = Uri.parse('https://wa.me/$phone');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(FontAwesomeIcons.whatsapp,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    "WhatsApp",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (data['whatsappNumber'] != null &&
                            data['whatsappNumber'].toString().isNotEmpty &&
                            data['phoneNumber'] != null &&
                            data['phoneNumber'].toString().isNotEmpty)
                          const SizedBox(height: 12),
                        // Call Now Button
                        if (data['phoneNumber'] != null &&
                            data['phoneNumber'].toString().isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final uri =
                                    Uri.parse('tel:${data['phoneNumber']}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              icon: const Icon(Icons.phone_rounded,
                                  color: Colors.white, size: 22),
                              label: Text(
                                "Call Now",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumAppBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: _servicesStream ??=
              FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            final allServices = snapshot.hasData ? snapshot.data!.docs : [];

            // 1. Build category list dynamically starting with defaults
            final List<String> currentCategoryList = [
              "For You",
              "Workers",
              "Bus",
              "Local Ads",
              "Online Shops",
            ];
            // Clamp the selected category index
            if (selectedCategoryIndex >= currentCategoryList.length) {
              selectedCategoryIndex = 0;
            }
            final selected = currentCategoryList[selectedCategoryIndex];

            // Map to dbSelected category name
            String dbSelected = selected;
            if (selected == "For You" || selected == "Workers")
              dbSelected = "All";
            else if (selected == "Bus")
              dbSelected = "Interior";
            else if (selected == "Local Ads") dbSelected = "Vehicle";

            // 2. Filter services
            final filtered = allServices.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name =
                  (data['service_name'] ?? '').toString().toLowerCase();
              final category = (data['category'] ?? '').toString();
              final rating = (data['rating'] ?? 0).toDouble();
              final status = (data['status'] ?? '').toString().toLowerCase();

              final matchesCategory =
                  dbSelected == "All" || category == dbSelected;
              final sq = searchQuery.trim().toLowerCase();
              final matchesSearch = sq.isEmpty || name.contains(sq);
              final matchesRating = rating >= _minRating;
              final isActive = status != 'inactive';

              return matchesCategory &&
                  matchesSearch &&
                  matchesRating &&
                  isActive;
            }).toList();

            if (_sortBy == 'A-Z') {
              filtered.sort(
                (a, b) => (a['service_name'] ?? '').toString().compareTo(
                      (b['service_name'] ?? '').toString(),
                    ),
              );
            } else if (_sortBy == 'Rating') {
              filtered.sort(
                (a, b) => (b['rating'] ?? 0).compareTo((a['rating'] ?? 0)),
              );
            }

            // Render appropriate content in the services grid area

            return SingleChildScrollView(
              controller: _homeScrollController,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: selectedCategory == "Bus" ? 210 : 290,
                          ),
                          if (_searchController.text.isEmpty) ...[
                            StreamBuilder<DocumentSnapshot>(
                              stream: _globalContactStream,
                              builder: (context, globalContactSnap) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: _advertisementsStream,
                                  builder: (context, bannerSnap) {
                                    // While loading banners show skeleton
                                    if (bannerSnap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CarouselSkeleton(
                                        key: ValueKey('carousel_loading'),
                                      );
                                    }

                                    final bannerDocs =
                                        bannerSnap.data?.docs ?? [];

                                    // In-memory filter and sort to avoid composite index requirements
                                    final now = DateTime.now();
                                    final filteredDocs =
                                        bannerDocs.where((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;

                                      final position =
                                          data['bannerPosition'] ?? '';
                                      final showOnHome =
                                          data['showInForYou'] ?? true;

                                      bool matchesCategory = (position ==
                                          'Home -> $selectedCategory');
                                      if (selectedCategory == "For You") {
                                        matchesCategory =
                                            matchesCategory || showOnHome;
                                      }

                                      if (!matchesCategory) {
                                        return false;
                                      }

                                      // Filter by dates
                                      final startTimestamp =
                                          data['startDate'] as Timestamp?;
                                      final endTimestamp =
                                          data['endDate'] as Timestamp?;
                                      if (startTimestamp != null &&
                                          startTimestamp
                                              .toDate()
                                              .isAfter(now)) {
                                        return false;
                                      }
                                      if (endTimestamp != null &&
                                          endTimestamp.toDate().isBefore(now)) {
                                        return false;
                                      }

                                      return true;
                                    }).toList();

                                    // Sort in-memory: priority descending, then createdAt descending
                                    filteredDocs.sort((a, b) {
                                      final dataA =
                                          a.data() as Map<String, dynamic>;
                                      final dataB =
                                          b.data() as Map<String, dynamic>;

                                      final priorityA = dataA['priority'] ?? 0;
                                      final priorityB = dataB['priority'] ?? 0;
                                      if (priorityA != priorityB) {
                                        return (priorityB as num)
                                            .compareTo(priorityA as num);
                                      }

                                      final aTime =
                                          dataA['createdAt'] as Timestamp?;
                                      final bTime =
                                          dataB['createdAt'] as Timestamp?;
                                      if (aTime == null && bTime == null)
                                        return 0;
                                      if (aTime == null) return 1;
                                      if (bTime == null) return -1;
                                      return bTime.compareTo(aTime);
                                    });

                                    // Fallback: no banners from admin -> show placeholder
                                    final List<Widget> bannerItems = [];

                                    // Check for global contact banner
                                    final Map<String, dynamic>?
                                        globalContactData =
                                        globalContactSnap.data?.data()
                                            as Map<String, dynamic>?;

                                    if (globalContactData != null &&
                                        globalContactData['bannerImageUrl'] !=
                                            null &&
                                        globalContactData['bannerImageUrl']
                                            .toString()
                                            .isNotEmpty) {
                                      bannerItems.add(buildPromoCard(
                                          imageUrl: globalContactData[
                                              'bannerImageUrl'],
                                          onTap: () {
                                            _showGlobalContactSheet(
                                                context, globalContactData);
                                          }));
                                    }

                                    final adminBanners =
                                        filteredDocs.map((doc) {
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      return buildPromoCard(
                                        imageUrl: data['imageUrl'] ?? '',
                                        bannerImageUrl: data['bannerImageUrl'],
                                        title: data['title'] ?? '',
                                        buttonText: data['buttonText'],
                                        buttonBackgroundColor:
                                            data['buttonBackgroundColor'],
                                        buttonTextColor:
                                            data['buttonTextColor'],
                                        onTap: () async {
                                          final action = data['bannerAction'] ??
                                              data['buttonAction'] ??
                                              '';
                                          final value = data['actionValue'] ??
                                              data['website'] ??
                                              '';
                                          if (action == 'Open Product') {
                                            await _openProductFromBanner(
                                              context,
                                              data['productId']?.toString(),
                                            );
                                          } else if (action == 'Open Service') {
                                            await _openServiceFromBanner(
                                              context,
                                              data['serviceId']?.toString(),
                                            );
                                          } else if (action ==
                                              'Open In-App Page') {
                                            await _openInAppPageFromBanner(
                                              context,
                                              data['inAppPageId']?.toString() ??
                                                  data['actionValue']
                                                      ?.toString(),
                                            );
                                          } else if (action == 'Open URL' &&
                                              value.toString().isNotEmpty) {
                                            final uri =
                                                Uri.tryParse(value.toString());
                                            if (uri != null) {
                                              try {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              } catch (e) {
                                                debugPrint(
                                                    'Error launching URL: $e');
                                              }
                                            }
                                          }
                                        },
                                        onButtonTap: () async {
                                          final action = data['buttonAction'] ??
                                              data['bannerAction'] ??
                                              '';
                                          final value = data['actionValue'] ??
                                              data['website'] ??
                                              '';
                                          final valStr =
                                              value.toString().trim();

                                          if (action == 'Open Product') {
                                            await _openProductFromBanner(
                                              context,
                                              data['productId']?.toString(),
                                            );
                                          } else if (action == 'Open Service') {
                                            await _openServiceFromBanner(
                                              context,
                                              data['serviceId']?.toString(),
                                            );
                                          } else if (action ==
                                              'Open In-App Page') {
                                            await _openInAppPageFromBanner(
                                              context,
                                              data['inAppPageId']?.toString() ??
                                                  data['actionValue']
                                                      ?.toString(),
                                            );
                                          } else if (action == 'Open URL') {
                                            if (valStr.isEmpty) return;
                                            final uri = Uri.tryParse(valStr);
                                            if (uri != null) {
                                              try {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              } catch (e) {
                                                debugPrint(
                                                    'Error launching URL: $e');
                                              }
                                            }
                                          } else if (action ==
                                              'Open WhatsApp') {
                                            if (valStr.isEmpty) return;
                                            final phone = valStr.replaceAll(
                                                RegExp(r'[^0-9]'), '');
                                            final uri = Uri.parse(
                                                'https://wa.me/$phone');
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          } else if (action == 'Call') {
                                            if (valStr.isEmpty) return;
                                            final uri =
                                                Uri.parse('tel:$valStr');
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri);
                                            }
                                          }
                                        },
                                      );
                                    }).toList();

                                    bannerItems.addAll(adminBanners);

                                    if (bannerItems.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    final bannerCount = bannerItems.length;

                                    int localActiveIndex = 0;
                                    return AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      child: StatefulBuilder(
                                        key: const ValueKey('carousel_loaded'),
                                        builder: (context, setLocalState) {
                                          return Column(
                                            children: [
                                              CarouselSlider(
                                                items: bannerItems,
                                                options: CarouselOptions(
                                                  autoPlay: bannerCount > 1,
                                                  enlargeCenterPage: false,
                                                  aspectRatio: 1.8,
                                                  viewportFraction: 1,
                                                  onPageChanged:
                                                      (index, reason) {
                                                    setLocalState(() {
                                                      localActiveIndex = index;
                                                    });
                                                  },
                                                ),
                                              ),
                                              if (bannerCount > 1) ...[
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: List.generate(
                                                    bannerCount,
                                                    (index) {
                                                      return AnimatedContainer(
                                                        duration:
                                                            const Duration(
                                                          milliseconds: 250,
                                                        ),
                                                        width:
                                                            localActiveIndex ==
                                                                    index
                                                                ? 15
                                                                : 6,
                                                        height: 6,
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 3,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            3,
                                                          ),
                                                          color:
                                                              localActiveIndex ==
                                                                      index
                                                                  ? const Color(
                                                                      0xFFFFB800,
                                                                    )
                                                                  : Colors.grey[
                                                                      300],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                          if (selectedCategory == "For You" &&
                              _searchController.text.isEmpty)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const Column(
                                      key: ValueKey('loading_dashboard'),
                                      children: [
                                        ExpertServicesSkeleton(),
                                        SizedBox(height: 20),
                                        CityEssentialsSkeleton(),
                                        SizedBox(height: 20),
                                        MarketplaceSkeleton(),
                                        SizedBox(height: 20),
                                        SpotlightSkeleton(),
                                        SizedBox(height: 20),
                                        CommunityNewsSkeleton(),
                                        SizedBox(height: 20),
                                        TrustSectionSkeleton(),
                                      ],
                                    )
                                  : buildForYouDashboard(
                                      filtered,
                                      key: const ValueKey('loaded_dashboard'),
                                    ),
                            )
                          else if (selectedCategory == "Workers" &&
                              _searchController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const ServiceCardListSkeleton()
                                  : buildWorkersTab(filtered),
                            )
                          else if (selectedCategory == "Bus")
                            buildBusTab()
                          else if (selectedCategory == "Local Ads" &&
                              _searchController.text.isEmpty)
                            buildLocalAdsTab(allServices)
                          else if (selectedCategory == "Online Shops" &&
                              _searchController.text.isEmpty)
                            buildOnlineShopsTab()
                          else if (_searchController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const ServiceCardListSkeleton()
                                  : filtered.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.only(top: 100.0),
                                          child: Center(
                                            child: Text(
                                              "No results found for your search.",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                      : buildWorkersTab(filtered),
                            ),

                          const SizedBox(height: 130), // bottom bar spacing
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: selectedCategory == "Bus" ? 200 : 280,
                        width: double.infinity,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F2E5A), // Premium navy color
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 48,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: username == null
                                        ? const HeaderSkeleton(
                                            key: ValueKey('header_loading'),
                                          )
                                        : Padding(
                                            key: const ValueKey(
                                              'header_loaded',
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        const Color(
                                                      0xFFFFB800,
                                                    ), // Gold accent
                                                    child: Text(
                                                      username != null &&
                                                              username!
                                                                  .isNotEmpty
                                                          ? username![0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        username ?? 'Hello!',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final loc =
                                                              LocationController
                                                                  .to
                                                                  .currentLocation
                                                                  .value;
                                                          if (loc.isEmpty ||
                                                              loc ==
                                                                  'Unknown Location' ||
                                                              loc ==
                                                                  'Selected Location') {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                  content: Text(
                                                                      'Fetching location...')),
                                                            );
                                                            await LocationController
                                                                .to
                                                                .fetchLocation(
                                                                    forceRefresh:
                                                                        true);
                                                          } else {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const LocationSelectionPage(),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Obx(() {
                                                          final loc =
                                                              LocationController
                                                                  .to
                                                                  .currentLocation
                                                                  .value;
                                                          String shortLoc = loc;
                                                          if (loc.isNotEmpty &&
                                                              loc !=
                                                                  'Unknown Location' &&
                                                              loc !=
                                                                  'Selected Location') {
                                                            List<String> parts =
                                                                loc.split(',');
                                                            if (parts
                                                                .isNotEmpty) {
                                                              shortLoc =
                                                                  parts[0]
                                                                      .trim();
                                                              if (parts.length >
                                                                  1) {
                                                                shortLoc += ", " +
                                                                    parts[1]
                                                                        .trim();
                                                              }
                                                              if (shortLoc
                                                                      .length >
                                                                  25) {
                                                                shortLoc =
                                                                    "${shortLoc.substring(0, 25)}...";
                                                              }
                                                            }
                                                          }
                                                          final displayText = loc
                                                                  .isEmpty
                                                              ? 'Fetch Location'
                                                              : shortLoc;
                                                          return Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .location_on_outlined,
                                                                color: Colors
                                                                    .white70,
                                                                size: 12,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Flexible(
                                                                child: Text(
                                                                  displayText,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 2),
                                                              const Icon(
                                                                Icons
                                                                    .keyboard_arrow_down,
                                                                color: Colors
                                                                    .white70,
                                                                size: 12,
                                                              ),
                                                            ],
                                                          );
                                                        }),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                StreamBuilder<QuerySnapshot>(
                                                  stream: _notificationsStream,
                                                  builder: (context, snapshot) {
                                                    int unreadCount = 0;
                                                    if (snapshot.hasData) {
                                                      final lastRead = Hive.box(
                                                        'saved_routes_box',
                                                      ).get(
                                                        'last_notification_read_time',
                                                        defaultValue: 0,
                                                      ) as int;
                                                      for (var doc in snapshot
                                                          .data!.docs) {
                                                        final data = doc.data()
                                                            as Map<String,
                                                                dynamic>?;
                                                        if (data != null &&
                                                            data['created_at'] !=
                                                                null) {
                                                          final timestamp =
                                                              data['created_at']
                                                                  as Timestamp;
                                                          if (timestamp
                                                                  .millisecondsSinceEpoch >
                                                              lastRead) {
                                                            unreadCount++;
                                                          }
                                                        }
                                                      }
                                                    }
                                                    return Stack(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .notifications_none_outlined,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed: () {
                                                            Hive.box(
                                                              'saved_routes_box',
                                                            ).put(
                                                              'last_notification_read_time',
                                                              DateTime.now()
                                                                  .millisecondsSinceEpoch,
                                                            );
                                                            setState(
                                                              () {},
                                                            ); // to instantly clear the badge before stream re-emits
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    const NotificationsPage(),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                        if (unreadCount > 0)
                                                          Positioned(
                                                            right: 8,
                                                            top: 8,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                4,
                                                              ),
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              constraints:
                                                                  const BoxConstraints(
                                                                minWidth: 16,
                                                                minHeight: 16,
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  unreadCount >
                                                                          9
                                                                      ? '9+'
                                                                      : unreadCount
                                                                          .toString(),
                                                                  style:
                                                                      const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                Visibility(
                                                  visible: false,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                      Icons.menu,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {},
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                if (selectedCategory != "Bus") ...[
                                  const SizedBox(height: 12),
                                  // Search field with integrated filter and mic buttons inside
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextFormField(
                                        controller: _searchController,
                                        onChanged: (value) =>
                                            setState(() => searchQuery = value),
                                        onFieldSubmitted: (value) {
                                          RecommendationController.to
                                              .trackSearch(value, 'Other');
                                        },
                                        decoration: InputDecoration(
                                          hintText:
                                              "Search for workers, services...",
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          prefixIcon: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Image.asset(
                                              "assets/icons/serch_icon.png",
                                              color: const Color(0xFF0F2E5A),
                                              height: 18,
                                              width: 18,
                                            ),
                                          ),
                                          suffixIcon: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 20,
                                                width: 1,
                                                color: Colors.grey[300],
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () =>
                                                    showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                      top: Radius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                  ),
                                                  builder: (context) =>
                                                      buildFilterSheet(),
                                                ),
                                                child: const Icon(
                                                  Icons.qr_code_scanner,
                                                  color: Color(0xFF64748B),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  right: 14.0,
                                                ),
                                                child: Icon(
                                                  Icons.mic_none_outlined,
                                                  color: Color(0xFF64748B),
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 80,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: snapshot.connectionState ==
                                            ConnectionState.waiting
                                        ? const CategoryRowSkeleton(
                                            key: ValueKey('category_loading'),
                                          )
                                        : ScrollableHorizontalButtons(
                                            key: const ValueKey(
                                              'category_loaded',
                                            ),
                                            categories: currentCategoryList,
                                            selectedIndex:
                                                selectedCategoryIndex,
                                            onSelected: (index) {
                                              setState(() {
                                                selectedCategoryIndex = index;
                                                _clearBusSearch();
                                                _shuffleSeed = DateTime.now()
                                                    .millisecondsSinceEpoch;
                                                if (currentCategoryList[
                                                        index] ==
                                                    "Bus") {
                                                  _searchController.clear();
                                                  searchQuery = "";
                                                }
                                              });
                                              if (index <
                                                  currentCategoryList.length) {
                                                RecommendationController.to
                                                    .trackCategoryClick(
                                                  currentCategoryList[index],
                                                );
                                              }
                                            },
                                            isDark: true,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Parses a hex color string like "#1565C0" or "1565C0".
  /// Returns [fallback] if the string is null, empty, or invalid.
  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    try {
      final h = hex.replaceAll('#', '').trim();
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return fallback;
  }

  /// Builds a promotional banner card.
  /// [imageUrl] — network URL from Firestore; falls back to asset placeholder if empty.
  /// [title]    — optional overlay text set by the admin.
  Widget buildPromoCard({
    required String imageUrl,
    String? bannerImageUrl,
    String title = '',
    String? buttonText,
    String? buttonBackgroundColor,
    String? buttonTextColor,
    VoidCallback? onTap,
    VoidCallback? onButtonTap,
  }) {
    final bool isNetwork = imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // ── Banner image (network or local placeholder) ──
              if (isNetwork)
                Image.network(
                  imageUrl,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const ShimmerEffect(
                      child: SkeletonPlaceholder(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 12,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) =>
                      bannerImageUrl != null && bannerImageUrl.isNotEmpty
                          ? Image.network(bannerImageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey, size: 40),
                                  ))
                          : const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey, size: 40),
                            ),
                )
              else
                bannerImageUrl != null && bannerImageUrl.isNotEmpty
                    ? Image.network(bannerImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey, size: 40),
                            ))
                    : const SizedBox.shrink(),
              // ── Gradient overlay ──
              // Positioned.fill(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       gradient: LinearGradient(
              //         colors: [
              //           Colors.black.withOpacity(0.70),
              //           Colors.black.withOpacity(0.30),
              //           Colors.transparent,
              //         ],
              //         begin: Alignment.bottomCenter,
              //         end: Alignment.topCenter,
              //         stops: const [0.0, 0.55, 1.0],
              //       ),
              //     ),
              //   ),
              // ),
              // ── Title and CTA Button overlay ──
              if (title.isNotEmpty ||
                  (buttonText != null &&
                      buttonText.trim().isNotEmpty &&
                      buttonText.toLowerCase() != 'no text'))
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expanded(
                      //   child: title.isNotEmpty
                      //       ? Text(
                      //           title,
                      //           maxLines: 2,
                      //           overflow: TextOverflow.ellipsis,
                      //           style: const TextStyle(
                      //             color: Colors.white,
                      //             fontSize: 16,
                      //             fontWeight: FontWeight.w700,
                      //             letterSpacing: 0.3,
                      //             height: 1.3,
                      //             shadows: [
                      //               Shadow(
                      //                 color: Colors.black54,
                      //                 blurRadius: 6,
                      //                 offset: Offset(0, 2),
                      //               ),
                      //             ],
                      //           ),
                      //         )
                      //       : const SizedBox.shrink(),
                      // ),
                      if (buttonText != null &&
                          buttonText.trim().isNotEmpty &&
                          buttonText.toLowerCase() != 'no text')
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: onButtonTap ?? onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _parseHexColor(
                                buttonBackgroundColor,
                                const Color(0xFF0F2E5A),
                              ),
                              foregroundColor: _parseHexColor(
                                buttonTextColor,
                                Colors.white,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _parseHexColor(
                                  buttonTextColor,
                                  Colors.white,
                                ),
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
      ),
    );
  }

  IconData _getIconForSubcategory(String name) {
    switch (name) {
      // Healthcare
      case "Hospital":
        return Icons.local_hospital;
      case "Clinic":
        return Icons.medical_services;
      case "Pharmacy":
        return Icons.local_pharmacy;
      case "Laboratory":
        return Icons.science;

      // Shops
      case "Restaurant":
        return Icons.restaurant;
      case "Bakery":
        return Icons.cake;
      case "Grocery":
        return Icons.local_grocery_store;
      case "Supermarket":
        return Icons.store;
      case "Online Store":
        return Icons.shopping_cart;
      case "Fruits & Vegetables":
        return Icons.eco;
      case "Meat & Fish":
        return Icons.set_meal;
      case "Stationery":
        return Icons.menu_book;
      case "Mobile Shop":
        return Icons.phone_android;
      case "Electronics":
        return Icons.electrical_services;
      case "Fashion":
        return Icons.checkroom;
      case "Footwear":
        return Icons
            .dry_cleaning; // do_not_step is sometimes not available in older flutter, dry_cleaning or snowshoe
      case "Jewellery":
        return Icons.diamond;

      // Transportation
      case "Auto Taxi":
        return Icons.local_taxi;
      case "Pickup":
        return Icons.local_shipping;
      case "JCB":
        return Icons.precision_manufacturing;
      case "Bus":
        return Icons.directions_bus;
      case "Car Rental":
        return Icons.car_rental;

      // Education
      case "Tuition":
        return Icons.school;
      case "Coaching Centre":
        return Icons.cast_for_education;
      case "Computer Institute":
        return Icons.computer;
      case "Spoken English":
        return Icons.record_voice_over;

      // Public Services
      case "Helpline":
        return Icons.support_agent;
      case "Government Offices":
        return Icons.account_balance;
      case "Police":
        return Icons.local_police;
      case "Fire Station":
        return Icons.local_fire_department;
      case "Post Office":
        return Icons.local_post_office;

      default:
        return Icons.category;
    }
  }

  void _showSubcategoriesSheet(
    BuildContext context,
    String title,
    List<String> subcategories,
    void Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: subcategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(subcategories[index]);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEF2FF),
                              shape: BoxShape.circle,
                            ),
                            child: subcategories[index] == "JCB"
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Image.asset(
                                      "assets/icons/jcb.png",
                                      color: const Color(0xFF0F2E5A),
                                    ),
                                  )
                                : Icon(
                                    _getIconForSubcategory(
                                      subcategories[index],
                                    ),
                                    color: const Color(0xFF0F2E5A),
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subcategories[index],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildFilterSheet() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filter Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minimum Rating'),
              DropdownButton<double>(
                value: _minRating,
                items: [0, 1, 2, 3, 4, 5].map((e) {
                  return DropdownMenuItem<double>(
                    value: e.toDouble(),
                    child: Text(e == 0 ? 'Any' : '$e+ Stars'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _minRating = value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sort By'),
              DropdownButton<String>(
                value: _sortBy,
                items: ['None', 'A-Z', 'Rating'].map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildForYouDashboard(List<dynamic> services, {Key? key}) {
    final recController = RecommendationController.to;

    return Obx(() {
      if (recController.isLoading.value) {
        return const Column(
          children: [
            ExpertServicesSkeleton(),
            SizedBox(height: 20),
            CityEssentialsSkeleton(),
            SizedBox(height: 20),
            MarketplaceSkeleton(),
            SizedBox(height: 20),
            SpotlightSkeleton(),
            SizedBox(height: 20),
            CommunityNewsSkeleton(),
            SizedBox(height: 20),
            TrustSectionSkeleton(),
          ],
        );
      }

      // Helper widget for horizontal expert services carousel
      Widget buildExpertServicesCarousel(List<dynamic> rawServices) {
        var expertServices = rawServices.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = (data['status'] ?? '').toString().toLowerCase();
          return status != 'inactive';
        }).toList();

        if (expertServices.isEmpty) return const SizedBox.shrink();

        expertServices.shuffle(Random(_shuffleSeed));
        if (expertServices.length > 5) {
          expertServices = expertServices.take(5).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Expert Services",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Highly-rated local professionals",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryIndex = 1; // Switch to Workers tab
                      });
                      if (_homeScrollController.hasClients) {
                        _homeScrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: expertServices.map((service) {
                  final data = service.data() as Map<String, dynamic>? ?? {};
                  final name = data['service_name'] ?? '';
                  final category = data['category'] ?? '';
                  final rating = (data['rating'] ?? 0.0).toDouble();
                  final price = data['price'] ?? 0;
                  final image = data['image'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsPage(
                            category: category,
                            serviceName: name,
                            rating: rating,
                            originalPrice: data['original_price'] ?? 0,
                            discount: data['discount'] ?? 0,
                            image: image,
                            discountPrice: price,
                            serviceType: data['service_type'],
                            businessLat:
                                (data['businessLat'] as num?)?.toDouble(),
                            businessLng:
                                (data['businessLng'] as num?)?.toDouble(),
                            businessAddress: data['businessAddress'] as String?,
                            businessMapsUrl: data['businessMapsUrl'] as String?,
                            serviceId: service.id,
                            providerId: data['providerId']?.toString() ??
                                data['uid']?.toString() ??
                                'Unknown',
                            providerName: data['providerName']?.toString() ??
                                data['workerName']?.toString() ??
                                'Unknown',
                            providerPhone: data['providerPhone']?.toString() ??
                                data['phone']?.toString() ??
                                '',
                            serviceDescription:
                                data['description']?.toString() ??
                                    data['about']?.toString() ??
                                    '',
                            estimatedDuration:
                                data['duration']?.toString() ?? '1 hr',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(
                        right: 14,
                        bottom: 6,
                        top: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                                child: image.startsWith('http')
                                    ? Image.network(
                                        image,
                                        height: 95,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 95,
                                          width: double.infinity,
                                          color: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        image,
                                        height: 95,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 95,
                                          width: double.infinity,
                                          color: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 11,
                                        color: Color(0xFF0F2E5A),
                                      ),
                                      const SizedBox(width: 2.5),
                                      Text(
                                        rating.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F2E5A),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2E5A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "₹$price ",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F2E5A),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: "onwards",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      }

      // Reusable widget for horizontal product carousels

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _shuffleSeed = DateTime.now().millisecondsSinceEpoch;
          });
          await recController.fetchRecommendations();
        },
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            buildExpertServicesCarousel(services),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "City Essentials",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 0,
                      runSpacing: 18,
                      alignment: WrapAlignment.start,
                      children: [
                        buildEssentialItem(
                          imagePath: "assets/image/online_sevices.png",
                          label: "Online Services",
                          bgColor: const Color.fromARGB(255, 255, 255, 255),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InternetCafePage(),
                              ),
                            );
                          },
                        ),
                        buildEssentialItem(
                          imagePath: 'assets/image/healthcare.png',
                          label: "Healthcare",
                          bgColor: const Color.fromARGB(255, 251, 251, 251),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const HealthcareCategoriesPage(),
                              ),
                            );
                          },
                        ),
                        buildEssentialItem(
                          imagePath: 'assets/image/shops.png',
                          label: "Shops",
                          bgColor: const Color.fromARGB(255, 255, 255, 255),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ShopsCategoriesPage(),
                              ),
                            );
                          },
                        ),
                        buildEssentialItem(
                          imagePath: 'assets/image/tranportation.png',
                          label: "Transportation",
                          bgColor: const Color.fromARGB(255, 255, 255, 255),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TransportationCategoriesPage(),
                              ),
                            );
                          },
                        ),
                        buildEssentialItem(
                          imagePath: "assets/image/education.png",
                          label: "Education",
                          bgColor: const Color.fromARGB(255, 255, 255, 255),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EducationCategoriesPage(),
                              ),
                            );
                          },
                        ),
                        buildEssentialItem(
                          imagePath: "assets/image/public_services.png",
                          label: "Public Services",
                          bgColor: const Color.fromARGB(255, 255, 255, 255),
                          iconColor: const Color(0xFF0F2E5A),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PublicServicesCategoriesPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Local Marketplace Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Local Marketplace",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Top Deals",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  SizedBox(
                    width: 160,
                    child: buildMarketplaceCard(
                      image:
                          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=300&q=80",
                      title: "Premium Calicut Halwa",
                      price: 320,
                      originalPrice: 400,
                      discountBadge: "20% OFF",
                      discountColor: const Color(0xFFEF4444),
                      bottomInfo: "🚚 Free Delivery",
                      bottomInfoColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 160,
                    child: buildMarketplaceCard(
                      image:
                          "https://images.unsplash.com/photo-1616627547584-bf28cee262db?auto=format&fit=crop&w=300&q=80",
                      title: "Bamboo Lamp Shade",
                      price: 850,
                      originalPrice: 1200,
                      discountBadge: "HOT DEAL",
                      discountColor: const Color(0xFFFFB800),
                      bottomInfo: "⏳ Limited Stock",
                      bottomInfoColor: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 160,
                    child: buildMarketplaceCard(
                      image:
                          "https://images.unsplash.com/photo-1583209814683-c023dd293cc6?auto=format&fit=crop&w=300&q=80",
                      title: "Handmade Kerala Saree",
                      price: 1530,
                      originalPrice: 1800,
                      discountBadge: "15% OFF",
                      discountColor: const Color(0xFF8B5CF6),
                      bottomInfo: "🚚 Free Delivery",
                      bottomInfoColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                "Local Shop Spotlight",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  buildSpotlightCard(
                    shopName: "Zayan Textiles",
                    location: "Calicut Beach Road",
                    offer: "Flat 30% Off",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F2E5A), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  buildSpotlightCard(
                    shopName: "Green Grocers",
                    location: "Thalayad Road",
                    offer: "Fresh Organic: 10% Off",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget buildEssentialItem({
    IconData? icon,
    String? imagePath,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 4,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Center(
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        height: 32,
                        width: 32,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMarketplaceCard({
    required String image,
    required String title,
    required double price,
    required double originalPrice,
    required String discountBadge,
    required Color discountColor,
    required String bottomInfo,
    required Color bottomInfoColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        height: 115,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 115,
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 28,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "No Connection",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 10),
                              )
                            ],
                          ),
                        ),
                      )
                    : Image.asset(
                        image,
                        height: 115,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 115,
                          width: double.infinity,
                          color: const Color(0xFFF1F5F9),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 28,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "No Connection",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 10),
                              )
                            ],
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: discountColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    discountBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "₹${price.round()}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "₹${originalPrice.round()}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  bottomInfo,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: bottomInfoColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSpotlightCard({
    required String shopName,
    required String location,
    required String offer,
    required Gradient gradient,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 14, bottom: 4, top: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shopName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              location,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    offer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Visit Store",
                    style: TextStyle(
                      color: Color(0xFF0F2E5A),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNewsItem({
    required String image,
    required String title,
    required String timeAndSource,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image.startsWith('http')
              ? Image.network(
                  image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.black12,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Image.asset(
                  image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.black12,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeAndSource,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTrustBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFB800), size: 24),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget buildWorkersTab(List<dynamic> filtered) {
    List<dynamic> displayList = List.from(filtered);

    // Shuffle the list for display if no explicit sort is applied
    if (_sortBy == 'None') {
      displayList.shuffle(Random(_shuffleSeed));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Directory",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2E5A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Find the right expert for your task",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 14.0,
            mainAxisExtent: 235,
          ),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final service = displayList[index];
            final data = service.data() as Map<String, dynamic>;
            final name = data['service_name'] ?? '';
            final category = data['category'] ?? '';
            final rating = (data['rating'] ?? 0.0).toDouble();
            final price = data['price'] ?? 0;
            final image = data['image'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceDetailsPage(
                      category: category,
                      serviceName: name,
                      rating: rating,
                      originalPrice: data['original_price'] ?? 0,
                      discount: data['discount'] ?? 0,
                      image: image,
                      discountPrice: price,
                      serviceType: data['service_type'],
                      businessLat: (data['businessLat'] as num?)?.toDouble(),
                      businessLng: (data['businessLng'] as num?)?.toDouble(),
                      businessAddress: data['businessAddress'] as String?,
                      businessMapsUrl: data['businessMapsUrl'] as String?,
                      serviceId: data['id']?.toString() ??
                          data['serviceId']?.toString() ??
                          'Unknown',
                      providerId: data['providerId']?.toString() ??
                          data['uid']?.toString() ??
                          'Unknown',
                      providerName: data['providerName']?.toString() ??
                          data['workerName']?.toString() ??
                          'Unknown',
                      providerPhone: data['providerPhone']?.toString() ??
                          data['phone']?.toString() ??
                          '',
                      serviceDescription: data['description']?.toString() ??
                          data['about']?.toString() ??
                          '',
                      estimatedDuration: data['duration']?.toString() ?? '1 hr',
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFEFEF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: image.startsWith('http')
                          ? Image.network(
                              image,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 110,
                                width: double.infinity,
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : image.isNotEmpty
                              ? Image.asset(
                                  image,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 110,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 110,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2E5A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2E5A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Starts from ₹$price",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              "Book Now",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2E5A),
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
        ),
      ],
    );
  }

  Widget buildOnlineShopsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // 1. "Sadiq, still looking for these?" purple gradient box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${username ?? 'Sadiq'}, still looking for these?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 145,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildLookingForCard(
                        "Vehicle Body Cover",
                        "assets/image/car_clean.png",
                        "Shop Now",
                      ),
                      _buildLookingForCard(
                        "All Purpose Cleaner",
                        "assets/image/carpet.png",
                        "Shop Now",
                      ),
                      _buildLookingForCard(
                        "Car Shampoo",
                        "assets/image/carpet.png",
                        "Shop Now",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Smart TV Promo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "55\" Ultra HD (4K) Smart TV",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "From ₹19,999*",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text(
                          "Buy",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Icon(
                    Icons.tv_outlined,
                    size: 80,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Flash Sale Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Flash Sale",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildTimerUnit("09"),
                  const Text(
                    " : ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildTimerUnit("59"),
                  const Text(
                    " : ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildTimerUnit("50"),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "SEE ALL",
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFlashSaleCard(
                      "TRUFFLE CAKE",
                      "₹499",
                      "₹999",
                      "50% OFF",
                      "assets/image/add_image.png",
                    ),
                    _buildFlashSaleCard(
                      "PREMIUM WATCH",
                      "₹2,489",
                      "₹5,000",
                      "50% OFF",
                      "assets/image/add_image.png",
                    ),
                    _buildFlashSaleCard(
                      "OFFICE CHAIR",
                      "₹4,999",
                      "₹9,999",
                      "50% OFF",
                      "assets/image/add_image.png",
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Suggested For You Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Suggested For You",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: [
                  _buildSuggestedCard(
                    "FOXCARE Windshield Wash...",
                    "₹249",
                    "₹499",
                    "100+ ordered this week",
                    "assets/image/add_image.png",
                  ),
                  _buildSuggestedCard(
                    "Premium Car Cover",
                    "₹1,499",
                    "₹2,999",
                    "2,300+ ordered this week",
                    "assets/image/car_clean.png",
                  ),
                  _buildSuggestedCard(
                    "SEVINCAR Multi-purpose...",
                    "₹269",
                    "₹499",
                    "150+ ordered this week",
                    "assets/image/carpet.png",
                  ),
                  _buildSuggestedCard(
                    "Pro Phone 13 Ultra",
                    "₹54,999",
                    "₹1,20,000",
                    "10,000+ ordered this week",
                    "assets/image/carpet.png",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Trending Near You Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Trending Near You",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTrendingCard(
                      "SNEAKERS",
                      "4.8",
                      "₹4,199",
                      "assets/image/add_image.png",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTrendingCard(
                      "GOLD RING",
                      "4.9",
                      "₹48,350",
                      "assets/image/add_image.png",
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Special Deals for You Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6D28D9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Combo Sales Fest",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Enjoy extra 10% off on all collections using\n'OFF10' coupon code.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCA8A04),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text(
                    "Claim now",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookingForCard(
    String title,
    String imageAsset,
    String actionText,
  ) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.purple,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            actionText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerUnit(String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        unit,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFlashSaleCard(
    String title,
    String price,
    String originalPrice,
    String badge,
    String imageAsset,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.cake_outlined,
                          size: 40,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      originalPrice,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(
    String title,
    String price,
    String originalPrice,
    String orderText,
    String imageAsset,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                originalPrice,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            orderText,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(
    String title,
    String rating,
    String price,
    String imageAsset,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAsset,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag,
                      size: 50,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.grey,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getBusSchedulesStream() {
    return FirebaseFirestore.instance
        .collection('transports')
        .where('transport_category', isEqualTo: 'Bus')
        .snapshots()
        .switchMap((transportsSnapshot) {
      if (transportsSnapshot.docs.isEmpty) {
        return Stream.value([]);
      }

      final List<Stream<List<Map<String, dynamic>>>> driverStreams =
          transportsSnapshot.docs.map((driverDoc) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
        final driverId = driverDoc.id;

        return FirebaseFirestore.instance
            .collection('transports')
            .doc(driverId)
            .collection('buses')
            .snapshots()
            .map((busesSnapshot) {
          final List<Map<String, dynamic>> combinedBuses = [];

          // Check parent transport status
          final driverStatus = driverData['status']?.toString().toLowerCase();
          if (driverStatus != 'inactive' && driverStatus != 'false') {
            // Add the parent transport document as a bus
            combinedBuses.add({
              'bus_id': driverId,
              'driver_id': driverId,
              'bus': driverData,
              'driver': driverData,
            });
          }

          if (busesSnapshot.docs.isNotEmpty) {
            print(
              "Driver $driverId has ${busesSnapshot.docs.length} buses",
            );
            for (final busDoc in busesSnapshot.docs) {
              final busData = busDoc.data() as Map<String, dynamic>? ?? {};

              // Check subcollection bus status
              final busStatus = busData['status']?.toString().toLowerCase();
              if (busStatus != 'inactive' && busStatus != 'false') {
                print(
                  "  -> Found active bus inside transports/$driverId/buses: ${busDoc.id}",
                );
                print("     Bus Data: $busData");

                combinedBuses.add({
                  'bus_id': busDoc.id,
                  'driver_id': driverId,
                  'bus': busData,
                  'driver': driverData,
                });
              }
            }
          }
          return combinedBuses;
        });
      }).toList();

      return Rx.combineLatestList(driverStreams).map((listOfLists) {
        final flatList = listOfLists.expand((list) => list).toList();
        print("Total Combined Buses emitted to UI: ${flatList.length}");
        return flatList;
      });
    });
  }

  Widget buildBusTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _busSchedulesStream2 ??= _getBusSchedulesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(60),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0F2E5A)),
            ),
          );
        }

        final List<Map<String, dynamic>> allBusSchedules = snapshot.data
                ?.map((item) {
                  final busData = item['bus'] as Map<String, dynamic>;
                  final driverData = item['driver'] as Map<String, dynamic>;

                  final isKsrtc =
                      busData['bus_type']?.toString().toUpperCase() == 'KSRTC';
                  final subType =
                      (busData['bus_sub_type']?.toString().toUpperCase() ??
                          "ORDINARY");
                  final firstStop = busData['first_stop']?.toString() ?? "";
                  final rawTime = busData['departure_time']?.toString() ?? "";
                  String timeMain = rawTime;
                  String timePeriod = "";

                  if (rawTime.toLowerCase().contains("am")) {
                    timeMain = rawTime
                        .replaceAll(RegExp(r'am', caseSensitive: false), '')
                        .trim();
                    timePeriod = "AM";
                  } else if (rawTime.toLowerCase().contains("pm")) {
                    timeMain = rawTime
                        .replaceAll(RegExp(r'pm', caseSensitive: false), '')
                        .trim();
                    timePeriod = "PM";
                  } else if (rawTime.isNotEmpty && rawTime.contains(":")) {
                    final parts = rawTime.split(":");
                    final h = int.tryParse(parts[0]) ?? 0;
                    if (h >= 12) {
                      timeMain = "${h > 12 ? h - 12 : 12}:${parts[1]}";
                      timePeriod = "PM";
                    } else {
                      timeMain = "${h == 0 ? 12 : h}:${parts[1]}";
                      timePeriod = "AM";
                    }
                  }

                  return {
                    "id": item['bus_id'],
                    "driver_id": item['driver_id'],
                    "type": "LIVE",
                    "tags": [isKsrtc ? "KSRTC" : "PRIVATE", subType],
                    "timeMain": timeMain,
                    "timePeriod": timePeriod,
                    "from": busData['start_place']?.toString() ??
                        driverData['main_stand']?.toString() ??
                        "",
                    "to": busData['destination']?.toString() ?? "",
                    "via": firstStop.isNotEmpty ? "Via $firstStop" : "",
                    "stops": [
                      {
                        "name": busData['start_place']?.toString() ??
                            driverData['main_stand']?.toString() ??
                            "Origin",
                        "time": "Departs ${busData['departure_time'] ?? ''}",
                      },
                      {
                        "name":
                            busData['destination']?.toString() ?? "Destination",
                        "status": "Arrives ${busData['arrival_time'] ?? ''}",
                        "statusColor": Colors.green,
                      },
                    ],
                    "frequency": busData['bus_name']?.toString() ?? "",
                    "bus_name": busData['bus_name']?.toString() ?? "",
                    "registration_number":
                        busData['registration_number']?.toString() ??
                            busData['reg_number']?.toString() ??
                            driverData['registration_number']?.toString() ??
                            driverData['reg_number']?.toString() ??
                            "",
                    "driver_name": driverData['username']?.toString() ?? "",
                    "driver_phone": driverData['phone']?.toString() ?? "",
                    "driver_rating": driverData['ratings']?.toString() ?? "0.0",
                    "driver_reviews":
                        driverData['total_reviews']?.toString() ?? "0",
                    "driver_img": driverData['profile_img']?.toString() ?? "",
                    "showMap": true,
                    "showFavorite": false,
                    "isKsrtc": isKsrtc,
                    "district": busData['district']?.toString() ??
                        driverData['district']?.toString(),
                  };
                })
                .whereType<Map<String, dynamic>>()
                .toList() ??
            [];

        final filteredSchedules = allBusSchedules.where((bus) {
          if (selectedBusFilter == "KSRTC" && !bus['isKsrtc']) return false;
          if (selectedBusFilter == "Private Bus" && bus['isKsrtc'])
            return false;

          if (_selectedDistrict != "All Districts" &&
              bus['district'] != _selectedDistrict) return false;

          final fromSearch = _fromBusController.text.trim().toLowerCase();
          final toSearch = _toBusController.text.trim().toLowerCase();

          final matchesFrom = fromSearch.isEmpty ||
              bus['from'].toString().toLowerCase().contains(fromSearch);
          final matchesTo = toSearch.isEmpty ||
              bus['to'].toString().toLowerCase().contains(toSearch);

          final globalSearch = _searchController.text.trim().toLowerCase();
          final matchesGlobal = globalSearch.isEmpty ||
              bus['from'].toString().toLowerCase().contains(globalSearch) ||
              bus['to'].toString().toLowerCase().contains(globalSearch) ||
              bus['frequency'].toString().toLowerCase().contains(
                    globalSearch,
                  ) ||
              bus['tags'].toString().toLowerCase().contains(globalSearch);

          return matchesFrom && matchesTo && matchesGlobal;
        }).toList();

        final currentFrom = _fromBusController.text.trim().toLowerCase();
        final currentTo = _toBusController.text.trim().toLowerCase();
        final isCurrentRouteSaved = currentFrom.isNotEmpty &&
            currentTo.isNotEmpty &&
            _savedRoutes.any(
              (route) =>
                  route['from']!.toLowerCase() == currentFrom &&
                  route['to']!.toLowerCase() == currentTo,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search schedules card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // FROM Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF0F2E5A),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "FROM",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 24,
                                child: TextField(
                                  controller: _fromBusController,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F2E5A),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_fromBusController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _fromBusController.clear();
                              });
                            },
                            child: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // TO Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.navigation,
                          color: Color(0xFFFFB800),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TO",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 24,
                                child: TextField(
                                  controller: _toBusController,
                                  onChanged: (val) => setState(() {}),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F2E5A),
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_toBusController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _toBusController.clear();
                              });
                            },
                            child: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search Schedules & Save buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              toastInfo(
                                "Searching schedules from ${_fromBusController.text} to ${_toBusController.text}...",
                              );
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                _scrollToSchedule,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2E5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Search Schedules",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            final fromText = _fromBusController.text.trim();
                            final toText = _toBusController.text.trim();
                            if (fromText.isEmpty || toText.isEmpty) {
                              toastWarning(
                                "Please fill both FROM and TO fields to save.",
                              );
                              return;
                            }

                            final alreadyExistsIndex = _savedRoutes.indexWhere(
                              (route) =>
                                  route['from']!.toLowerCase() ==
                                      fromText.toLowerCase() &&
                                  route['to']!.toLowerCase() ==
                                      toText.toLowerCase(),
                            );

                            if (alreadyExistsIndex != -1) {
                              // Toggle: unsave
                              setState(() {
                                _savedRoutes.removeAt(alreadyExistsIndex);
                                _routesBox.put('routes', _savedRoutes);
                              });
                              toastSuccess("Route removed from saved list.");
                              return;
                            }

                            setState(() {
                              // Insert at the beginning so it shows first
                              _savedRoutes.insert(0, {
                                "from": fromText,
                                "to": toText,
                              });
                              _routesBox.put('routes', _savedRoutes);
                            });
                            toastSuccess("Saved route: $fromText ⇄ $toText");
                          },
                          icon: Icon(
                            isCurrentRouteSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isCurrentRouteSaved
                                ? const Color(0xFFFFB800)
                                : const Color(0xFF0F2E5A),
                          ),
                          tooltip: isCurrentRouteSaved
                              ? "Remove saved route"
                              : "Save current route",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Saved Routes Section
            if (_savedRoutes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark,
                      size: 14,
                      color: Color(0xFF0F2E5A),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Saved Routes",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _savedRoutes[index];
                    final routeText = "${route['from']} ⇄ ${route['to']}";
                    return Container(
                      margin: const EdgeInsets.only(right: 12, top: 4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _fromBusController.text = route['from']!;
                                _toBusController.text = route['to']!;
                              });
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                _scrollToSchedule,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F2E5A),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            child: Text(
                              routeText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _savedRoutes.removeAt(index);
                                  _routesBox.put('routes', _savedRoutes);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 8,
                                  color: Color(0xFF0F2E5A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            // District Filter Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Color(0xFF0F2E5A),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "District:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _districtLoading
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                value: _selectedDistrict,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 24,
                                  color: Color(0xFF475569),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF0F2E5A),
                                  fontWeight: FontWeight.w600,
                                ),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedDistrict = newValue;
                                      GetStorage().write(
                                        'selected_district',
                                        newValue,
                                      );
                                    });
                                  }
                                },
                                items: () {
                                  final List<String> districts = [
                                    "All Districts",
                                    "Kozhikode",
                                    "Kannur",
                                    "Malappuram",
                                    "Wayanad",
                                    "Palakkad",
                                    "Thrissur",
                                    "Ernakulam",
                                    "Kottayam",
                                    "Alappuzha",
                                    "Pathanamthitta",
                                    "Kollam",
                                    "Thiruvananthapuram",
                                    "Idukki",
                                    "Kasaragod",
                                  ];
                                  if (!districts.contains(_selectedDistrict)) {
                                    districts.add(_selectedDistrict);
                                  }
                                  return districts
                                      .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList();
                                }(),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildBusFilterChip("All Types"),
                  const SizedBox(width: 8),
                  _buildBusFilterChip("KSRTC"),
                  const SizedBox(width: 8),
                  _buildBusFilterChip("Private Bus"),
                ],
              ),
            ),

            // Section Title
            Padding(
              key: _scheduleKey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upcoming Schedules",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Live status for your route",
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // List of Cards
            if (_selectedDistrict == "All Districts")
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please select a district to view available bus routes.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (filteredSchedules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    "No bus schedules found for the selected district.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...filteredSchedules
                  .map((bus) => _buildBusScheduleCard(bus))
                  .toList(),
          ],
        );
      },
    );
  }

  // ─── Local Ads Tab ──────────────────────────────────────────────────────────
  Widget buildLocalAdsTab(List<dynamic> allServices) {
    if (allServices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.campaign_outlined, size: 48, color: Color(0xFFCBD5E1)),
              SizedBox(height: 12),
              Text(
                "No advertisements yet",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 13,
                      color: Color(0xFFD97706),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "SPONSORED",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Local Advertisements",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    Text(
                      "Discover deals from local businesses",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Category Filter Chips ──────────────────────────────────────────
        Builder(
          builder: (context) {
            // Derive unique categories from the live data
            final categories = <String>['All'];
            for (final doc in allServices) {
              final cat =
                  ((doc.data() as Map<String, dynamic>)['category'] ?? '')
                      .toString()
                      .trim();
              if (cat.isNotEmpty && !categories.contains(cat)) {
                categories.add(cat);
              }
            }

            // Clamp selection if the category no longer exists
            if (!categories.contains(_selectedAdCategory)) {
              _selectedAdCategory = 'All';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scrollable chip row
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedAdCategory == cat;

                      final Map<String, Color> catColors = {
                        'All': const Color(0xFF0F2E5A),
                        'Exterior': const Color(0xFF0F2E5A),
                        'Interior': const Color(0xFF7C3AED),
                        'Vehicle': const Color(0xFF059669),
                        'Pet': const Color(0xFFDB2777),
                        'Home': const Color(0xFFEA580C),
                      };
                      final Color chipColor =
                          catColors[cat] ?? const Color(0xFF0F2E5A);

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedAdCategory = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? chipColor
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? chipColor
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Filtered Ad Cards
              ],
            ); // closes outer Column
          },
        ), // closes outer Builder (category derivation + chips)
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBusFilterChip(String type) {
    final isSelected = selectedBusFilter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBusFilter = type;
          _clearBusSearch();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F2E5A)
              : const Color(0xFFE2E8F0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0F2E5A),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBusScheduleCard(Map<String, dynamic> bus) {
    final isFavorite = _favoriteBuses.contains(bus['id']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Tags + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: (bus['tags'] as List<String>).map((tag) {
                  final isLive = tag == "LIVE";
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFF0F2E5A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  );
                }).toList(),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bus['timeMain'] ?? bus['time'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                      height: 1.0,
                    ),
                  ),
                  if (bus['timePeriod'] != null &&
                      bus['timePeriod'].toString().isNotEmpty)
                    Text(
                      bus['timePeriod'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Route title
          Text(
            "${bus['from']} to ${bus['to']}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
          Text(
            bus['via'],
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          // Stop details (if present)
          if (bus['stops'] != null) ...[
            Column(
              children: (bus['stops'] as List<dynamic>).map<Widget>((stop) {
                final isFirst = (bus['stops'] as List).indexOf(stop) == 0;
                final status = stop['status'] as String?;
                final statusColor = stop['statusColor'] as Color?;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot and line indicator
                    Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst
                                ? const Color(0xFF0F2E5A)
                                : const Color(0xFFFFB800),
                          ),
                        ),
                        if (isFirst)
                          Container(
                            width: 2,
                            height: 16,
                            color: const Color(0xFFCBD5E1),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stop['name'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            status ?? stop['time'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor ?? const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          // Info Box (if present)
          if (bus['infoBox'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF0F2E5A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bus['infoBox']['title'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                  ),
                  Text(
                    bus['infoBox']['subtitle'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          ),
          // Footer action row
          // Driver Details (Hidden per user request)
          // Footer action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "${bus['bus_name']} ${bus['registration_number'] != null && bus['registration_number'].isNotEmpty ? '• ${bus['registration_number']}' : ''}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Hidden map and details buttons
            ],
          ),
        ],
      ),
    );
  }

  void _showBusDetailsSheet(Map<String, dynamic> bus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${bus['from']} to ${bus['to']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                bus['via'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                "Schedule Information:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
              const SizedBox(height: 8),
              Text("Departure Time: ${bus['time']}"),
              const SizedBox(height: 4),
              Text("Frequency: ${bus['frequency']}"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 35);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dashLength = 5.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    double distance = 0.0;
    bool draw = true;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        double length = draw ? dashLength : gap;
        if (distance + length > measurePath.length) {
          length = measurePath.length - distance;
        }
        if (draw) {
          dashPath.addPath(
            measurePath.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

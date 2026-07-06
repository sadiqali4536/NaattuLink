import 'dart:ui';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:swiftclean_project/MVVM/utils/Config/Toast.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Exterior_Bookingpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Home_Booking_Page.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Interior_Booking_page.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/pet_Bookingpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/vehicle_booking_page.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/service_functions/ServiceCardwith map.dart';
import 'package:swiftclean_project/MVVM/utils/widget/button/Scrollable/scrollable_horizontal_buttons.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => HomepageState();
}

// Public so user_Dashboard can call resetToForYou() via GlobalKey
class HomepageState extends State<Homepage> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 0);

  int? _safeRating(dynamic rating) {
    if (rating is num) return rating.toInt();
    return null;
  }

  String? username;
  int selectedCategoryIndex = 0;
  int activeBannerIndex = 0;
  String searchQuery = "";
  double _minRating = 0;
  String _sortBy = 'None';
  late TextEditingController _searchController;
  Stream<QuerySnapshot>? _servicesStream;

  // Bus tab state variables
  String selectedBusFilter = "All Types";
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
    "Emergency"
  ];

  String get selectedCategory => categoryList[selectedCategoryIndex];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fromBusController = TextEditingController(text: "Calicut");
    _toBusController = TextEditingController(text: "Thalayad");
    loadUsername();
    _servicesStream =
        FirebaseFirestore.instance.collection('services').snapshots();

    // Initialize saved routes from Hive
    _routesBox = Hive.box('saved_routes_box');
    if (_routesBox.get('routes') == null) {
      // Seed with default routes if empty
      _routesBox.put('routes', [
        {"from": "Calicut", "to": "Thalayad"},
        {"from": "Kozhikode", "to": "Wayanad"},
        {"from": "Balussery", "to": "Thalayad"},
      ]);
    }
    _loadSavedRoutes();
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          username = data['username'];
        });
      }
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
    setState(() {
      selectedCategoryIndex = 0;
      _selectedAdCategory = 'All';
      _clearBusSearch();
    });
    if (_homeScrollController.hasClients) {
      _homeScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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
              "Emergency"
            ];
            for (var doc in allServices) {
              final data = doc.data() as Map<String, dynamic>;
              final cat = (data['category'] ?? '').toString().trim();
              if (cat.isNotEmpty) {
                String norm = cat.toLowerCase();
                bool isDuplicate = false;
                if (norm == 'exterior' || norm == 'workers')
                  isDuplicate = true;
                else if (norm == 'interior' || norm == 'bus')
                  isDuplicate = true;
                else if (norm == 'vehicle' || norm == 'local ads')
                  isDuplicate = true;
                else if (norm == 'all' || norm == 'for you')
                  isDuplicate = true;
                else if (norm == 'emergency')
                  isDuplicate = true;
                else if (norm == 'pet' || norm == 'home') isDuplicate = true;

                for (var existing in currentCategoryList) {
                  if (existing.trim().toLowerCase() == norm) {
                    isDuplicate = true;
                  }
                }

                if (!isDuplicate) {
                  currentCategoryList.add(cat);
                }
              }
            }

            // Clamp the selected category index
            if (selectedCategoryIndex >= currentCategoryList.length) {
              selectedCategoryIndex = 0;
            }
            final selected = currentCategoryList[selectedCategoryIndex];

            // Map to dbSelected category name
            String dbSelected = selected;
            if (selected == "For You")
              dbSelected = "All";
            else if (selected == "Workers")
              dbSelected = "Exterior";
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

              final matchesCategory =
                  dbSelected == "All" || category == dbSelected;
              final matchesSearch = name.contains(searchQuery.toLowerCase());
              final matchesRating = rating >= _minRating;

              return matchesCategory && matchesSearch && matchesRating;
            }).toList();

            if (_sortBy == 'A-Z') {
              filtered.sort((a, b) => (a['service_name'] ?? '')
                  .toString()
                  .compareTo((b['service_name'] ?? '').toString()));
            } else if (_sortBy == 'Rating') {
              filtered.sort(
                  (a, b) => (b['rating'] ?? 0).compareTo((a['rating'] ?? 0)));
            }

            // Render appropriate content in the services grid area
            Widget servicesContent;
            if (snapshot.connectionState == ConnectionState.waiting) {
              servicesContent = ShimmerEffect(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    mainAxisExtent: 155,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) {
                    return const SkeletonPlaceholder(
                        width: 90, height: 140, borderRadius: 16);
                  },
                ),
              );
            } else if (snapshot.hasError) {
              servicesContent = SizedBox(
                height: 150,
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else if (filtered.isEmpty) {
              servicesContent = const SizedBox(
                height: 150,
                child: Center(child: Text('No services found')),
              );
            } else {
              servicesContent = GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  mainAxisExtent: 155,
                  childAspectRatio: 0.8,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  return GestureDetector(
                    onTap: () {
                      final category = filtered[index]['category'];
                      if (category == 'Exterior') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ExteriorBookingpage(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      } else if (category == 'Interior') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => InteriorBookingPage(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      } else if (category == 'Vehicle') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => VehicleBookingPage(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      } else if (category == 'Pet') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PetCleaning(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      } else if (category == 'Home') {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HomeBookingPage(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      } else {
                        // Fallback booking page for any other dynamic/emergency category
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ExteriorBookingpage(
                                      category: filtered[index]['category'],
                                      serviceName: filtered[index]
                                          ['service_name'],
                                      rating: _safeRating(
                                          filtered[index]['rating']),
                                      originalPrice: filtered[index]
                                          ['original_price'],
                                      discount: filtered[index]['discount'],
                                      image: filtered[index]['image'],
                                      discountPrice: filtered[index]['price'],
                                      serviceType: filtered[index]
                                          ['service_type'],
                                    )));
                      }
                    },
                    child: ServiceCard(
                      image: filtered[index]['image'] ?? '',
                      rating: (filtered[index]['rating'] ?? 0).toDouble(),
                      title: (filtered[index]['service_name'] ?? '')
                          .toString()
                          .toUpperCase(),
                    ),
                  );
                },
              );
            }

            return SingleChildScrollView(
              controller: _homeScrollController,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 310),
                          if (_searchController.text.isEmpty) ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const CarouselSkeleton(
                                      key: ValueKey('carousel_loading'))
                                  : Column(
                                      key: const ValueKey('carousel_loaded'),
                                      children: [
                                        CarouselSlider(
                                          items: [
                                            buildPromoCard(
                                                "assets/image/add_image.png",
                                                "Grand Kerala Festival\nUp to 60% Off"),
                                            buildPromoCard(
                                                "assets/image/add_image.png",
                                                "20% OFF Interior Cleaning"),
                                          ],
                                          options: CarouselOptions(
                                              autoPlay: true,
                                              enlargeCenterPage: false,
                                              aspectRatio: 2.1,
                                              viewportFraction: 1,
                                              onPageChanged: (index, reason) {
                                                setState(() {
                                                  activeBannerIndex = index;
                                                });
                                              }),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(2, (index) {
                                            return Container(
                                              width: activeBannerIndex == index
                                                  ? 15
                                                  : 6,
                                              height: 6,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 3),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                color: activeBannerIndex ==
                                                        index
                                                    ? const Color(0xFFFFB800)
                                                    : Colors.grey[300],
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                          const SizedBox(height: 20),
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
                                  : buildForYouDashboard(filtered,
                                      key: const ValueKey('loaded_dashboard')),
                            )
                          else if (selectedCategory == "Workers" &&
                              _searchController.text.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const ServiceCardListSkeleton()
                                  : buildWorkersTab(filtered),
                            )
                          else if (selectedCategory == "Bus" &&
                              _searchController.text.isEmpty)
                            buildBusTab()
                          else if (selectedCategory == "Local Ads" &&
                              _searchController.text.isEmpty)
                            buildLocalAdsTab(allServices)
                          else
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: servicesContent,
                            ),
                          const SizedBox(height: 130), // bottom bar spacing
                        ],
                      ),
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F2E5A), // Premium navy color
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(35),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: username == null
                                    ? const HeaderSkeleton(
                                        key: ValueKey('header_loading'))
                                    : Padding(
                                        key: const ValueKey('header_loaded'),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 1.5),
                                              ),
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundColor: const Color(
                                                    0xFFFFB800), // Gold accent
                                                child: Text(
                                                  username != null &&
                                                          username!.isNotEmpty
                                                      ? username![0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                  Obx(() {
                                                    final loc =
                                                        LocationController
                                                            .to
                                                            .currentLocation
                                                            .value;
                                                    if (loc.isEmpty)
                                                      return const SizedBox
                                                          .shrink();
                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .location_on_outlined,
                                                            color:
                                                                Colors.white70,
                                                            size: 12),
                                                        const SizedBox(
                                                            width: 4),
                                                        Flexible(
                                                          child: Text(
                                                            loc,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 11,
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
                                                            color:
                                                                Colors.white70,
                                                            size: 12),
                                                      ],
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                            Stack(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .notifications_none_outlined,
                                                      color: Colors.white),
                                                  onPressed: () {},
                                                ),
                                                if (notificationCount > 0)
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 8,
                                                        minHeight: 8,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.menu,
                                                  color: Colors.white),
                                              onPressed: () {},
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              // Search field with integrated filter and mic buttons inside
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _searchController,
                                    onChanged: (value) =>
                                        setState(() => searchQuery = value),
                                    decoration: InputDecoration(
                                      hintText:
                                          "Search for workers, services...",
                                      hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13),
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
                                            onTap: () => showModalBottomSheet(
                                              context: context,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            20)),
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
                                            padding:
                                                EdgeInsets.only(right: 14.0),
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
                                              vertical: 14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? const CategoryRowSkeleton(
                                        key: ValueKey('category_loading'))
                                    : ScrollableHorizontalButtons(
                                        key: const ValueKey('category_loaded'),
                                        categories: currentCategoryList,
                                        selectedIndex: selectedCategoryIndex,
                                        onSelected: (index) {
                                          setState(() {
                                            selectedCategoryIndex = index;
                                            _clearBusSearch();
                                          });
                                        },
                                        isDark: true,
                                      ),
                              ),
                            ],
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

  Widget buildPromoCard(String imagePath, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
            // Semi-transparent gradient overlay to ensure text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Celebrate with local favorites and deals",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFB800), // Gold/Yellow Explore button
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Explore Now",
                      style: TextStyle(
                        color: Color(0xFF0F2E5A),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
  }

  Widget buildFilterSheet() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filter Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
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
    final expertServices = services.toList();
    expertServices.sort((a, b) => ((b.data()
                as Map<String, dynamic>)['rating'] ??
            0)
        .toDouble()
        .compareTo(
            ((a.data() as Map<String, dynamic>)['rating'] ?? 0).toDouble()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  int workersIndex = categoryList.indexOf("Workers");
                  if (workersIndex != -1) {
                    setState(() {
                      selectedCategoryIndex = workersIndex;
                      _clearBusSearch();
                    });
                  }
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 13,
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
          height: 180,
          child: expertServices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(child: Text("No expert services available")),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount:
                      expertServices.length > 5 ? 5 : expertServices.length,
                  itemBuilder: (context, index) {
                    final doc = expertServices[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final serviceName = data['service_name'] ?? 'Service';
                    final rating = (data['rating'] ?? 0.0).toDouble();
                    final image = data['image'] ?? '';
                    final price =
                        data['price'] ?? data['original_price'] ?? '189';

                    return GestureDetector(
                      onTap: () {
                        final category = data['category'];
                        if (category == 'Exterior') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ExteriorBookingpage(
                                        category: data['category'],
                                        serviceName: data['service_name'],
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: data['image'],
                                        discountPrice: data['price'],
                                        serviceType: data['service_type'],
                                      )));
                        } else if (category == 'Interior') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => InteriorBookingPage(
                                        category: data['category'],
                                        serviceName: data['service_name'],
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: data['image'],
                                        discountPrice: data['price'],
                                        serviceType: data['service_type'],
                                      )));
                        } else if (category == 'Vehicle') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VehicleBookingPage(
                                        category: data['category'],
                                        serviceName: data['service_name'],
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: data['image'],
                                        discountPrice: data['price'],
                                        serviceType: data['service_type'],
                                      )));
                        } else if (category == 'Pet') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PetCleaning(
                                        category: data['category'],
                                        serviceName: data['service_name'],
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: data['image'],
                                        discountPrice: data['price'],
                                        serviceType: data['service_type'],
                                      )));
                        } else if (category == 'Home') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HomeBookingPage(
                                        category: data['category'],
                                        serviceName: data['service_name'],
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: data['image'],
                                        discountPrice: data['price'],
                                        serviceType: data['service_type'],
                                      )));
                        }
                      },
                      child: Container(
                        width: 140,
                        margin:
                            const EdgeInsets.only(right: 14, bottom: 6, top: 4),
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
                                      top: Radius.circular(20)),
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
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(
                                                Icons.image_outlined,
                                                size: 24,
                                                color: Colors.grey),
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
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(
                                                Icons.image_outlined,
                                                size: 24,
                                                color: Colors.grey),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB800),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            size: 11, color: Color(0xFF0F2E5A)),
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
                                  horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
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
                  },
                ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text(
            "City Essentials",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2E5A),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildEssentialItem(
                      icon: Icons.local_taxi_outlined,
                      label: "Auto/Taxi",
                      bgColor: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF4F46E5),
                      onTap: () {
                        int busIndex = categoryList.indexOf("Bus");
                        if (busIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = busIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.local_hospital_outlined,
                      label: "Clinics",
                      bgColor: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        int emgIndex = categoryList.indexOf("Emergency");
                        if (emgIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = emgIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.phone_in_talk_outlined,
                      label: "Helpline",
                      bgColor: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        int emgIndex = categoryList.indexOf("Emergency");
                        if (emgIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = emgIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.school_outlined,
                      label: "Tuition",
                      bgColor: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      onTap: () {
                        setState(() {
                          searchQuery = "Tuition";
                          _searchController.text = "Tuition";
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildEssentialItem(
                      icon: Icons.restaurant_outlined,
                      label: "Food",
                      bgColor: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        setState(() {
                          searchQuery = "Food";
                          _searchController.text = "Food";
                        });
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.computer_outlined,
                      label: "Internet Cafe",
                      bgColor: const Color(0xFFF0F9FF),
                      iconColor: const Color(0xFF0EA5E9),
                      onTap: () {
                        int adsIndex = categoryList.indexOf("Local Ads");
                        if (adsIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = adsIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.local_shipping_outlined,
                      label: "Pickup",
                      bgColor: const Color(0xFFFDF2F8),
                      iconColor: const Color(0xFFDB2777),
                      onTap: () {
                        int adsIndex = categoryList.indexOf("Local Ads");
                        if (adsIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = adsIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                    buildEssentialItem(
                      icon: Icons.work_outline,
                      label: "Jobs",
                      bgColor: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      onTap: () {
                        int workersIndex = categoryList.indexOf("Workers");
                        if (workersIndex != -1) {
                          setState(() {
                            selectedCategoryIndex = workersIndex;
                            _clearBusSearch();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Top Deals",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: buildMarketplaceCard(
                  image: "assets/image/add_image.png",
                  title: "Premium Calicut Halwa",
                  price: 320,
                  originalPrice: 600,
                  discountBadge: "50% OFF",
                  discountColor: Colors.red,
                  bottomInfo: "1h Free Delivery",
                  bottomInfoColor: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: buildMarketplaceCard(
                  image: "assets/image/add_image.png",
                  title: "Bamboo Lamp Shade",
                  price: 850,
                  originalPrice: 1300,
                  discountBadge: "BEST DEAL",
                  discountColor: const Color(0xFFFFB800),
                  bottomInfo: "Limited Stock",
                  bottomInfoColor: Colors.orange,
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
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: const [
              Icon(Icons.newspaper, color: Color(0xFF0F2E5A), size: 20),
              SizedBox(width: 6),
              Text(
                "Community News",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E5A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                buildNewsItem(
                  image: "assets/image/add_image.png",
                  title: "New Solar Park project announced for Thalayad area.",
                  timeAndSource: "2 hours ago • Local Council",
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.black12, height: 1),
                ),
                buildNewsItem(
                  image: "assets/image/add_image.png",
                  title: "Annual Community Boat Race registration now open.",
                  timeAndSource: "4 hours ago • Sports Club",
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: const Color(0xFFCBD5E1),
              strokeWidth: 1.5,
              gap: 6,
              dashLength: 6,
              borderRadius: 20,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    "Why book through Thalayadukkar?",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildTrustBadge(
                        icon: Icons.verified_user_outlined,
                        title: "Background Checked",
                        subtitle: "Safe & secure",
                      ),
                      buildTrustBadge(
                        icon: Icons.payments_outlined,
                        title: "Transparent Pricing",
                        subtitle: "Upfront quotes",
                      ),
                      buildTrustBadge(
                        icon: Icons.flash_on_outlined,
                        title: "Quick Response",
                        subtitle: "Instant booking",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEssentialItem({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
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
              ),
              child: Icon(icon, color: iconColor, size: 22),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                          child: const Icon(Icons.image_outlined,
                              size: 28, color: Colors.grey),
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
                          child: const Icon(Icons.image_outlined,
                              size: 28, color: Colors.grey),
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: Colors.grey),
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
                    child: const Icon(Icons.image_outlined,
                        size: 20, color: Colors.grey),
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
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
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
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget buildWorkersTab(List<dynamic> filtered) {
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 14.0,
            mainAxisExtent: 245,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final service = filtered[index];
            final name = service['service_name'] ?? '';
            final category = service['category'] ?? '';
            final rating = (service['rating'] ?? 0.0).toDouble();
            final price = service['price'] ?? 0;
            final image = service['image'] ?? '';

            return Container(
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
                    child: image.isNotEmpty
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
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            height: 110,
                            width: double.infinity,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  Expanded(
                    child: Padding(
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
                              const Icon(Icons.star,
                                  color: Color(0xFFFFB800), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Starts from ₹$price",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              if (category == 'Interior') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => InteriorBookingPage(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              } else if (category == 'Exterior') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ExteriorBookingpage(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              } else if (category == 'Vehicle') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => VehicleBookingPage(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              } else if (category == 'Pet') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PetCleaning(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              } else if (category == 'Home') {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => HomeBookingPage(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ExteriorBookingpage(
                                              category: category,
                                              serviceName: name,
                                              rating: rating.toInt(),
                                              originalPrice:
                                                  service['original_price'],
                                              discount: service['discount'],
                                              image: image,
                                              discountPrice: price,
                                              serviceType:
                                                  service['service_type'],
                                            )));
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "Book Now",
                                  style: TextStyle(
                                    color: Color(0xFF0F2E5A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildBusTab() {
    final List<Map<String, dynamic>> allBusSchedules = [
      {
        "id": "bus_1",
        "type": "LIVE",
        "tags": ["LIVE", "LIMITED STOP"],
        "time": "08:30 AM",
        "from": "Calicut",
        "to": "Thalayad",
        "via": "Via Pavangad, Atholi",
        "stops": [
          {"name": "Calicut Stand", "time": "Arrives 09:15 AM"},
          {
            "name": "Thalayad Junction",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Every 15 mins",
        "showMap": true,
        "isKsrtc": false,
      },
      {
        "id": "bus_ksrtc_1",
        "type": "KSRTC",
        "tags": ["KSRTC ORDINARY"],
        "time": "06:30 AM",
        "from": "Calicut",
        "to": "Thalayad",
        "via": "Via Pavangad, Atholi, Balussery",
        "stops": [
          {"name": "Calicut Stand", "time": "06:30 AM"},
          {"name": "Balussery Stand", "time": "07:20 AM"},
          {
            "name": "Thalayad Junction",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      },
      {
        "id": "bus_ksrtc_2",
        "type": "KSRTC",
        "tags": ["K-SWIFT SF"],
        "time": "07:45 AM",
        "from": "Kozhikode",
        "to": "Wayanad",
        "via": "Via Balussery, Thalayad, Thamarassery",
        "stops": [
          {"name": "Kozhikode KSRTC", "time": "07:45 AM"},
          {"name": "Balussery", "time": "08:30 AM"},
          {
            "name": "Thalayad Entry",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "showFavorite": true,
        "isKsrtc": true,
      },
      {
        "id": "bus_2",
        "type": "KSRTC",
        "tags": ["KSRTC FP"],
        "time": "09:10 AM",
        "from": "Kozhikode",
        "to": "Wayanad",
        "via": "Stop at Thalayad Road",
        "stops": [
          {"name": "Kozhikode KSRTC", "time": "Duration 90m"},
          {
            "name": "Thalayad Entry",
            "status": "Delayed 5m",
            "statusColor": const Color(0xFFF59E0B)
          },
        ],
        "frequency": "Daily Service",
        "showFavorite": true,
        "isKsrtc": true,
      },
      {
        "id": "bus_3",
        "type": "Private",
        "tags": ["ORDINARY"],
        "time": "09:45 AM",
        "from": "Balussery",
        "to": "Thalayad",
        "via": "Via Panangad",
        "infoBox": {
          "title": "Arriving in 12 mins",
          "subtitle": "FREQUENCY\n30 min gaps"
        },
        "frequency": "Tracked Live",
        "isKsrtc": false,
      },
      {
        "id": "bus_ksrtc_3",
        "type": "KSRTC",
        "tags": ["KSRTC LS"],
        "time": "10:30 AM",
        "from": "Calicut",
        "to": "Thalayad",
        "via": "Via Atholi, Balussery",
        "stops": [
          {"name": "Calicut Stand", "time": "10:30 AM"},
          {
            "name": "Thalayad Junction",
            "status": "Delayed 10m",
            "statusColor": const Color(0xFFF59E0B)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      },
      {
        "id": "bus_ksrtc_4",
        "type": "KSRTC",
        "tags": ["KSRTC ORDINARY"],
        "time": "12:15 PM",
        "from": "Balussery",
        "to": "Thalayad",
        "via": "Via Panangad, Unnikulam",
        "stops": [
          {"name": "Balussery Stand", "time": "12:15 PM"},
          {
            "name": "Thalayad Junction",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      },
      {
        "id": "bus_ksrtc_5",
        "type": "KSRTC",
        "tags": ["K-SWIFT DELUXE"],
        "time": "02:30 PM",
        "from": "Kozhikode",
        "to": "Wayanad",
        "via": "Via Balussery, Thalayad, Vythiri",
        "stops": [
          {"name": "Kozhikode KSRTC", "time": "02:30 PM"},
          {
            "name": "Thalayad Entry",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      },
      {
        "id": "bus_ksrtc_6",
        "type": "KSRTC",
        "tags": ["KSRTC ORDINARY"],
        "time": "05:45 PM",
        "from": "Calicut",
        "to": "Thalayad",
        "via": "Via Pavangad, Atholi, Balussery",
        "stops": [
          {"name": "Calicut Stand", "time": "05:45 PM"},
          {"name": "Balussery Stand", "time": "06:40 PM"},
          {
            "name": "Thalayad Junction",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      },
      {
        "id": "bus_ksrtc_7",
        "type": "KSRTC",
        "tags": ["KSRTC SF"],
        "time": "08:15 PM",
        "from": "Kozhikode",
        "to": "Wayanad",
        "via": "Via Balussery, Thalayad",
        "stops": [
          {"name": "Kozhikode KSRTC", "time": "08:15 PM"},
          {
            "name": "Thalayad Entry",
            "status": "On Time",
            "statusColor": const Color(0xFF10B981)
          },
        ],
        "frequency": "Daily Service",
        "isKsrtc": true,
      }
    ];

    final filteredSchedules = allBusSchedules.where((bus) {
      if (selectedBusFilter == "KSRTC" && !bus['isKsrtc']) return false;
      if (selectedBusFilter == "Private" && bus['isKsrtc']) return false;

      final fromSearch = _fromBusController.text.trim().toLowerCase();
      final toSearch = _toBusController.text.trim().toLowerCase();

      final matchesFrom = fromSearch.isEmpty ||
          bus['from'].toString().toLowerCase().contains(fromSearch);
      final matchesTo = toSearch.isEmpty ||
          bus['to'].toString().toLowerCase().contains(toSearch);

      return matchesFrom && matchesTo;
    }).toList();

    final currentFrom = _fromBusController.text.trim().toLowerCase();
    final currentTo = _toBusController.text.trim().toLowerCase();
    final isCurrentRouteSaved = currentFrom.isNotEmpty &&
        currentTo.isNotEmpty &&
        _savedRoutes.any((route) =>
            route['from']!.toLowerCase() == currentFrom &&
            route['to']!.toLowerCase() == currentTo);

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF0F2E5A), size: 18),
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
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 24,
                            child: TextField(
                              controller: _fromBusController,
                              onChanged: (val) => setState(() {}),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F2E5A)),
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
                        child: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // TO Input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation,
                        color: Color(0xFFFFB800), size: 18),
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
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 24,
                            child: TextField(
                              controller: _toBusController,
                              onChanged: (val) => setState(() {}),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F2E5A)),
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
                        child: const Icon(Icons.clear,
                            color: Colors.grey, size: 18),
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
                              "Searching schedules from ${_fromBusController.text} to ${_toBusController.text}...");
                          Future.delayed(
                            const Duration(milliseconds: 100),
                            _scrollToSchedule,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2E5A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Search Schedules",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
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
                              "Please fill both FROM and TO fields to save.");
                          return;
                        }

                        final alreadyExistsIndex = _savedRoutes.indexWhere(
                            (route) =>
                                route['from']!.toLowerCase() ==
                                    fromText.toLowerCase() &&
                                route['to']!.toLowerCase() ==
                                    toText.toLowerCase());

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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.bookmark, size: 14, color: Color(0xFF0F2E5A)),
                const SizedBox(width: 4),
                const Text(
                  "Saved Routes",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A)),
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
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Text(
                          routeText,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
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
                            child: const Icon(Icons.close,
                                size: 8, color: Color(0xFF0F2E5A)),
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

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _buildBusFilterChip("All Types"),
              const SizedBox(width: 8),
              _buildBusFilterChip("KSRTC"),
              const SizedBox(width: 8),
              _buildBusFilterChip("Private"),
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
                    color: Color(0xFF0F2E5A)),
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
        if (filteredSchedules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                "No bus schedules found for this route.",
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
                    fontWeight: FontWeight.w500),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 13, color: Color(0xFFD97706)),
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
        Builder(builder: (context) {
          // Derive unique categories from the live data
          final categories = <String>['All'];
          for (final doc in allServices) {
            final cat = ((doc.data() as Map<String, dynamic>)['category'] ?? '')
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
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? chipColor : const Color(0xFFF1F5F9),
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
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Filtered Ad Cards
              Builder(builder: (context) {
                final filtered = _selectedAdCategory == 'All'
                    ? allServices
                    : allServices.where((doc) {
                        final cat =
                            ((doc.data() as Map<String, dynamic>)['category'] ??
                                    '')
                                .toString();
                        return cat == _selectedAdCategory;
                      }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 40, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 10),
                          Text(
                            'No ads in "$_selectedAdCategory"',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String name = data['service_name'] ?? 'Advertisement';
                    final String image = data['image'] ?? '';
                    final String category = data['category'] ?? '';
                    final double rating = (data['rating'] ?? 0).toDouble();
                    final String price = data['price']?.toString() ??
                        data['original_price']?.toString() ??
                        '';
                    final String originalPrice =
                        data['original_price']?.toString() ?? '';
                    final String discount = data['discount']?.toString() ?? '';
                    final String serviceType =
                        data['service_type']?.toString() ?? '';

                    // Category badge colour
                    final Map<String, Color> catColors = {
                      'Exterior': const Color(0xFF0F2E5A),
                      'Interior': const Color(0xFF7C3AED),
                      'Vehicle': const Color(0xFF059669),
                      'Pet': const Color(0xFFDB2777),
                      'Home': const Color(0xFFEA580C),
                    };
                    final Color badgeColor =
                        catColors[category] ?? const Color(0xFF0F2E5A);

                    return GestureDetector(
                      onTap: () {
                        if (category == 'Exterior') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ExteriorBookingpage(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        } else if (category == 'Interior') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => InteriorBookingPage(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        } else if (category == 'Vehicle') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VehicleBookingPage(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        } else if (category == 'Pet') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PetCleaning(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        } else if (category == 'Home') {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HomeBookingPage(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ExteriorBookingpage(
                                        category: category,
                                        serviceName: name,
                                        rating: _safeRating(data['rating']),
                                        originalPrice: data['original_price'],
                                        discount: data['discount'],
                                        image: image,
                                        discountPrice: data['price'],
                                        serviceType: serviceType,
                                      )));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  child: image.startsWith('http')
                                      ? Image.network(
                                          image,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            height: 180,
                                            color: const Color(0xFFF1F5F9),
                                            child: const Center(
                                              child: Icon(
                                                  Icons.campaign_outlined,
                                                  size: 48,
                                                  color: Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          height: 180,
                                          color: const Color(0xFFF1F5F9),
                                          child: const Center(
                                            child: Icon(Icons.campaign_outlined,
                                                size: 48,
                                                color: Color(0xFFCBD5E1)),
                                          ),
                                        ),
                                ),
                                // Gradient overlay
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Color(0xCC0F2E5A),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Category badge
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category.isNotEmpty ? category : 'Ad',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                // Rating badge
                                if (rating > 0)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB800),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 11,
                                              color: Color(0xFF0F2E5A)),
                                          const SizedBox(width: 3),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F2E5A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Title overlay on image bottom
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom info row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (price.isNotEmpty)
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹$price',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F2E5A),
                                                ),
                                              ),
                                              if (originalPrice.isNotEmpty &&
                                                  originalPrice != price) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  '₹$originalPrice',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                              if (discount.isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDCFCE7),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    '$discount% OFF',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF16A34A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        if (serviceType.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              serviceType,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F2E5A),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "View Deal",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ); // closes GestureDetector (each ad card)
                  }).toList(), // closes filtered.map → Column children
                ); // closes inner Column (filtered cards)
              }), // closes inner Builder (filtered card list)
            ], // closes outer Column children (chips + filtered cards)
          ); // closes outer Column
        }), // closes outer Builder (category derivation + chips)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Text(
                bus['time'],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A)),
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
                color: Color(0xFF0F2E5A)),
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
                                color: Color(0xFF334155)),
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
                  const Icon(Icons.directions_bus,
                      color: Color(0xFF0F2E5A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bus['infoBox']['title'],
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A)),
                    ),
                  ),
                  Text(
                    bus['infoBox']['subtitle'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
          // Footer action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus['frequency'],
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  if (bus['showMap'] == true) ...[
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Showing live bus route on map...")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.map,
                            color: Color(0xFF0F2E5A), size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (bus['showFavorite'] == true) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFavorite) {
                            _favoriteBuses.remove(bus['id']);
                          } else {
                            _favoriteBuses.add(bus['id']);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color:
                              isFavorite ? Colors.red : const Color(0xFF0F2E5A),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () {
                      _showBusDetailsSheet(bus);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2E5A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Details",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
                    color: Color(0xFF0F2E5A)),
              ),
              const SizedBox(height: 6),
              Text(bus['via'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
              const Text("Schedule Information:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0F2E5A))),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Close",
                      style: TextStyle(color: Colors.white)),
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

import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Exterior_Bookingpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Home_Booking_Page.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/Interior_Booking_page.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/pet_Bookingpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Booking_page/vehicle_booking_page.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/service_functions/ServiceCardwith map.dart';
import 'package:swiftclean_project/MVVM/utils/widget/button/Scrollable/scrollable_horizontal_buttons.dart';
import 'package:swiftclean_project/MVVM/Viewmodel/location_controller.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 0);
  String? username;
  int selectedCategoryIndex = 0;
  String searchQuery = "";
  double _minRating = 0;
  String _sortBy = 'None';
  late TextEditingController _searchController;

  final List<String> categoryList = [
    "All",
    "Exterior",
    "Interior",
    "Vehicle",
    "Pet",
    "Home"
  ];

  String get selectedCategory => categoryList[selectedCategoryIndex];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    loadUsername();
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
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(246, 246, 246, 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No services found'));
                    }

                    final allServices = snapshot.data!.docs;
                    final filtered = allServices.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['service_name'] ?? '').toString().toLowerCase();
                      final category = (data['category'] ?? '').toString();
                      final rating = (data['rating'] ?? 0).toDouble();
                      final selected = selectedCategory;

                      final matchesCategory =
                          selected == "All" || category == selected;
                      final matchesSearch =
                          name.contains(searchQuery.toLowerCase());
                      final matchesRating = rating >= _minRating;

                      return matchesCategory && matchesSearch && matchesRating;
                    }).toList();

                    if (_sortBy == 'A-Z') {
                      filtered.sort((a, b) => (a['service_name'] ?? '')
                          .toString()
                          .compareTo((b['service_name'] ?? '').toString()));
                    } else if (_sortBy == 'Rating') {
                      filtered.sort((a, b) =>
                          (b['rating'] ?? 0).compareTo((a['rating'] ?? 0)));
                    }

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 200),
                          if (_searchController.text.isEmpty) ...[
                            CarouselSlider(
                              items: [
                                buildPromoCard("assets/image/add_image.png",
                                    "20% OFF Interior Cleaning"),
                                buildPromoCard("assets/image/add_image.png",
                                    "25% OFF Pet Grooming"),
                              ],
                              options: CarouselOptions(
                                  autoPlay: true,
                                  enlargeCenterPage: true,
                                  aspectRatio: 2.0,
                                  viewportFraction: 1),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ScrollableHorizontalButtons(
                            categories: categoryList,
                            selectedIndex: selectedCategoryIndex,
                            onSelected: (index) {
                              setState(() => selectedCategoryIndex = index);
                            },
                          ),
                          GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.0,
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
                                                  category: filtered[index]
                                                      ['category'],
                                                  serviceName: filtered[index]
                                                      ['service_name'],
                                                  rating: filtered[index]
                                                      ['rating'],
                                                  originalPrice: filtered[index]
                                                      ['original_price'],
                                                  discount: filtered[index]
                                                      ['discount'],
                                                  image: filtered[index]
                                                      ['image'],
                                                  discountPrice: filtered[index]
                                                      ['price'],
                                                  serviceType: filtered[index]
                                                      ['service_type'],
                                                )));
                                  } else if (category == 'Interior') {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => InteriorBookingPage(
                                                  category: filtered[index]
                                                      ['category'],
                                                  serviceName: filtered[index]
                                                      ['service_name'],
                                                  rating: filtered[index]
                                                      ['rating'],
                                                  originalPrice: filtered[index]
                                                      ['original_price'],
                                                  discount: filtered[index]
                                                      ['discount'],
                                                  image: filtered[index]
                                                      ['image'],
                                                  discountPrice: filtered[index]
                                                      ['price'],
                                                  serviceType: filtered[index]
                                                      ['service_type'],
                                                )));
                                  } else if (category == 'Vehicle') {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => VehicleBookingPage(
                                                  category: filtered[index]
                                                      ['category'],
                                                  serviceName: filtered[index]
                                                      ['service_name'],
                                                  rating: filtered[index]
                                                      ['rating'],
                                                  originalPrice: filtered[index]
                                                      ['original_price'],
                                                  discount: filtered[index]
                                                      ['discount'],
                                                  image: filtered[index]
                                                      ['image'],
                                                  discountPrice: filtered[index]
                                                      ['price'],
                                                  serviceType: filtered[index]
                                                      ['service_type'],
                                                )));
                                  } else if (category == 'Pet') {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => PetCleaning(
                                                  category: filtered[index]
                                                      ['category'],
                                                  serviceName: filtered[index]
                                                      ['service_name'],
                                                  rating: filtered[index]
                                                      ['rating'],
                                                  originalPrice: filtered[index]
                                                      ['original_price'],
                                                  discount: filtered[index]
                                                      ['discount'],
                                                  image: filtered[index]
                                                      ['image'],
                                                  discountPrice: filtered[index]
                                                      ['price'],
                                                  serviceType: filtered[index]
                                                      ['service_type'],
                                                )));
                                  } else if (category == 'Home') {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => HomeBookingPage(
                                                  category: filtered[index]
                                                      ['category'],
                                                  serviceName: filtered[index]
                                                      ['service_name'],
                                                  rating: filtered[index]
                                                      ['rating'],
                                                  originalPrice: filtered[index]
                                                      ['original_price'],
                                                  discount: filtered[index]
                                                      ['discount'],
                                                  image: filtered[index]
                                                      ['image'],
                                                  discountPrice: filtered[index]
                                                      ['price'],
                                                  serviceType: filtered[index]
                                                      ['service_type'],
                                                )));
                                  }
                                },
                                child: ServiceCard(
                                  image: filtered[index]['image'] ?? '',
                                  rating: (filtered[index]['rating'] ?? 0)
                                      .toDouble(),
                                  title: (filtered[index]['service_name'] ?? '')
                                      .toString()
                                      .toUpperCase(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                    gradient: LinearGradient(
                      colors: [gradientgreen1.c, gradientgreen3.c],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 50),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(' Good day for cleaning',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[400])),
                          Padding(
                            padding: const EdgeInsets.only(right: 25),
                            child: Text(
                              username != null ? 'Hello, $username' : 'Hello!',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          Obx(() {
                            final loc =
                                LocationController.to.currentLocation.value;
                            if (loc.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4, right: 25),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Color(0xFFF5B544), size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      loc,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: mq.height * 0.17,
                  left: 20,
                  right: 70,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: Image.asset("assets/icons/serch_icon.png",
                            color: Colors.black),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: mq.height * 0.17,
                  right: 10,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => buildFilterSheet(),
                      ),
                      child: Container(
                        height: 55,
                        width: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white),
                        child: Image.asset("assets/icons/filtter_icon.png",
                            scale: 1.3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 45,
                  right: 20,
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Colors.white),
                        onPressed: () {},
                      ),
                      if (notificationCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPromoCard(String imagePath, String title) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: <Widget>[
          Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(200, 0, 0, 0),
                    Color.fromARGB(0, 0, 0, 0)
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

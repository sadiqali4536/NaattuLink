import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/add_new_bus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/see_all_buses.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_card_widget.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_notifications.dart';

class BusWorkerhomepage extends StatefulWidget {
  const BusWorkerhomepage.BusWorkerhomepage({Key? key}) : super(key: key);

  @override
  State<BusWorkerhomepage> createState() => _BusWorkerhomepageState();
}

class _BusWorkerhomepageState extends State<BusWorkerhomepage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    // Safely inject controller if not already present (e.g. on hot-reload)
    final controller = Get.put(BusDashboardController());

    return Obx(() {
      if (controller.isLoading.value && controller.userData.isEmpty) {
        return const Scaffold(
          backgroundColor: Color(0xFF0C1F41),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      if (controller.hasError.value || controller.userData.isEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFF0C1F41),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_outlined,
                    color: Colors.white, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'No internet connection or data lost',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => controller.initialize(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0C1F41),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final data = controller.userData;
      final userName = data['username'] ?? 'User';
      final busName = data['bus_name'] ?? 'N/A';
      final regNumber = data['reg_number'] ?? 'N/A';
      final firstStop = data['first_stop'] ?? 'N/A';
      final destination = data['destination'] ?? 'N/A';
      final mainStand = data['main_stand'] ?? 'N/A';
      final arrivalTime = data['arrival_time'] ?? 'N/A';
      final departureTime = data['departure_time'] ?? 'N/A';
      final status = data['status']?.toString().toUpperCase() ?? 'ACTIVE';
      final profileImg = data['profile_img']?.toString() ?? '';

      return Scaffold(
        backgroundColor:
            const Color(0xFF0C1F41), // Dark blue background for top section
        body: SafeArea(
          child: Column(
            children: [
              // Top Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white24,
                              backgroundImage: profileImg.isNotEmpty
                                  ? NetworkImage(profileImg)
                                  : null,
                              onBackgroundImageError: profileImg.isNotEmpty
                                  ? (exception, stackTrace) {
                                      debugPrint(
                                          'Failed to load profile image: $exception');
                                    }
                                  : null,
                              child: profileImg.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back,',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                Text('$userName!',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BusWorkerNotifications(),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search bus, route or number...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon:
                              const Icon(Icons.filter_list, color: Colors.grey),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    Builder(
                      builder: (context) {
                        int totalBuses = 0;
                        int activeBuses = 0;

                        final hasOriginalBus = (data['bus_name'] != null &&
                            data['bus_name'].toString().isNotEmpty);
                        if (hasOriginalBus) {
                          totalBuses += 1;
                          if (status == 'ACTIVE' || status == 'TRUE') {
                            activeBuses += 1;
                          }
                        }

                        totalBuses += controller.buses.length;
                        for (var doc in controller.buses) {
                          final bData = doc.data() as Map<String, dynamic>;
                          final bStatusStr =
                              bData['status']?.toString().toUpperCase();
                          if (bStatusStr == 'ACTIVE' || bStatusStr == 'TRUE') {
                            activeBuses += 1;
                          }
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCard('TOTAL BUSES', totalBuses.toString(),
                                Icons.swap_horiz, Colors.blue),
                            _buildStatCard(
                                'ACTIVE TRIPS',
                                activeBuses.toString(),
                                Icons.timelapse,
                                Colors.orange),
                            _buildStatCard(
                                'ACTIVE ROUTES',
                                activeBuses.toString(),
                                Icons.map,
                                Colors.white),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom White Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Active Buses',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SeeAllBusesScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('See All',
                                        style: TextStyle(color: Colors.grey))),
                              ],
                            ),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  List<Widget> busCards = [];

                                  final hasOriginalBus = (data['bus_name'] !=
                                          null &&
                                      data['bus_name'].toString().isNotEmpty);

                                  if (hasOriginalBus) {
                                    bool matches = busName
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        firstStop
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        destination
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        mainStand
                                            .toLowerCase()
                                            .contains(_searchQuery);
                                    if (matches) {
                                      busCards.add(BusCardWidget(
                                        busName: busName,
                                        regNumber: regNumber,
                                        firstStop: firstStop,
                                        destination: destination,
                                        arrivalTime: arrivalTime,
                                        departureTime: departureTime,
                                        status: status,
                                        docId: uid,
                                        isMainBus: true,
                                        rawData: data,
                                      ));
                                    }
                                  }

                                  for (var doc in controller.buses) {
                                    final bData =
                                        doc.data() as Map<String, dynamic>;
                                    final bName =
                                        bData['bus_name'] ?? 'Unknown';
                                    final bFirst =
                                        bData['start_place'] ?? 'Start';
                                    final bDest = bData['destination'] ?? 'End';
                                    final bMainStand =
                                        bData['main_stand'] ?? '';

                                    bool matches = bName
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        bFirst
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        bDest
                                            .toLowerCase()
                                            .contains(_searchQuery) ||
                                        bMainStand
                                            .toLowerCase()
                                            .contains(_searchQuery);

                                    if (matches) {
                                      busCards.add(BusCardWidget(
                                        busName: bName,
                                        regNumber:
                                            bData['registration_number'] ??
                                                'N/A',
                                        firstStop: bFirst,
                                        destination: bDest,
                                        arrivalTime:
                                            bData['arrival_time'] ?? '--:--',
                                        departureTime:
                                            bData['departure_time'] ?? '--:--',
                                        status: (bData['status'] == true ||
                                                bData['status'] == 'true' ||
                                                bData['status'] == 'active' ||
                                                bData['status'] == 'ACTIVE')
                                            ? 'ACTIVE'
                                            : 'INACTIVE',
                                        docId: doc.id,
                                        isMainBus: false,
                                        rawData: bData,
                                      ));
                                    }
                                  }

                                  if (busCards.isEmpty) {
                                    return Center(
                                        child: Text(_searchQuery.isEmpty
                                            ? "No buses found. Click + to add."
                                            : "No buses match your search."));
                                  }

                                  return ListView(
                                    controller: controller.scrollController,
                                    children: busCards,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const AddNewBusScreen()),
                            );
                          },
                          backgroundColor: const Color(0xFF0C1F41),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

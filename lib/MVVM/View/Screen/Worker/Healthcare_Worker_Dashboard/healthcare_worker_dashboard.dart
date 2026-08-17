import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/healthcare_worker_homepage.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/controller/healthcare_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/healthcare_worker_profile.dart';

class HealthcareWorkerDashboard extends StatefulWidget {
  const HealthcareWorkerDashboard({super.key});

  @override
  State<HealthcareWorkerDashboard> createState() =>
      _HealthcareWorkerDashboardState();
}

class _HealthcareWorkerDashboardState extends State<HealthcareWorkerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HealthcareWorkerHomepage(),
    const HealthcareWorkerProfile(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put(HealthcareDashboardController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color.fromRGBO(
              15, 42, 82, 100), // Yellow accent from mockup
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(15, 42, 82, 1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.home_filled,
                    color: Color.fromRGBO(15, 42, 82, 1)),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(15, 42, 82, 1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person,
                    color: Color.fromRGBO(15, 42, 82, 1)),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

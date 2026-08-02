import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_homepage.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_profile.dart';

class BusWorkerDashboard extends StatefulWidget {
  const BusWorkerDashboard({Key? key}) : super(key: key);

  @override
  State<BusWorkerDashboard> createState() => _BusWorkerDashboardState();
}

class _BusWorkerDashboardState extends State<BusWorkerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BusWorkerhomepage.BusWorkerhomepage(),
    const BusWorkerProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor:
              const Color(0xFFF9A825), // Gold/Yellow color from design
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

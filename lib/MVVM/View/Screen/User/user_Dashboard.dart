import 'dart:developer';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/chat/Chatpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Home/Homepage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/services/Services_list.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/profile.dart';

class user_Dashboard extends StatefulWidget {
  const user_Dashboard({super.key});

  @override
  State<user_Dashboard> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<user_Dashboard> {
  final _pageController = PageController(initialPage: 0);
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 0);

  int maxCount = 5;
  int cartCount = 0;

  late final List<Widget> _bottomBarPages;

  @override
  void initState() {
    super.initState();
    _bottomBarPages = [
      const Homepage(),
      const ServicesList(),
      CartPage(),
      const ChatPage(),
      const Profile(),
    ];
    _getCartItemCount();
  }

  void _getCartItemCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('cartItems')
          .snapshots()
          .listen((snapshot) {
        setState(() {
          cartCount = snapshot.docs.length;
        });
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iconPaths = [
      "assets/icons/list_bottombar.png",
      "assets/icons/cart_bottombar.png",
      "assets/icons/chat_bottomnavigationbar.png",
      "assets/icons/profile_bottombar.png",
    ];

    for (final path in iconPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _bottomBarPages.length,
        physics:
            const NeverScrollableScrollPhysics(), // Change to NeverScrollableScrollPhysics() to disable swipe
        onPageChanged: (index) {
          _controller.index = index; // Sync bottom bar with swipe
        },
        itemBuilder: (context, index) => _bottomBarPages[index],
      ),
      extendBody: true,
      bottomNavigationBar: (_bottomBarPages.length <= maxCount)
          ? AnimatedNotchBottomBar(
              notchBottomBarController: _controller,
              color: const Color.fromARGB(255, 248, 248, 248),
              showLabel: false,
              maxLine: 1,
              shadowElevation: 5,
              kBottomRadius: 18.0,
              notchGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(88, 142, 12, 1),
                  Color.fromRGBO(53, 120, 1, 1),
                ],
              ),
              removeMargins: false,
              bottomBarWidth: 432,
              bottomBarHeight: 75,
              showShadow: true,
              durationInMilliSeconds: 300,
              elevation: 5,
              kIconSize: 24.0,
              bottomBarItems: [
                BottomBarItem(
                  inActiveItem: Icon(Icons.home_filled,
                      color: const Color.fromRGBO(133, 130, 130, 1)),
                  activeItem: Icon(Icons.home_filled, color: Colors.white),
                ),
                BottomBarItem(
                  inActiveItem: Image.asset(
                    "assets/icons/list_bottombar.png",
                    color: const Color.fromRGBO(133, 130, 130, 1),
                  ),
                  activeItem: Image.asset(
                    "assets/icons/list_bottombar.png",
                    color: Colors.white,
                  ),
                ),
                BottomBarItem(
                  inActiveItem: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset("assets/icons/cart_bottombar.png"),
                      if (cartCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 20, minHeight: 20),
                            child: Center(
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeItem: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset("assets/icons/cart_bottombar.png",
                          color: Colors.white),
                      if (cartCount > 0)
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: Container(
                            height: 22,
                            width: 22,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
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
                BottomBarItem(
                  inActiveItem: Image.asset(
                    "assets/icons/chat_bottomnavigationbar.png",
                    color: const Color.fromRGBO(133, 130, 130, 1),
                  ),
                  activeItem: Image.asset(
                    "assets/icons/chat_bottomnavigationbar.png",
                    color: Colors.white,
                  ),
                ),
                BottomBarItem(
                  inActiveItem:
                      Image.asset("assets/icons/profile_bottombar.png"),
                  activeItem: Image.asset(
                    "assets/icons/profile_bottombar.png",
                    color: Colors.white,
                  ),
                ),
              ],
              onTap: (index) {
                log('current selected index $index');
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            )
          : null,
    );
  }
}

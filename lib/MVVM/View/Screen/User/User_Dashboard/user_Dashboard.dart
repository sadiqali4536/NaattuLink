import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/Home/Homepage.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/profile.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/my_bookings.dart';

class user_Dashboard extends StatefulWidget {
  const user_Dashboard({super.key});

  @override
  State<user_Dashboard> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<user_Dashboard> {
  int _currentIndex = 0;
  int cartCount = 0;

  /// Key gives us access to HomepageState.resetToForYou()
  final GlobalKey<HomepageState> _homepageKey = GlobalKey<HomepageState>();

  late final List<Widget> _bottomBarPages;

  @override
  void initState() {
    super.initState();
    _bottomBarPages = [
      Homepage(key: _homepageKey),
      CartPage(),
      const MyBookings(),
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
        if (mounted) {
          setState(() {
            cartCount = snapshot.docs.length;
          });
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iconPaths = [
      "assets/icons/cart_bottombar.png",
      "assets/icons/booking.png",
      "assets/icons/profile_bottombar.png",
    ];

    for (final path in iconPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "My Cart";
      case 2:
        return "Bookings";
      case 3:
        return "Profile";
      default:
        return "";
    }
  }

  Widget _buildIcon(int index, bool isActive) {
    final color = isActive ? const Color(0xFF0F2E5A) : const Color(0xFF858282);
    switch (index) {
      case 0:
        return Icon(Icons.home_filled, color: color, size: 24);
      case 1:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              "assets/icons/cart_bottombar.png",
              color: color,
              height: 24,
              width: 24,
            ),
            if (cartCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case 2:
        return Image.asset(
          "assets/icons/booking.png",
          color: color,
          height: 24,
          width: 24,
        );
      case 3:
        return Image.asset(
          "assets/icons/profile_bottombar.png",
          color: color,
          height: 24,
          width: 24,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabItem(int index) {
    final isActive = _currentIndex == index;
    final label = _getLabel(index);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // If tapping Home (index 0): always reset category + scroll to top.
          // This covers both:
          //   • Returning from another tab  (switch to Home)
          //   • Double-tapping Home while already on it
          if (index == 0) {
            _homepageKey.currentState?.resetToForYou();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(index, isActive),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF0F2E5A)
                      : const Color(0xFF858282),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _bottomBarPages,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final tabCount = _bottomBarPages.length;
                final tabWidth = totalWidth / tabCount;

                const horizontalMargin = 6.0;
                final pillWidth = tabWidth - (horizontalMargin * 2);
                const pillHeight = 56.0;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: _currentIndex * tabWidth + horizontalMargin,
                      top: (75 - pillHeight) / 2,
                      width: pillWidth,
                      height: pillHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: List.generate(
                          tabCount,
                          (index) => _buildTabItem(index),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}

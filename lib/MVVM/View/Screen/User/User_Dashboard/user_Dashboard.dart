import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Homepage.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/account_profile_screen.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/my_bookings.dart';

class user_Dashboard extends StatefulWidget {
  final int initialHomeCategoryIndex;
  const user_Dashboard({super.key, this.initialHomeCategoryIndex = 0});

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
      Homepage(
          key: _homepageKey,
          initialCategoryIndex: widget.initialHomeCategoryIndex),
      CartPage(),
      const MyBookings(),
      const AccountProfileScreen(),
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
    final color = isActive
        ? Color.fromARGB(255, 18, 56, 110)
        : const Color(0xFF858282); // Purple for active
    switch (index) {
      case 0:
        return Icon(Icons.home_outlined, color: color, size: 26);
      case 1:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.shopping_cart_outlined, color: color, size: 26),
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
        return Icon(Icons.assignment_outlined, color: color, size: 26);
      case 3:
        return Icon(Icons.person_outline, color: color, size: 26);
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Color.fromARGB(255, 255, 212, 13).withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(index, isActive),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? Color(0xFF0F2E5A)
                            : const Color(0xFF858282),
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 10,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _bottomBarPages,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _bottomBarPages.length,
                (index) => _buildTabItem(index),
              ),
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

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/cart/Cartpage.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Homepage.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/account_profile_screen.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/my_bookings.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/viewmodel/cart_controller.dart';

class user_Dashboard extends StatefulWidget {
  final int initialHomeCategoryIndex;
  final int initialIndex;
  const user_Dashboard({
    super.key,
    this.initialHomeCategoryIndex = 0,
    this.initialIndex = 0,
  });

  @override
  State<user_Dashboard> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<user_Dashboard> {
  late int _currentIndex;

  /// Key gives us access to HomepageState.resetToForYou()
  final GlobalKey<HomepageState> _homepageKey = GlobalKey<HomepageState>();

  late final List<Widget> _bottomBarPages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Ensure CartController is put into memory permanently
    Get.put(CartController(), permanent: true);

    _bottomBarPages = [
      Homepage(
          key: _homepageKey,
          initialCategoryIndex: widget.initialHomeCategoryIndex),
      CartPage(),
      const MyBookings(),
      const AccountProfileScreen(),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final iconPaths = [
      "assets/icons/home_new.png",
      "assets/icons/cart_new.png",
      "assets/icons/bookings_new.png",
      "assets/icons/profile_new.png",
    ];

    for (final path in iconPaths) {
      precacheImage(AssetImage(path), context);
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'home'.tr;
      case 1:
        return 'my_cart'.tr;
      case 2:
        return 'bookings'.tr;
      case 3:
        return 'profile'.tr;
      default:
        return "";
    }
  }

  Widget _buildIcon(int index, bool isActive) {
    final color = isActive
        ? Colors.white
        : const Color(0xFF858282); // Active is white, inactive is grey
    switch (index) {
      case 0:
        return Image.asset("assets/icons/home_new.png",
            color: color, width: 26, height: 26);
      case 1:
        return Obx(() {
          final cartCount = Get.find<CartController>().cartItems.length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset("assets/icons/cart_new.png",
                  color: color, width: 26, height: 26),
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
        });
      case 2:
        return Image.asset("assets/icons/bookings_new.png",
            color: color, width: 26, height: 26);
      case 3:
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          return Image.asset("assets/icons/profile_new.png",
              color: color, width: 26, height: 26);
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('store_products')
              .where('sellerId', isEqualTo: uid)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            int outOfStockCount = 0;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                bool isProductOutOfStock = false;
                final status = (data['status']?.toString().toUpperCase() ?? '');
                if (status == 'OUT OF STOCK' || status == 'OUT_OF_STOCK') {
                  isProductOutOfStock = true;
                } else {
                  final stockQty = data['stockQuantity'];
                  if (stockQty != null) {
                    final qty = num.tryParse(stockQty.toString()) ?? 0;
                    if (qty <= 0) isProductOutOfStock = true;
                  }
                  if (!isProductOutOfStock) {
                    final variants = data['variants'];
                    if (variants is List && variants.isNotEmpty) {
                      isProductOutOfStock = variants.every((v) {
                        final vStock = num.tryParse(
                                (v is Map ? v['stockQuantity'] : null)
                                        ?.toString() ??
                                    '1') ??
                            1;
                        return vStock <= 0;
                      });
                    }
                  }
                }
                if (isProductOutOfStock) outOfStockCount++;
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset("assets/icons/profile_new.png",
                    color: color, width: 26, height: 26),
                if (outOfStockCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            );
          },
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
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isActive ? const Color(0xFF0F2E5A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildIcon(index, isActive),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF0F2E5A)
                      : const Color(0xFF858282),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
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
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _bottomBarPages,
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200, width: 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -4),
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

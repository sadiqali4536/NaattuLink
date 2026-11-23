import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/View/Screen/User/Queue/business_queue_live_page.dart';
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
  bool _isLoadingIdentity = true;
  bool _isBusiness = false;
  bool _queueEnabled = false;
  String _businessDocId = '';
  String _businessCollection = '';
  StreamSubscription<DocumentSnapshot>? _businessSubscription;

  /// Key gives us access to HomepageState.resetToForYou()
  final GlobalKey<HomepageState> _homepageKey = GlobalKey<HomepageState>();

  late List<Widget> _bottomBarPages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Ensure CartController is put into memory permanently
    Get.put(CartController(), permanent: true);
    _resolveUserIdentity();
  }

  Future<void> _resolveUserIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final collections = ['businesses', 'shops', 'shops_businesses'];
      for (String col in collections) {
        final doc = await getUserDocument(user, col);
        if (doc != null && doc.exists) {
          _isBusiness = true;
          _businessDocId = doc.id;
          _businessCollection = col;
          // Read queueEnabled initially
          final data = doc.data() as Map<String, dynamic>?;
          _queueEnabled = (data?['queueEnabled'] ?? false) == true;

          // Set up real-time listener
          _businessSubscription = FirebaseFirestore.instance
              .collection(col)
              .doc(doc.id)
              .snapshots()
              .listen((snapshot) {
            if (snapshot.exists) {
              final updatedData = snapshot.data();
              final isEnabled = (updatedData?['queueEnabled'] ?? false) == true;
              if (mounted && _queueEnabled != isEnabled) {
                setState(() {
                  _queueEnabled = isEnabled;
                  _updateBottomBarPages();
                  // Adjust current index if it was on Queue and queue was disabled
                  if (!_queueEnabled && _currentIndex == 2) {
                    _currentIndex = 0; // Go to home
                  } else if (!_queueEnabled && _currentIndex > 2) {
                    _currentIndex--; // Shift indices down
                  } else if (_queueEnabled && _currentIndex >= 2) {
                    _currentIndex++; // Shift indices up
                  }
                });
              }
            }
          });
          break;
        }
      }
    }

    _updateBottomBarPages();

    if (mounted) {
      setState(() {
        _isLoadingIdentity = false;
      });
    }
  }

  void _updateBottomBarPages() {
    _bottomBarPages = [
      Homepage(
          key: _homepageKey,
          initialCategoryIndex: widget.initialHomeCategoryIndex),
      CartPage(),
    ];

    if (_isBusiness && _queueEnabled) {
      _bottomBarPages.add(BusinessQueueLivePage(
        businessDocId: _businessDocId,
        collection: _businessCollection,
      ));
    }

    _bottomBarPages.add(const MyBookings());
    _bottomBarPages.add(const AccountProfileScreen());
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

  @override
  void dispose() {
    _businessSubscription?.cancel();
    super.dispose();
  }

  String _getLabel(int index) {
    if (_isBusiness && _queueEnabled) {
      // 5 tabs: Home, Cart, Queue, Bookings, Profile
      switch (index) {
        case 0:
          return 'home'.tr;
        case 1:
          return 'my_cart'.tr;
        case 2:
          return 'queue'.tr;
        case 3:
          return 'bookings'.tr;
        case 4:
          return 'profile'.tr;
        default:
          return "";
      }
    } else {
      // 4 tabs: Home, Cart, Bookings, Profile
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
  }

  Widget _buildIcon(int index, bool isActive) {
    final color = isActive
        ? Colors.white
        : const Color(0xFF858282); // Active is white, inactive is grey

    int resolvedIndex = index;
    if (_isBusiness && _queueEnabled) {
      // Queue is at index 2 — show the clock icon
      if (index == 2) {
        final queueColor =
            isActive ? const Color(0xFF0F2E5A) : const Color(0xFF858282);
        return Icon(Icons.watch_later_rounded, color: queueColor, size: 32);
      } else if (index == 3) {
        resolvedIndex = 2; // bookings
      } else if (index == 4) {
        resolvedIndex = 3; // profile
      }
    }

    switch (resolvedIndex) {
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
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text('$cartCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold)),
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
                final status = (data['status']?.toString().toUpperCase() ?? '');
                if (status == 'OUT OF STOCK' || status == 'OUT_OF_STOCK') {
                  outOfStockCount++;
                }
              }
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset("assets/icons/profile_new.png",
                    color: color, width: 26, height: 26),
                if (outOfStockCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
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

    if (_isBusiness && _queueEnabled && index == 2) {
      // Empty slot for the notched FloatingActionButton
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(height: 36),
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
            const SizedBox(height: 8),
          ],
        ),
      );
    }

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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      isActive ? const Color(0xFF0F2E5A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
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
    if (_isLoadingIdentity) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: FadeIndexedStack(
        index: _currentIndex,
        children: _bottomBarPages,
      ),
      extendBody: _isBusiness && _queueEnabled,
      floatingActionButtonLocation: (_isBusiness && _queueEnabled)
          ? FloatingActionButtonLocation.centerDocked
          : null,
      floatingActionButton: (_isBusiness && _queueEnabled)
          ? SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 6,
                shape: const CircleBorder(),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                child: Icon(
                  Icons.watch_later_rounded,
                  color: _currentIndex == 2
                      ? const Color(0xFF0F2E5A)
                      : const Color(0xFF858282),
                  size: 32,
                ),
              ),
            )
          : null,
      bottomNavigationBar: (_isBusiness && _queueEnabled)
          // ── Notched bar for businesses with queue enabled ──
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomAppBar(
                padding: EdgeInsets.zero,
                notchMargin: 8,
                shape: const CircularNotchedRectangle(),
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 75,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      _bottomBarPages.length,
                      (index) => _buildTabItem(index),
                    ),
                  ),
                ),
              ),
            )
          // ── Regular curved bar (queue disabled / regular user) ──
          : DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: SafeArea(
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_bottomBarPages.length, (index) {
                        final isActive = _currentIndex == index;
                        final label = _getLabel(index);
                        return GestureDetector(
                          onTap: () {
                            if (index == 0) {
                              _homepageKey.currentState?.resetToForYou();
                            }
                            setState(() => _currentIndex = index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 32) /
                                _bottomBarPages.length,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF0F2E5A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
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
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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

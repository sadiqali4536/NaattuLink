import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:swiftclean_project/MVVM/View/Screen/Worker/Worker_Dashboard.dart';
import 'package:swiftclean_project/MVVM/Viewmodel/location_controller.dart';
import 'package:swiftclean_project/MVVM/utils/Founctions/helper_functions.dart';
import 'package:swiftclean_project/MVVM/utils/widget/BottomNavigationbar/BottomNvigationBar.dart';

class FindingLocationPage extends StatefulWidget {
  const FindingLocationPage({super.key});

  @override
  State<FindingLocationPage> createState() => _FindingLocationPageState();
}

class _FindingLocationPageState extends State<FindingLocationPage>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  late final Animation<double> _lineWidthAnimation;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _lineWidthAnimation = Tween<double>(begin: 0.10, end: 0.32).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Step 1: fetch location → Step 2: check auth → Step 3: navigate
    _fetchLocationThenRoute();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Location + Auth logic ──────────────────────────────────────────────────

  Future<void> _fetchLocationThenRoute() async {
    String placeName = 'Unknown Location';

    try {
      // Step 1: Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('[LOC] Permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('[LOC] After request, permission: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        print('[LOC] Permission permanently denied — skipping GPS');
      } else {
        // Step 2: Check service
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        print('[LOC] Location service enabled: $serviceEnabled');

        if (!serviceEnabled) {
          print('[LOC] Location service is OFF — skipping GPS');
        } else {
          // Step 3: Get position
          print('[LOC] Fetching position...');
          final Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          print(
              '[LOC] Got position: ${position.latitude}, ${position.longitude}');

          // Step 4: Reverse geocode
          print('[LOC] Reverse geocoding...');
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          print('[LOC] Placemarks count: ${placemarks.length}');

          if (placemarks.isNotEmpty) {
            final Placemark place = placemarks.first;
            print(
                '[LOC] subLocality=${place.subLocality} locality=${place.locality} adminArea=${place.administrativeArea}');
            final parts = <String>[
              if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
              if ((place.locality ?? '').isNotEmpty) place.locality!,
              if ((place.administrativeArea ?? '').isNotEmpty)
                place.administrativeArea!,
            ];
            placeName =
                parts.isNotEmpty ? parts.take(2).join(', ') : 'My Location';
          }
        }
      }
    } catch (e, st) {
      print('[LOC] ERROR during location fetch: $e');
      print('[LOC] StackTrace: $st');
    }

    print('[LOC] Final placeName: "$placeName"');

    if (!mounted) {
      print('[LOC] Widget not mounted — aborting navigation');
      return;
    }
    _routeByAuth(placeName);
  }

  Future<void> _routeByAuth(String placeName) async {
    // Save location in the global controller so any page can observe it
    LocationController.to.currentLocation.value = placeName;
    print(
        '[LOC] LocationController set to: "${LocationController.to.currentLocation.value}"');

    final user = FirebaseAuth.instance.currentUser;
    print('[LOC] Auth user: ${user?.uid ?? "null (not logged in)"}');

    if (user == null) {
      Get.offAll(() => const LoginAndSigning());
      return;
    }

    final role = await getRole(user.uid);
    print('[LOC] User role: $role');

    if (role == 'user') {
      Get.offAll(() => Bottomnvigationbar());
    } else if (role == 'worker') {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(user.uid)
          .get();

      final isVerified = workerDoc.data()?['isVerified'] == 1;
      print('[LOC] Worker isVerified: $isVerified');

      if (isVerified) {
        Get.offAll(() => WorkerDashboard());
      } else {
        Get.offAll(() => const LoginAndSigning());
      }
    } else {
      Get.offAll(() => const LoginAndSigning());
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  static const Color _navy = Color(0xFF12233E);
  static const Color _amber = Color(0xFFF5B544);
  static const Color _violet = Color(0xFF7B5EA7);
  static const Color _blue = Color(0xFF4169E1);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hub = size.width * 0.78;
    final orbit = hub * 0.46;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Background — fills the entire screen ───────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/bg/location_fetchig_backround.png',
                fit: BoxFit.fill,
              ),
            ),

            // ── Content layer ──────────────────────────────────────────────
            Positioned.fill(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.22),

                  // ── Animation hub ─────────────────────────────────────────
                  SizedBox(
                    width: hub,
                    height: hub,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _ring(hub, Colors.blueGrey.withOpacity(0.07)),
                        _ring(hub * 0.79, Colors.blueGrey.withOpacity(0.10)),
                        _ring(hub * 0.60, Colors.blueGrey.withOpacity(0.14)),

                        // Neumorphic white platform
                        Container(
                          width: hub * 0.496,
                          height: hub * 0.496,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.22),
                                blurRadius: 32,
                                spreadRadius: 8,
                                offset: const Offset(6, 10),
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 18,
                                spreadRadius: -3,
                                offset: Offset(-4, -4),
                              ),
                            ],
                          ),
                        ),

                        // Rotating ticks
                        RotationTransition(
                          turns: _rotateController,
                          child: SizedBox(
                            width: orbit * 2,
                            height: orbit * 2,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                    left: 0,
                                    child: _tick(w: 9, h: 42, color: _amber)),
                                Positioned(
                                    right: 0,
                                    child: _tick(w: 9, h: 42, color: _amber)),
                                Positioned(
                                    top: 0,
                                    child: _tick(w: 30, h: 8, color: _amber)),
                                Positioned(
                                    bottom: 0,
                                    child: _tick(w: 34, h: 8, color: _blue)),
                              ],
                            ),
                          ),
                        ),

                        // Pulsing navy centre
                        ScaleTransition(
                          scale: _pulse,
                          child: Container(
                            width: hub * 0.325,
                            height: hub * 0.325,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _navy,
                              boxShadow: [
                                BoxShadow(
                                  color: _navy.withOpacity(0.30),
                                  blurRadius: 24,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(Icons.navigation_rounded,
                                color: Colors.white, size: hub * 0.14),
                          ),
                        ),

                        // Violet pin top-right
                        Positioned(
                          top: hub * 0.08,
                          right: hub * 0.04,
                          child: _locationPin(_violet, size: hub * 0.10),
                        ),
                        // Amber pin bottom-left
                        Positioned(
                          bottom: hub * 0.13,
                          left: hub * 0.04,
                          child: _locationPin(_amber, size: hub * 0.082),
                        ),

                        // Sparkles
                        Positioned(
                            top: hub * 0.28,
                            left: hub * 0.15,
                            child: _sparkle(hub * 0.048)),
                        Positioned(
                            top: hub * 0.20,
                            right: hub * 0.25,
                            child: _sparkle(hub * 0.036)),
                        Positioned(
                            bottom: hub * 0.28,
                            right: hub * 0.16,
                            child: _sparkle(hub * 0.042)),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.055),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    'Finding your location...',
                    style: TextStyle(
                      color: _navy,
                      fontSize: size.width * 0.058,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: size.height * 0.012),

                  // Gradient underline
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 3,
                        width: size.width * _lineWidthAnimation.value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient:
                              const LinearGradient(colors: [_blue, _amber]),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: size.height * 0.022),

                  // Subtitle
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.12),
                    child: Text(
                      'Connecting you with local experts\nand services in your area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blueGrey[400],
                        fontSize: size.width * 0.037,
                        height: 1.6,
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _ring(double size, Color borderColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
    );
  }

  Widget _tick({required double w, required double h, required Color color}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _locationPin(Color color, {required double size}) {
    return Icon(Icons.location_on_rounded, color: color, size: size);
  }

  Widget _sparkle(double size) {
    return Text(
      '✦',
      style: TextStyle(
        color: _amber.withOpacity(0.65),
        fontSize: size,
        height: 1,
      ),
    );
  }
}

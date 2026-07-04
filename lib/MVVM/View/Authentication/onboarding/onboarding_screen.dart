import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/controller/common_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  late AnimationController _pinAnimationController;
  late AnimationController _ambientController;
  bool _isAnimatingPin = false;
  double _pagePosition = 0.0;
  bool _isButtonPressed = false;
  bool _isPageAnimating = false;

  @override
  void initState() {
    super.initState();
    _pinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 1000), // Sped up travel speed per request
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds continuous loops
    )..repeat();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _pagePosition = _pageController.page ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pinAnimationController.dispose();
    _ambientController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    GetStorage().write('onboarding', 'true');
    CommonController.to.onboardingCompleted.value = true;
    Get.offAll(() => const LoginAndSigning());
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full-screen PageView (Only slides the top and bottom contents)
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPage('assets/bg/onboarding1.png', 0),
                _buildPage('assets/bg/onboarding2.png', 1),
                _buildPage('assets/bg/onboarding3.png', 2),
                _buildPage('assets/bg/onboarding4.png', 3),
              ],
            ),
          ),

          // 2. Static Dot Indicators (Fixed in the white space gap on top of the tagline image)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            top: _currentPage == 0
                ? mq.height * 0.48
                : (_currentPage == 1
                    ? mq.height * 0.46
                    : (_currentPage == 2
                        ? mq.height * 0.49
                        : mq.height * 0.82)),
            left: 0,
            right: 0,
            child: Center(
              child: _buildIndicators(),
            ),
          ),

          // 3. Static Bottom Button and Terms of Service (Fixed at the bottom of the screen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom +
                    (_currentPage == 0
                        ? 120
                        : (_currentPage == 1
                            ? 80
                            : (_currentPage == 2 ? 85 : 80))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCTAButton(),
                  // Animated Terms of Service text at the bottom for page 4
                  // AnimatedCrossFade(
                  //   firstChild: const SizedBox(height: 0),
                  //   secondChild: const Padding(
                  //     padding: EdgeInsets.only(top: 10),
                  //     child: Text(
                  //       "By tapping 'Get Started', you agree to our Terms of Service",
                  //       style: TextStyle(
                  //         color: Color(0xFF64748B),
                  //         fontSize: 10,
                  //         decoration: TextDecoration.underline,
                  //       ),
                  //       textAlign: TextAlign.center,
                  //     ),
                  //   ),
                  //   crossFadeState: _currentPage == 3
                  //       ? CrossFadeState.showSecond
                  //       : CrossFadeState.showFirst,
                  //   duration: const Duration(milliseconds: 250),
                  // ),
                ],
              ),
            ),
          ),

          // 4. Header Skip Button (Aligned to top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _finishOnboarding,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _currentPage == 2
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFFE2E8F0).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        color: _currentPage == 2
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DOT INDICATORS ---
  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final bool isActive = index == _currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24.0 : 8.0,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0A235C) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildCTAButton() {
    final bool isPage1 = _currentPage == 0;
    final String buttonText = (isPage1)
        ? "Get Started"
        : (_currentPage == 3 ? "Get Started" : "Next");
    final Color buttonColor =
        isPage1 ? const Color(0xFF0A235C) : const Color(0xFFFBBF24);
    final Color textColor = isPage1 ? Colors.white : const Color(0xFF0A235C);

    final Color arrowBgColor =
        isPage1 ? const Color(0xFFFBBF24) : const Color(0xFF0A235C);
    final Color arrowIconColor =
        isPage1 ? const Color(0xFF0A235C) : const Color(0xFFFBBF24);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isButtonPressed = true),
      onTapUp: (_) => setState(() => _isButtonPressed = false),
      onTapCancel: () => setState(() => _isButtonPressed = false),
      child: AnimatedScale(
        scale: _isButtonPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_isPageAnimating) return;

              if (_currentPage == 0 || _currentPage == 1) {
                if (!_isAnimatingPin) {
                  setState(() {
                    _isAnimatingPin = true;
                  });
                  _pinAnimationController.forward().then((_) {
                    setState(() {
                      _isPageAnimating = true;
                    });
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOutCubic,
                    ).then((_) {
                      setState(() {
                        _isPageAnimating = false;
                      });
                    });
                    _pinAnimationController.reset();
                    setState(() {
                      _isAnimatingPin = false;
                    });
                  });
                }
              } else if (_currentPage < _totalPages - 1) {
                setState(() {
                  _isPageAnimating = true;
                });
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOutCubic,
                ).then((_) {
                  setState(() {
                    _isPageAnimating = false;
                  });
                });
              } else {
                _finishOnboarding();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(buttonText),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: arrowBgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: arrowIconColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- FULL-SCREEN IMAGE PAGE BUILDER ---
  Widget _buildPage(String assetPath, int index) {
    final bool isPage1 = index == 0;
    final bool isPage2 = index == 1;
    final bool isPage3 = index == 2;
    final bool isPage4 = index == 3;
    final mq = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
          ),
        ),

        // NaattuLink Mockup Content Image (Page 1)
        if (isPage1) ...[
          // 1. Top Image of cleaning professional (includes logo, tagline, man, and curves)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            height: mq.height * 0.44,
            child: Image.asset(
              'assets/image/temp_image1.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Tagline (Your City, One App text & dotted lines)
          Positioned(
            top: mq.height * 0.130,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/image/tagline.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          // 3. Scrollable Cards Row
          Positioned(
            top: mq.height * 0.65,
            left: 0,
            right: 0,
            child: _buildCardsRow(mq),
          ),
        ],

        // Floating/Moving Animations overlays
        if (isPage1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom - 40,
            left: 0,
            right: 0,
            height: 120,
            child: BottomPage1Animation(
              controller: _pinAnimationController,
              ambientController: _ambientController,
            ),
          ),
        if (isPage2)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom - 30,
            left: 0,
            right: 0,
            height: 120,
            child: BottomPage2Animation(
              controller: _pinAnimationController,
              ambientController: _ambientController,
            ),
          ),
        if (isPage3)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom - 40,
            left: (mq.width - 240) / 2,
            width: 240,
            height: 110,
            child: BottomPage3Animation(
              ambientController: _ambientController,
            ),
          ),
        if (isPage4)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom - 30,
            left: 0,
            right: 0,
            height: 120,
            child: BottomPage4Animation(
              ambientController: _ambientController,
            ),
          ),
      ],
    );
  }

  // --- CARDS ROW & CARD BUILDERS ---
  Widget _buildCardsRow(Size mq) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildCard(
            title: "Trusted Workers",
            desc: "Skilled professionals you can count on.",
            icon: Icons.engineering,
            iconBg: const Color(0xFFFFB01D),
            iconColor: const Color(0xFF0D1E4C),
            mq: mq,
          ),
          const SizedBox(width: 12),
          _buildCard(
            title: "Local Shops",
            desc: "Support local businesses near you.",
            icon: Icons.storefront,
            iconBg: const Color(0xFF0D1E4C),
            iconColor: const Color(0xFFFFB01D),
            mq: mq,
          ),
          const SizedBox(width: 12),
          _buildCard(
            title: "City Utilities",
            desc: "Find electricity, water, and local services.",
            icon: Icons.flash_on,
            iconBg: const Color(0xFF0EA5E9),
            iconColor: Colors.white,
            mq: mq,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Size mq,
  }) {
    return Container(
      width: mq.width * 0.44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0D1E4C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WAVE CLIPPER FOR ONBOARDING IMAGE ---
class OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.76);

    final controlPoint = Offset(size.width * 0.45, size.height * 1.05);
    final endPoint = Offset(size.width, size.height * 0.68);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- WAVE PAINTER FOR ONBOARDING SCREEN ---
class OnboardingWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintNavy = Paint()
      ..color = const Color(0xFF0A235C) // Navy
      ..style = PaintingStyle.fill;

    final paintGold = Paint()
      ..color = const Color(0xFFFBBF24) // Gold
      ..style = PaintingStyle.fill;

    // Navy Stripe
    final pathNavy = Path();
    pathNavy.moveTo(0, size.height * 0.76);
    pathNavy.quadraticBezierTo(
        size.width * 0.45, size.height * 1.05, size.width, size.height * 0.68);
    pathNavy.lineTo(size.width, size.height * 0.74);
    pathNavy.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.11,
      0,
      size.height * 0.82,
    );
    pathNavy.close();
    canvas.drawPath(pathNavy, paintNavy);

    // Gold Stripe
    final pathGold = Path();
    pathGold.moveTo(0, size.height * 0.82);
    pathGold.quadraticBezierTo(
        size.width * 0.45, size.height * 1.11, size.width, size.height * 0.74);
    pathGold.lineTo(size.width, size.height * 0.77);
    pathGold.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.14,
      0,
      size.height * 0.85,
    );
    pathGold.close();
    canvas.drawPath(pathGold, paintGold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- ONBOARDING CUSTOM ANIMATIONS ---

class BottomPage1Animation extends StatefulWidget {
  final AnimationController controller;
  final AnimationController ambientController;
  const BottomPage1Animation({
    super.key,
    required this.controller,
    required this.ambientController,
  });

  @override
  State<BottomPage1Animation> createState() => _BottomPage1AnimationState();
}

class _BottomPage1AnimationState extends State<BottomPage1Animation> {
  Widget _buildDustParticle(double x, double y, double opacityFactor) {
    return Positioned(
      left: x - 3,
      top: y - 3,
      child: Opacity(
        opacity: (0.4 * opacityFactor).clamp(0.0, 1.0),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // Symmetrical path starting from background shop (width * 0.42) to destination building (width * 0.78)
        final Path path = Path();
        path.moveTo(width * 0.42, height * 0.65);
        path.quadraticBezierTo(
          width * 0.60,
          height * 0.30,
          width * 0.78,
          height * 0.62,
        );

        return AnimatedBuilder(
          animation:
              Listenable.merge([widget.controller, widget.ambientController]),
          builder: (context, child) {
            final double value = widget.controller.value;
            final double ambient = widget.ambientController.value;

            // 1. Idle Pin Floating and Scaling
            double idleBob = 4.0 * sin(2 * 3.14159 * ambient);
            double idleScale =
                0.98 + 0.04 * ((sin(2 * 3.14159 * ambient) + 1) / 2);

            // 2. Arrival Pin Scale Bounce and Ripple
            double pinScale = idleScale;
            double pinYOffset = idleBob;
            double rippleRadius = 0.0;
            double rippleOpacity = 0.0;

            if (value > 0.85) {
              final double progress = (value - 0.85) / 0.15;
              pinScale = 1.0 + 0.3 * sin(3.14159 * progress);
              pinYOffset = 0.0; // lock position during bounce
              rippleRadius = 45.0 * progress;
              rippleOpacity = (1.0 - progress).clamp(0.0, 1.0);
            }

            // Compute current position of the bike on the path
            Offset pinPosition = Offset(width * 0.42, height * 0.65);
            double tiltAngle = 0.0;

            final List<PathMetric> metricsList = path.computeMetrics().toList();
            if (metricsList.isNotEmpty) {
              final PathMetric metric = metricsList.first;
              final double currentLength = metric.length * value;
              if (currentLength > 0) {
                final Tangent? tangent =
                    metric.getTangentForOffset(currentLength);
                if (tangent != null) {
                  pinPosition = tangent.position;
                  tiltAngle = tangent.angle;
                }
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Dashed path drawn progressively
                Positioned.fill(
                  child: CustomPaint(
                    painter: DashedPathPainter(value),
                  ),
                ),

                // 2. Arrival expanding ripple
                if (value > 0.85)
                  Positioned(
                    left: (width * 0.78) - rippleRadius,
                    top: (height * 0.62) - 10 - rippleRadius,
                    child: Opacity(
                      opacity: rippleOpacity,
                      child: Container(
                        width: rippleRadius * 2,
                        height: rippleRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withOpacity(0.5),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Static destination location pin
                Positioned(
                  left: (width * 0.78) - 15,
                  top: (height * 0.62) - 25 - pinYOffset,
                  child: Transform.scale(
                    scale: pinScale,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF0A235C), // Dark blue destination pin
                      size: 30,
                    ),
                  ),
                ),

                // 4. Dust particles trailing behind the traveling bike
                if (value > 0.05 && value < 0.95) ...[
                  _buildDustParticle(
                      pinPosition.dx - 18, pinPosition.dy + 2, 1.0),
                  _buildDustParticle(
                      pinPosition.dx - 26, pinPosition.dy + 4, 0.7),
                  _buildDustParticle(
                      pinPosition.dx - 34, pinPosition.dy + 5, 0.4),
                ],

                // 5. Glowing light particle following drawing tip
                if (value > 0.05 && value < 0.95)
                  Positioned(
                    left: pinPosition.dx - 4,
                    top: pinPosition.dy - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withOpacity(0.8),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 6. Bike delivery icon running along the path (starts at shop roof)
                Positioned(
                  left: pinPosition.dx - 14 - (1.0 - value) * 36,
                  top: pinPosition.dy -
                      24 -
                      (value > 0.0 ? (4.0 * sin(value * 35).abs()) : 0.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(tiltAngle), // Face left (default)
                    child: const Icon(
                      Icons.directions_bike,
                      color: Color(0xFF0A235C), // Dark blue matching theme
                      size: 28,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AnimatedWorker extends StatefulWidget {
  const AnimatedWorker({super.key});

  @override
  State<AnimatedWorker> createState() => _AnimatedWorkerState();
}

class _AnimatedWorkerState extends State<AnimatedWorker>
    with SingleTickerProviderStateMixin {
  late AnimationController _workerController;

  @override
  void initState() {
    super.initState();
    _workerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _workerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bounceOffset = 6.0 * _workerController.value;
    final double rotateAngle = 0.3 * (_workerController.value - 0.5);

    return Transform.translate(
      offset: Offset(0, -bounceOffset),
      child: Transform.rotate(
        angle: rotateAngle,
        child: const Icon(
          Icons.directions_bike, // Bike icon representing rider/worker
          color:
              Color(0xFF0A235C), // Dark blue matching theme for high contrast
          size: 28,
        ),
      ),
    );
  }
}

class DashedPathPainter extends CustomPainter {
  final double progress;
  DashedPathPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(size.width * 0.42, size.height * 0.65);
    path.quadraticBezierTo(
      size.width * 0.60,
      size.height * 0.30,
      size.width * 0.78,
      size.height * 0.62,
    );

    final Path currentPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      final double length = metric.length * progress;
      double distance = 0.0;
      const double dashLength = 6.0;
      const double gapLength = 6.0;
      while (distance < length) {
        final double nextDistance = distance + dashLength;
        currentPath.addPath(
          metric.extractPath(
              distance, nextDistance < length ? nextDistance : length),
          Offset.zero,
        );
        distance = nextDistance + gapLength;
      }
    }
    canvas.drawPath(currentPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedPathPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class BottomPage2Animation extends StatefulWidget {
  final AnimationController controller;
  final AnimationController ambientController;
  const BottomPage2Animation({
    super.key,
    required this.controller,
    required this.ambientController,
  });

  @override
  State<BottomPage2Animation> createState() => _BottomPage2AnimationState();
}

class _BottomPage2AnimationState extends State<BottomPage2Animation> {
  Widget _buildDustParticle(double x, double y, double opacityFactor) {
    return Positioned(
      left: x - 3,
      top: y - 3,
      child: Opacity(
        opacity: (0.4 * opacityFactor).clamp(0.0, 1.0),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // Path coordinates for a gentle road hill curve
        final Path path = Path();
        path.moveTo(40, height * 0.75);
        path.quadraticBezierTo(
          width * 0.5,
          height * 0.45,
          width - 50,
          height * 0.78,
        );

        return AnimatedBuilder(
          animation:
              Listenable.merge([widget.controller, widget.ambientController]),
          builder: (context, child) {
            final double value = widget.controller.value;
            final double ambient = widget.ambientController.value;

            // Compute current position of the vehicle on the path
            Offset vehiclePosition = Offset(40, height * 0.75);
            double tiltAngle = 0.0;

            final List<PathMetric> metricsList = path.computeMetrics().toList();
            if (metricsList.isNotEmpty) {
              final PathMetric metric = metricsList.first;
              final double currentLength = metric.length * value;
              if (currentLength > 0) {
                final Tangent? tangent =
                    metric.getTangentForOffset(currentLength);
                if (tangent != null) {
                  vehiclePosition = tangent.position;
                  tiltAngle = tangent.angle;
                }
              }
            }

            // 1. Rocking and bobbing animation (Idle vs Driving)
            double busTilt = tiltAngle;
            double busYOffset = 0.0;

            if (value == 0.0) {
              // Idle motion
              busTilt = 0.02 * sin(4 * 3.14159 * ambient);
              busYOffset = 1.2 * sin(4 * 3.14159 * ambient).abs();
            } else {
              // Driving suspension bounce
              busYOffset = 3.0 * sin(value * 30).abs();
            }

            // 2. Headlight pulse opacity
            double headlightOpacity =
                0.2 + 0.35 * ((sin(2 * 3.14159 * ambient) + 1) / 2);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Dashed road path drawn progressively
                Positioned.fill(
                  child: CustomPaint(
                    painter: DashedPathPainter2(value),
                  ),
                ),

                // 2. Headlight beam/glow overlay ahead of the bus (front is on the right since flipped)
                Positioned(
                  left: vehiclePosition.dx + 16,
                  top: vehiclePosition.dy - 12 - busYOffset,
                  child: Opacity(
                    opacity: headlightOpacity,
                    child: Container(
                      width: 25,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFBBF24).withOpacity(0.8),
                            const Color(0xFFFBBF24).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Dust particles trailing behind the bus
                if (value > 0.05 && value < 0.95) ...[
                  _buildDustParticle(
                      vehiclePosition.dx - 22, vehiclePosition.dy + 4, 1.0),
                  _buildDustParticle(
                      vehiclePosition.dx - 30, vehiclePosition.dy + 6, 0.7),
                  _buildDustParticle(
                      vehiclePosition.dx - 38, vehiclePosition.dy + 7, 0.4),
                ],

                // 4. Bus/Car driving along the path (flipped to face forward)
                Positioned(
                  left: vehiclePosition.dx - 18,
                  top: vehiclePosition.dy - 28 - busYOffset,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(busTilt)
                      ..scale(-1.0, 1.0), // Flip horizontally to face right
                    child: const Icon(
                      Icons.directions_bus, // Bus icon
                      color: Color(0xFF0A235C), // Dark blue matching theme
                      size: 32,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DashedPathPainter2 extends CustomPainter {
  final double progress;
  DashedPathPainter2(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFCBD5E1) // Grey road dashed trail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(40, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      size.width - 50,
      size.height * 0.78,
    );

    final Path currentPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      final double length = metric.length * progress;
      double distance = 0.0;
      const double dashLength = 6.0;
      const double gapLength = 4.0;
      while (distance < length) {
        final double nextDistance = distance + dashLength;
        currentPath.addPath(
          metric.extractPath(
              distance, nextDistance < length ? nextDistance : length),
          Offset.zero,
        );
        distance = nextDistance + gapLength;
      }
    }
    canvas.drawPath(currentPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedPathPainter2 oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class BottomPage3Animation extends StatefulWidget {
  final AnimationController ambientController;
  const BottomPage3Animation({super.key, required this.ambientController});

  @override
  State<BottomPage3Animation> createState() => _BottomPage3AnimationState();
}

class _BottomPage3AnimationState extends State<BottomPage3Animation> {
  // Store the default positions of the 5 avatars
  final List<Offset> _avatarPositions = [
    const Offset(0.26, 0.45),
    const Offset(0.74, 0.35),
    const Offset(0.50, 0.18),
    const Offset(0.20, 0.15),
    const Offset(0.80, 0.65),
  ];

  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.support_agent,
    Icons.account_circle,
    Icons.engineering,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final Offset center = Offset(width / 2, height / 2);

        return AnimatedBuilder(
          animation: widget.ambientController,
          builder: (context, child) {
            final double ambient = widget.ambientController.value;

            // Highlight connection math:
            // Determine active index based on ambient progress (cycles 0 to 4)
            final int activeIndex = (ambient * 5).floor() % 5;
            // Connection line draws progressively in the middle 60% of each cycle
            final double cycleProgress = (ambient * 5) - (ambient * 5).floor();
            double connectionProgress = 0.0;
            if (cycleProgress > 0.1 && cycleProgress < 0.7) {
              connectionProgress = (cycleProgress - 0.1) / 0.6;
            } else if (cycleProgress >= 0.7) {
              connectionProgress = 1.0;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. Concentric radar waves
                ...List.generate(3, (index) {
                  final double startDelay = index * 0.33;
                  double progress = ambient - startDelay;
                  if (progress < 0.0) progress += 1.0;

                  final double scale = 0.2 + (0.8 * progress);
                  final double opacity = (1.0 - progress).clamp(0.0, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withOpacity(0.5),
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // 2. Rotating radar scan beam
                Positioned(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: RadarBeamPainter(2 * 3.14159 * ambient),
                  ),
                ),

                // 3. Highlighted connection lines
                ...List.generate(5, (index) {
                  final bool isActive = index == activeIndex;
                  if (!isActive) return const SizedBox.shrink();

                  // Calculate current floating offset of the active avatar
                  final double phaseShift = index * 0.2;
                  double progress = ambient - phaseShift;
                  if (progress < 0.0) progress += 1.0;
                  final double driftX = 6.0 * cos(2 * 3.14159 * progress);
                  final double driftY = 6.0 * sin(2 * 3.14159 * progress);

                  final Offset avatarOffset = Offset(
                    width * _avatarPositions[index].dx + driftX,
                    height * _avatarPositions[index].dy + driftY,
                  );

                  return Positioned.fill(
                    child: CustomPaint(
                      painter: ConnectionLinePainter(
                        start: center,
                        end: avatarOffset,
                        progress: connectionProgress,
                      ),
                    ),
                  );
                }),

                // 4. Central pulsing search icon
                Transform.scale(
                  scale: 1.0 + 0.12 * (1.0 - (2.0 * (ambient - 0.5).abs())),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A235C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A235C).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // 5. Floating profile avatars
                ...List.generate(5, (index) {
                  final Offset basePos = _avatarPositions[index];
                  final IconData icon = _avatarIcons[index];
                  final bool isActive = index == activeIndex;

                  // Float/drift logic
                  final double phaseShift = index * 0.2;
                  double progress = ambient - phaseShift;
                  if (progress < 0.0) progress += 1.0;
                  final double driftX = 6.0 * cos(2 * 3.14159 * progress);
                  final double driftY = 6.0 * sin(2 * 3.14159 * progress);

                  // Scale and opacity sways
                  final double avatarScale =
                      0.9 + 0.25 * (1.0 - (2.0 * (progress - 0.5).abs()));
                  final double opacity =
                      0.4 + 0.6 * (1.0 - (2.0 * (progress - 0.5).abs()));

                  // Highlight glow/checkmark variables
                  final double highlightScale = isActive
                      ? (1.0 + 0.15 * sin(3.14159 * connectionProgress))
                      : 1.0;
                  final Color iconColor = isActive
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF0A235C);

                  return Positioned(
                    left: width * basePos.dx + driftX - 15,
                    top: height * basePos.dy + driftY - 15,
                    child: Transform.scale(
                      scale: avatarScale * highlightScale,
                      child: Opacity(
                        opacity: opacity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Yellow glow circle behind active avatar
                            if (isActive && connectionProgress > 0.3)
                              Positioned(
                                left: -6,
                                top: -6,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFBBF24)
                                        .withOpacity(0.25),
                                  ),
                                ),
                              ),

                            // Main Icon container
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFF0A235C),
                                  width: isActive ? 2.0 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: iconColor,
                              ),
                            ),

                            // Small checkmark pulse at top-right
                            if (isActive && connectionProgress > 0.7)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBBF24),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class RadarBeamPainter extends CustomPainter {
  final double angle;
  RadarBeamPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFFBBF24).withOpacity(0.0),
          const Color(0xFFFBBF24).withOpacity(0.35),
        ],
        stops: const [0.75, 1.0],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant RadarBeamPainter oldDelegate) =>
      oldDelegate.angle != angle;
}

class ConnectionLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  ConnectionLinePainter(
      {required this.start, required this.end, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;
    final Paint paint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double limit = distance * progress;

    double current = 0.0;
    const double dashLength = 4.0;
    const double gapLength = 4.0;

    while (current < limit) {
      final double next = current + dashLength;
      final double tStart = current / distance;
      final double tEnd = (next < limit ? next : limit) / distance;

      canvas.drawLine(
        Offset(start.dx + dx * tStart, start.dy + dy * tStart),
        Offset(start.dx + dx * tEnd, start.dy + dy * tEnd),
        paint,
      );
      current = next + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionLinePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.progress != progress;
  }
}

class BottomPage4Animation extends StatefulWidget {
  final AnimationController ambientController;
  const BottomPage4Animation({super.key, required this.ambientController});

  @override
  State<BottomPage4Animation> createState() => _BottomPage4AnimationState();
}

class _BottomPage4AnimationState extends State<BottomPage4Animation> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double centerX = width / 2;
        final double centerY = height / 2;

        return AnimatedBuilder(
          animation: widget.ambientController,
          builder: (context, child) {
            final double ambient = widget.ambientController.value;

            // Storefront floating and breathing calculations
            final double bounce = 4.0 * sin(2 * 3.14159 * ambient);
            final double breatheScale =
                0.98 + 0.04 * ((sin(2 * 3.14159 * ambient) + 1) / 2);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Orbiting Ad Megaphone (0 deg phase)
                _buildOrbitingIcon(Icons.campaign, const Color(0xFFFBBF24), 0.0,
                    75.0, 25.0, centerX, centerY, ambient),

                // Orbiting Ad Shopping Bag (60 deg phase / 1.047 rad)
                _buildOrbitingIcon(Icons.local_mall, const Color(0xFF0A235C),
                    1.047, 82.0, 28.0, centerX, centerY, ambient),

                // Orbiting Ad Offer Tag (120 deg phase / 2.094 rad)
                _buildOrbitingIcon(Icons.local_offer, const Color(0xFFFBBF24),
                    2.094, 70.0, 22.0, centerX, centerY, ambient),

                // Orbiting Ad Campaign Icon (180 deg phase / 3.141 rad)
                _buildOrbitingIcon(Icons.analytics, const Color(0xFF0A235C),
                    3.141, 85.0, 30.0, centerX, centerY, ambient),

                // Orbiting Ad Gift Box (240 deg phase / 4.188 rad)
                _buildOrbitingIcon(Icons.card_giftcard, const Color(0xFFFBBF24),
                    4.188, 78.0, 24.0, centerX, centerY, ambient),

                // Orbiting Ad Notification Bell (300 deg phase / 5.236 rad)
                _buildOrbitingIcon(
                    Icons.notifications_active,
                    const Color(0xFF0A235C),
                    5.236,
                    80.0,
                    26.0,
                    centerX,
                    centerY,
                    ambient),

                // Central Storefront Icon (breathes and floats gently)
                Transform.translate(
                  offset: Offset(0, -bounce),
                  child: Transform.scale(
                    scale: breatheScale,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A235C),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A235C).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrbitingIcon(
    IconData icon,
    Color color,
    double phaseShift,
    double radX,
    double radY,
    double centerX,
    double centerY,
    double progress,
  ) {
    final double angle = (2 * 3.14159 * progress) + phaseShift;

    // Ellipse coordinates around the center
    final double dx = radX * cos(angle);
    final double dy = radY * sin(angle) - 10.0;

    // Depth simulation using sin(angle)
    // sin(angle) ranges from -1.0 to 1.0.
    // -1.0 is the top of the ellipse (behind), 1.0 is the bottom (in front).
    final double depthFactor = (sin(angle) + 1.0) / 2.0; // 0.0 to 1.0

    final double scale =
        0.65 + 0.55 * depthFactor; // scales between 0.65 and 1.2
    final double opacity =
        0.35 + 0.65 * depthFactor; // opacity between 0.35 and 1.0

    return Positioned(
      left: centerX + dx - 12,
      top: centerY + dy - 12,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                if (depthFactor > 0.6)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class StorefrontWidget extends StatelessWidget {
  final double size;
  final AnimationController? ambientController;
  const StorefrontWidget({
    super.key,
    this.size = 48,
    this.ambientController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientController ?? kAlwaysCompleteAnimation,
      builder: (context, child) {
        final double ambient = ambientController?.value ?? 0.0;

        // Awning sway rotation angle (gentle sway)
        final double swayAngle = 0.04 * sin(2 * 3.14159 * ambient);

        // Door sliding open/close logic
        // Open the door slightly between progress 0.2 and 0.45
        double doorSlide = 0.0;
        if (ambient > 0.2 && ambient < 0.45) {
          final double t = (ambient - 0.2) / 0.25;
          doorSlide = (size * 0.08) * sin(3.14159 * t);
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Building base (wall) color - White backing
              Positioned(
                bottom: 4,
                child: Container(
                  width: size * 0.72,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFF0A235C), width: 1.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),

              // 2. Door/Window inside base - Dark Blue with occasional sliding open interaction
              Positioned(
                bottom: 4,
                left: (size * 0.39) + doorSlide,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A235C),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                  ),
                ),
              ),

              // 3. Colored Awning roof - Yellow/Orange stripes with gentle sway swayAngle
              Positioned(
                top: size * 0.18,
                child: Transform.rotate(
                  angle: swayAngle,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: size * 0.88,
                    height: size * 0.28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24), // Yellow matching theme
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: const Color(0xFF0A235C), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 3.5,
                          color: index % 2 == 0
                              ? Colors.white.withOpacity(0.5)
                              : Colors.transparent,
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // 4. Shop outline overlay
              Icon(
                Icons.storefront,
                color: const Color(0xFF0A235C),
                size: size,
              ),
            ],
          ),
        );
      },
    );
  }
}

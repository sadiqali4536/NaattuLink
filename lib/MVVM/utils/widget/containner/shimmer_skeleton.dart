import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE2E8F0), // Base slate-200 (#F2F4F7 approximation)
                Color(0xFFFFFFFF), // Shimmer highlight (#FFFFFF)
                Color(0xFFE2E8F0), // Base slate-200
              ],
              stops: const [0.15, 0.5, 0.85],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final double translation = bounds.width * (slidePercent - 0.5) * 2.2;
    return Matrix4.translationValues(translation, 0.0, 0.0);
  }
}

class SkeletonPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const SkeletonPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7), // #F2F4F7 base color
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// 1. Header Skeleton
class HeaderSkeleton extends StatelessWidget {
  const HeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            // Circular profile
            const SkeletonPlaceholder(width: 48, height: 48, shape: BoxShape.circle),
            const SizedBox(width: 12),
            // Name/Location lines
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonPlaceholder(width: 110, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                SkeletonPlaceholder(width: 75, height: 10, borderRadius: 4),
              ],
            ),
            const Spacer(),
            // Menu/Notification icons
            const SkeletonPlaceholder(width: 38, height: 38, shape: BoxShape.circle),
            const SizedBox(width: 10),
            const SkeletonPlaceholder(width: 38, height: 38, shape: BoxShape.circle),
          ],
        ),
      ),
    );
  }
}

// 2. Search Bar Skeleton
class SearchBarSkeleton extends StatelessWidget {
  const SearchBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerEffect(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SkeletonPlaceholder(width: double.infinity, height: 50, borderRadius: 25),
      ),
    );
  }
}

// 3. Category Row Skeleton
class CategoryRowSkeleton extends StatelessWidget {
  const CategoryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SizedBox(
        height: 65,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 5,
          itemBuilder: (_, __) {
            return const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SkeletonPlaceholder(width: 90, height: 42, borderRadius: 20),
            );
          },
        ),
      ),
    );
  }
}

// 4. Carousel Banner Skeleton
class CarouselSkeleton extends StatelessWidget {
  const CarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SkeletonPlaceholder(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.175,
              borderRadius: 20,
            ),
          ),
          // Carousel dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SkeletonPlaceholder(width: 7, height: 7, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Expert Services Skeleton
class ExpertServicesSkeleton extends StatelessWidget {
  const ExpertServicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonPlaceholder(width: 140, height: 16, borderRadius: 6),
                SkeletonPlaceholder(width: 60, height: 14, borderRadius: 6),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (_, __) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card image
                      const SkeletonPlaceholder(width: 140, height: 95, borderRadius: 20),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonPlaceholder(width: 100, height: 12, borderRadius: 4),
                            SizedBox(height: 6),
                            SkeletonPlaceholder(width: 80, height: 10, borderRadius: 4),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SkeletonPlaceholder(width: 50, height: 12, borderRadius: 4),
                                SkeletonPlaceholder(width: 35, height: 12, borderRadius: 6),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 6. City Essentials Skeleton
class CityEssentialsSkeleton extends StatelessWidget {
  const CityEssentialsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SkeletonPlaceholder(width: 120, height: 16, borderRadius: 6),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 80,
              ),
              itemCount: 8,
              itemBuilder: (_, __) {
                return Column(
                  children: const [
                    SkeletonPlaceholder(width: 50, height: 50, shape: BoxShape.circle),
                    SizedBox(height: 6),
                    SkeletonPlaceholder(width: 55, height: 8, borderRadius: 4),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 7. Local Marketplace Skeleton
class MarketplaceSkeleton extends StatelessWidget {
  const MarketplaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SkeletonPlaceholder(width: 150, height: 16, borderRadius: 6),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 220,
              ),
              itemCount: 2,
              itemBuilder: (_, __) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      const SkeletonPlaceholder(width: double.infinity, height: 120, borderRadius: 20),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonPlaceholder(width: 100, height: 12, borderRadius: 4),
                            SizedBox(height: 6),
                            SkeletonPlaceholder(width: 60, height: 10, borderRadius: 4),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SkeletonPlaceholder(width: 50, height: 14, borderRadius: 4),
                                SkeletonPlaceholder(width: 40, height: 14, borderRadius: 4),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 8. Shop Spotlight Skeleton
class SpotlightSkeleton extends StatelessWidget {
  const SpotlightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SkeletonPlaceholder(width: 160, height: 16, borderRadius: 6),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              itemBuilder: (_, __) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SkeletonPlaceholder(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 140,
                    borderRadius: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 9. Community News Skeleton
class CommunityNewsSkeleton extends StatelessWidget {
  const CommunityNewsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SkeletonPlaceholder(width: 140, height: 16, borderRadius: 6),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  // News image
                  const SkeletonPlaceholder(width: 90, height: 75, borderRadius: 15),
                  const SizedBox(width: 12),
                  // News details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonPlaceholder(width: double.infinity, height: 12, borderRadius: 4),
                        SizedBox(height: 6),
                        SkeletonPlaceholder(width: 150, height: 12, borderRadius: 4),
                        SizedBox(height: 12),
                        SkeletonPlaceholder(width: 70, height: 8, borderRadius: 4),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 10. Trust Section Skeleton
class TrustSectionSkeleton extends StatelessWidget {
  const TrustSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              const SkeletonPlaceholder(width: 180, height: 14, borderRadius: 6),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  3,
                  (index) => Column(
                    children: const [
                      SkeletonPlaceholder(width: 32, height: 32, shape: BoxShape.circle),
                      SizedBox(height: 8),
                      SkeletonPlaceholder(width: 60, height: 8, borderRadius: 4),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 11. Bottom Navigation Skeleton
class BottomNavSkeleton extends StatelessWidget {
  const BottomNavSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            5,
            (index) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonPlaceholder(width: 24, height: 24, shape: BoxShape.circle),
                SizedBox(height: 6),
                SkeletonPlaceholder(width: 35, height: 8, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 12. Profile Page Skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const SkeletonPlaceholder(width: 70, height: 70, shape: BoxShape.circle),
                  const SizedBox(height: 15),
                  const SkeletonPlaceholder(width: 140, height: 20, borderRadius: 6),
                  const SizedBox(height: 8),
                  const SkeletonPlaceholder(width: 90, height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  const SkeletonPlaceholder(width: 110, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SkeletonPlaceholder(width: 80, height: 14, borderRadius: 4),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(4, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: const [
                        SkeletonPlaceholder(width: 24, height: 24, shape: BoxShape.circle),
                        SizedBox(width: 20),
                        SkeletonPlaceholder(width: 120, height: 14, borderRadius: 4),
                      ],
                    ),
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 13. Bookings List Skeleton
class BookingsListSkeleton extends StatelessWidget {
  const BookingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 145,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SkeletonPlaceholder(width: 80, height: 120, borderRadius: 10),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25, right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonPlaceholder(width: 140, height: 18, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonPlaceholder(width: 100, height: 12, borderRadius: 4),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              SkeletonPlaceholder(width: 16, height: 16, shape: BoxShape.circle),
                              SizedBox(width: 8),
                              SkeletonPlaceholder(width: 50, height: 10, borderRadius: 4),
                              SizedBox(width: 16),
                              SkeletonPlaceholder(width: 16, height: 16, shape: BoxShape.circle),
                              SizedBox(width: 8),
                              SkeletonPlaceholder(width: 40, height: 10, borderRadius: 4),
                            ],
                          ),
                          SizedBox(height: 10),
                          SkeletonPlaceholder(width: 60, height: 14, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 14. Service Card List Skeleton
class ServiceCardListSkeleton extends StatelessWidget {
  const ServiceCardListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const SkeletonPlaceholder(width: 95.5, height: 120, borderRadius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonPlaceholder(width: 130, height: 18, borderRadius: 4),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            SkeletonPlaceholder(width: 100, height: 14, borderRadius: 4),
                            SizedBox(width: 6),
                            SkeletonPlaceholder(width: 25, height: 12, borderRadius: 4),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            SkeletonPlaceholder(width: 30, height: 12, borderRadius: 4),
                            SizedBox(width: 8),
                            SkeletonPlaceholder(width: 40, height: 12, borderRadius: 4),
                            SizedBox(width: 8),
                            SkeletonPlaceholder(width: 50, height: 16, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 15. Chat History Skeleton
class ChatHistorySkeleton extends StatelessWidget {
  const ChatHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: 6,
        itemBuilder: (_, index) {
          final isMe = index % 2 == 0;
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe) ...[
                    const SkeletonPlaceholder(width: 30, height: 30, shape: BoxShape.circle),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 140 + (index % 3) * 30.0,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                        bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 16. Worker Dashboard Skeleton
class WorkerDashboardSkeleton extends StatelessWidget {
  const WorkerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonPlaceholder(width: 140, height: 18, borderRadius: 4),
                          SizedBox(height: 8),
                          SkeletonPlaceholder(width: 100, height: 12, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonPlaceholder(width: 80, height: 12, borderRadius: 4),
                          SizedBox(height: 6),
                          SkeletonPlaceholder(width: 90, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SkeletonPlaceholder(width: 80, height: 36, borderRadius: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 17. Worker Profile Skeleton
class WorkerProfileSkeleton extends StatelessWidget {
  const WorkerProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Row(
              children: [
                const SkeletonPlaceholder(width: 83, height: 83, shape: BoxShape.circle),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonPlaceholder(width: 150, height: 24, borderRadius: 6),
                    SizedBox(height: 8),
                    SkeletonPlaceholder(width: 100, height: 16, borderRadius: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            const SkeletonPlaceholder(width: 120, height: 16, borderRadius: 4),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 136,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 136,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),
            Container(
              height: 137,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              height: 53,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'home_card_system.dart';
import 'package:get/get.dart';

// Section theme enum — kept for backwards compatibility with themed_product_card.dart imports
enum SectionTheme {
  treats,
  brands,
  valueDeals,
  topPicks,
  nearby,
}

// Per-section colour offsets — stable; changing these recolours the whole app.
const int _kTreatsOffset    = 0;
const int _kValueDealsOffset = 1;
const int _kTopPicksOffset  = 2;
const int _kBrandsOffset    = 3;
const int _kNearbyOffset    = 4;

class ThemedProductSection extends StatelessWidget {
  /// The section heading. MUST NOT be changed dynamically.
  final String title;
  final List<StoreProductModel> products;
  final VoidCallback? onSeeAll;
  final bool isLoading;
  final SectionTheme theme;
  final String? username;

  const ThemedProductSection({
    super.key,
    required this.title,
    required this.products,
    required this.theme,
    this.onSeeAll,
    this.isLoading = false,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && products.isEmpty) return const SizedBox.shrink();

    switch (theme) {
      case SectionTheme.treats:
        return _buildTreatsSection();
      case SectionTheme.brands:
        return _buildBrandsSection();
      case SectionTheme.valueDeals:
        return _buildValueDealsSection();
      case SectionTheme.topPicks:
        return _buildTopPicksSection();
      case SectionTheme.nearby:
        return _buildNearbySection();
    }
  }

  // ── Shimmer helpers ─────────────────────────────────────────────────────────

  Widget _horizontalSkeleton({
    int count = 4,
    double height = 180,
    double width = 130,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: width,
          child: const ProductCardSkeleton(),
        ),
      ),
    );
  }

  // ── 1. New week, new treats ─────────────────────────────────────────────────
  // Heading is [title] — passed in and never renamed.
  // 2-day colour: offset 0

  Widget _buildTreatsSection() {
    final ct = HomeDailyCycle.biDayTheme(_kTreatsOffset);
    // Daily shuffle for fresh ordering
    final display = isLoading ? products : HomeDailyCycle.dailyShuffle(products);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
      decoration: BoxDecoration(
        color: ct.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ct.accent.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // title is always "New week, new treats" — username is appended
                    username != null && username!.isNotEmpty
                        ? '$title ${username!}'
                        : title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ct.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('🌟', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 185,
            child: isLoading
                ? _horizontalSkeleton(height: 185)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: display.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) => DynamicTreatsCard(
                      product: display[index],
                      theme: ct,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 2. Brands in Spotlight ──────────────────────────────────────────────────
  // Heading is "Brands in Spotlight" — never renamed.
  // 2-day colour: offset 3

  Widget _buildBrandsSection() {
    final ct = HomeDailyCycle.biDayTheme(_kBrandsOffset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DynamicSectionHeader(
          title: title, // always "Brands in Spotlight"
          titleColor: ct.textPrimary,
          subtitle: 'Featured products in the marketplace',
        ),
        SizedBox(
          height: 205,
          child: isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                            child: _ShimmerPlaceholder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        _ShimmerLine(width: double.infinity, height: 11),
                        SizedBox(height: 4),
                        _ShimmerLine(width: 80, height: 11),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length > 6 ? 6 : products.length,
                  itemBuilder: (_, index) => DynamicBrandCard(
                    product: products[index],
                    accentColor: ct.accent,
                  ),
                ),
        ),
      ],
    );
  }

  // ── 3. Top Value Deals ──────────────────────────────────────────────────────
  // Heading is "Top Value Deals" — never renamed.
  // 2-day colour: offset 1

  Widget _buildValueDealsSection() {
    final ct = HomeDailyCycle.biDayTheme(_kValueDealsOffset);
    final display = isLoading ? products : HomeDailyCycle.dailyShuffle(products);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ct.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ct.accent.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed heading — always "Top Value Deals"
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ct.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ct.badgeBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'DEALS',
                  style: TextStyle(
                    color: ct.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Great products at better prices',
            style: TextStyle(
              fontSize: 11,
              color: ct.textPrimary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 175,
            child: isLoading
                ? _horizontalSkeleton(height: 175, width: 130)
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: display.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) => DynamicValueDealCard(
                      product: display[index],
                      theme: ct,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 4. Today's Top Picks ────────────────────────────────────────────────────
  // Heading is "Today's Top Picks" — never renamed.
  // 2-day colour: offset 2

  Widget _buildTopPicksSection() {
    final ct = HomeDailyCycle.biDayTheme(_kTopPicksOffset);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DynamicSectionHeader(
          title: title, // always "Today's Top Picks"
          titleColor: ct.textPrimary,
          subtitle: 'Fresh picks for today',
        ),
        SizedBox(
          height: 180,
          child: isLoading
              ? _horizontalSkeleton(height: 180)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => DynamicTopPickCard(
                    product: products[index],
                    theme: ct,
                  ),
                ),
        ),
      ],
    );
  }

  // ── 5. Popular Near You ─────────────────────────────────────────────────────
  // Heading is "Popular Near You" — never renamed.
  // Hidden when products is empty (handled in build()).
  // 2-day colour: offset 4

  Widget _buildNearbySection() {
    final ct = HomeDailyCycle.biDayTheme(_kNearbyOffset);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ct.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ct.accent.withValues(alpha: 0.10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fixed heading — always "Popular Near You"
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ct.textPrimary,
                ),
              ),
              Icon(Icons.location_on_rounded, color: ct.accent, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Products from shops near you',
            style: TextStyle(
              fontSize: 11,
              color: ct.textPrimary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 16),
          isLoading
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, __) => const ProductCardSkeleton(),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length > 4 ? 4 : products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, index) => NearbyProductCard(
                    product: products[index],
                    theme: ct,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER PLACEHOLDERS (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: Color.lerp(
          const Color(0xFFE2E8F0),
          const Color(0xFFF1F5F9),
          _anim.value,
        ),
      ),
    );
  }
}

class _ShimmerLine extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerLine({required this.width, required this.height});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF1F5F9),
            _anim.value,
          ),
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import '../../product/product_details_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TWO-DAY VISUAL CYCLE
// ─────────────────────────────────────────────────────────────────────────────
//
// Headings are NEVER sourced from here. Only colours cycle.
//
// Each section gets a unique [sectionOffset] (0–4) so that on any given 2-day
// period every section shows a DIFFERENT palette colour.
// Two days later the whole set rotates by one step.
//
// Section offsets (keep these stable — changing them recolours the app):
//   treats     → 0
//   valueDeals → 1
//   topPicks   → 2
//   brands     → 3
//   nearby     → 4

class HomeCycleTheme {
  final Color background;
  final Color accent;
  final Color textPrimary;
  final Color badgeBackground;

  const HomeCycleTheme({
    required this.background,
    required this.accent,
    required this.textPrimary,
    required this.badgeBackground,
  });

  static const List<HomeCycleTheme> palette = [
    // 0 — soft gold
    HomeCycleTheme(
      background: Color(0xFFFFF8E1),
      accent: Color(0xFFF59E0B),
      textPrimary: Color(0xFF78350F),
      badgeBackground: Color(0xFFFDE68A),
    ),
    // 1 — soft blue
    HomeCycleTheme(
      background: Color(0xFFEFF6FF),
      accent: Color(0xFF3B82F6),
      textPrimary: Color(0xFF1E3A5F),
      badgeBackground: Color(0xFFBFDBFE),
    ),
    // 2 — soft purple
    HomeCycleTheme(
      background: Color(0xFFF5F3FF),
      accent: Color(0xFF8B5CF6),
      textPrimary: Color(0xFF3B0764),
      badgeBackground: Color(0xFFDDD6FE),
    ),
    // 3 — soft peach
    HomeCycleTheme(
      background: Color(0xFFFFF1F2),
      accent: Color(0xFFF43F5E),
      textPrimary: Color(0xFF881337),
      badgeBackground: Color(0xFFFECDD3),
    ),
    // 4 — soft mint
    HomeCycleTheme(
      background: Color(0xFFF0FDF4),
      accent: Color(0xFF10B981),
      textPrimary: Color(0xFF064E3B),
      badgeBackground: Color(0xFFA7F3D0),
    ),
  ];
}

class HomeDailyCycle {
  HomeDailyCycle._();

  /// Whole calendar days elapsed since 2026-01-01.
  /// Stable across every rebuild on the same day.
  static int get dayIndex {
    final today = DateTime.now();
    final epoch = DateTime(2026, 1, 1);
    return today.difference(epoch).inDays;
  }

  /// Changes every 2 calendar days.
  static int get biDayIndex => dayIndex ~/ 2;

  /// Returns the colour theme for a given section [sectionOffset].
  static HomeCycleTheme biDayTheme(int sectionOffset) {
    final index = (biDayIndex + sectionOffset) % HomeCycleTheme.palette.length;
    return HomeCycleTheme.palette[index];
  }

  /// Returns a new list with dynamic shuffling.
  /// Result changes every time it is called.
  static List<T> dailyShuffle<T>(List<T> items) {
    if (items.isEmpty) return items;
    final copy = List<T>.from(items);
    copy.shuffle(Random());
    return copy;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE HELPER
// ─────────────────────────────────────────────────────────────────────────────

enum ProductBadge { bigDeal, fewLeft, newProduct, topRated, featured, none }

class ProductBadgeHelper {
  ProductBadgeHelper._();

  static ProductBadge compute(StoreProductModel p) {
    if (p.hasDiscount && p.discountPercentage >= 50) return ProductBadge.bigDeal;
    if (p.stockQuantity > 0 && p.stockQuantity <= 5) return ProductBadge.fewLeft;
    if (_isNew(p)) return ProductBadge.newProduct;
    if (p.totalRatings >= 20 && p.averageRating >= 4.2) return ProductBadge.topRated;
    if (p.isFeatured) return ProductBadge.featured;
    return ProductBadge.none;
  }

  static bool _isNew(StoreProductModel p) {
    if (p.createdAt == null) return false;
    return DateTime.now().difference(p.createdAt!).inDays <= 14;
  }

  static String label(ProductBadge badge) {
    switch (badge) {
      case ProductBadge.bigDeal:   return 'BIG DEAL';
      case ProductBadge.fewLeft:   return 'FEW LEFT';
      case ProductBadge.newProduct: return 'NEW';
      case ProductBadge.topRated:  return 'TOP RATED';
      case ProductBadge.featured:  return 'FEATURED';
      case ProductBadge.none:      return '';
    }
  }

  static Color color(ProductBadge badge) {
    switch (badge) {
      case ProductBadge.bigDeal:   return const Color(0xFFDC2626);
      case ProductBadge.fewLeft:   return const Color(0xFFD97706);
      case ProductBadge.newProduct: return const Color(0xFF7C3AED);
      case ProductBadge.topRated:  return const Color(0xFF059669);
      case ProductBadge.featured:  return const Color(0xFF0F2E5A);
      case ProductBadge.none:      return Colors.transparent;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCT IMAGE HELPER
// ─────────────────────────────────────────────────────────────────────────────

String productImageUrl(StoreProductModel p) {
  if (p.coverImage.isNotEmpty) return p.coverImage;
  if (p.images.isNotEmpty) return p.images.first;
  return '';
}

class HomeProductImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const HomeProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http') || url.startsWith('https')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const _ImageFallback(),
      );
    }
    return const _ImageFallback();
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFFCBD5E1),
          size: 32,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SKELETON / SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
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
          borderRadius: BorderRadius.circular(widget.radius),
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

/// Skeleton card for 3-column Suggested grid or horizontal carousels.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            child: _ShimmerBox(
              width: double.infinity,
              height: double.infinity,
              radius: 14,
            ),
          ),
        ),
        SizedBox(height: 8),
        _ShimmerBox(width: double.infinity, height: 11, radius: 4),
        SizedBox(height: 5),
        _ShimmerBox(width: 60, height: 11, radius: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class DynamicSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onViewAll;

  const DynamicSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: titleColor ?? const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIP WIDGETS (badge + rating)
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  final int totalRatings;

  const _RatingChip({required this.rating, required this.totalRatings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
          if (totalRatings > 0) ...[
            const SizedBox(width: 2),
            Text(
              '($totalRatings)',
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STANDARD PRODUCT CARD  (3-col Suggested For You grid)
// ─────────────────────────────────────────────────────────────────────────────

class DynamicProductCard extends StatelessWidget {
  final StoreProductModel product;
  final bool showRating;
  final bool showBadge;

  const DynamicProductCard({
    super.key,
    required this.product,
    this.showRating = true,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final badge = ProductBadgeHelper.compute(product);
    final hasRating = showRating && product.totalRatings > 0;
    final imageUrl = productImageUrl(product);

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image + badge overlay
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: HomeProductImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  if (showBadge && badge != ProductBadge.none)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _BadgeChip(
                        label: ProductBadgeHelper.label(badge),
                        color: ProductBadgeHelper.color(badge),
                      ),
                    ),
                  if (hasRating)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: _RatingChip(
                        rating: product.averageRating,
                        totalRatings: product.totalRatings,
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '₹${product.sellingPrice.round()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          '₹${product.originalPrice.round()}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${product.discountPercentage}% OFF',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VALUE DEAL CARD  (for Top Value Deals horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class DynamicValueDealCard extends StatelessWidget {
  final StoreProductModel product;
  final HomeCycleTheme theme;

  const DynamicValueDealCard({
    super.key,
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final badge = ProductBadgeHelper.compute(product);
    final imageUrl = productImageUrl(product);

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                    ),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: HomeProductImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  if (badge != ProductBadge.none)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _BadgeChip(
                        label: ProductBadgeHelper.label(badge),
                        color: ProductBadgeHelper.color(badge),
                      ),
                    ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.badgeBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage}%',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${product.sellingPrice.round()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      '₹${product.originalPrice.round()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND / FEATURED CARD  (for Brands in Spotlight horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class DynamicBrandCard extends StatelessWidget {
  final StoreProductModel product;
  final Color? accentColor;

  const DynamicBrandCard({
    super.key,
    required this.product,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = productImageUrl(product);
    final label = product.brand.isNotEmpty
        ? product.brand
        : product.categoryName.isNotEmpty
            ? product.categoryName
            : product.productName;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: HomeProductImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  // AD badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Shop Now',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor ?? const Color(0xFF0F2E5A),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: accentColor ?? const Color(0xFF0F2E5A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY PRODUCT CARD  (for Popular Near You section)
// ─────────────────────────────────────────────────────────────────────────────

class NearbyProductCard extends StatelessWidget {
  final StoreProductModel product;
  final HomeCycleTheme theme;

  const NearbyProductCard({
    super.key,
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = productImageUrl(product);
    // sellerId used as shop label fallback if no brand present
    final shopLabel = product.brand.isNotEmpty
        ? product.brand
        : product.categoryName.isNotEmpty
            ? product.categoryName
            : 'Local Shop';

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: HomeProductImage(
                    url: imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '₹${product.sellingPrice.round()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${product.discountPercentage}% OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 11, color: theme.accent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shopLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textPrimary.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREATS CAROUSEL CARD  (for New week, new treats horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class DynamicTreatsCard extends StatelessWidget {
  final StoreProductModel product;
  final HomeCycleTheme theme;

  const DynamicTreatsCard({
    super.key,
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = productImageUrl(product);
    final badge = ProductBadgeHelper.compute(product);

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: HomeProductImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  if (badge != ProductBadge.none)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _BadgeChip(
                        label: ProductBadgeHelper.label(badge),
                        color: ProductBadgeHelper.color(badge),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${product.sellingPrice.round()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (product.hasDiscount)
                    Row(
                      children: [
                        Text(
                          '₹${product.originalPrice.round()}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.discountPercentage}% OFF',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP PICKS CARD  (for Today's Top Picks horizontal list)
// ─────────────────────────────────────────────────────────────────────────────

class DynamicTopPickCard extends StatelessWidget {
  final StoreProductModel product;
  final HomeCycleTheme theme;

  const DynamicTopPickCard({
    super.key,
    required this.product,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = productImageUrl(product);
    final hasRating = product.totalRatings > 0;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: HomeProductImage(
                        url: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                  if (hasRating)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: _RatingChip(
                        rating: product.averageRating,
                        totalRatings: product.totalRatings,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '₹${product.sellingPrice.round()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.textPrimary,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          '₹${product.originalPrice.round()}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

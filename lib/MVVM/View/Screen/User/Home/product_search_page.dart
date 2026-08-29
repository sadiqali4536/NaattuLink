import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controller/user/product_search_controller.dart';
import '../product/product_details_page.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ProductSearchController controller;

  static const _primary = Color(0xFF0F2E5A);

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProductSearchController(), permanent: false);
  }

  @override
  void dispose() {
    controller.searchQuery.value = '';
    controller.searchResults.clear();
    _searchController.dispose();
    Get.delete<ProductSearchController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return _buildLoadingGrid();
              final query = controller.searchQuery.value.trim();
              if (query.isEmpty) return _buildEmptyState();
              if (controller.searchResults.isEmpty) {
                return _buildNoResultsState(query);
              }
              return _buildResultsGrid(controller.searchResults);
            }),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH HEADER ───────────────────────────────────────────────────────────
  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 12,
        bottom: 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_new, size: 20, color: _primary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search, color: Color(0xFF9AA5B4), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        hintText: 'Search products, brands...',
                        hintStyle:
                            TextStyle(color: Color(0xFF9AA5B4), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => controller.searchQuery.value = val,
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          controller.saveSearch(val);
                        }
                      },
                    ),
                  ),
                  Obx(() {
                    if (controller.searchQuery.value.isNotEmpty) {
                      return GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          controller.searchQuery.value = '';
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close,
                              color: Color(0xFF9AA5B4), size: 18),
                        ),
                      );
                    } else {
                      return const SizedBox(width: 12);
                    }
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ─── RESULTS GRID ────────────────────────────────────────────────────────────
  Widget _buildResultsGrid(List<DocumentSnapshot> results) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedBanner(),
          const SizedBox(height: 16),
          _buildSellingFastSection(),
          const SizedBox(height: 16),
          _buildSponsoredCard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Obx(() => Text(
                  '${controller.searchResults.length} results for "${controller.searchQuery.value.trim()}"',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                )),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Column(
              children: _buildDynamicLayoutList(results),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicLayoutList(List<DocumentSnapshot> results) {
    List<Widget> gridItems = [];
    List<DocumentSnapshot> pendingPair = [];

    for (int i = 0; i < results.length; i++) {
      final doc = results[i];
      final data = doc.data() as Map<String, dynamic>;
      final name = data['productName'] ?? data['title'] ?? '';

      // If the product name is long (> 40 chars), show as a horizontal full-width card
      if (name.length > 40) {
        if (pendingPair.isNotEmpty) {
          gridItems.add(SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildProductCard(
                        pendingPair[0].data() as Map<String, dynamic>,
                        pendingPair[0].id)),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()), // Empty space
              ],
            ),
          ));
          gridItems.add(const SizedBox(height: 10));
          pendingPair.clear();
        }
        gridItems.add(_buildHorizontalProductCard(data, doc.id));
        gridItems.add(const SizedBox(height: 10));
      } else {
        pendingPair.add(doc);
        if (pendingPair.length == 2) {
          gridItems.add(SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildProductCard(
                        pendingPair[0].data() as Map<String, dynamic>,
                        pendingPair[0].id)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildProductCard(
                        pendingPair[1].data() as Map<String, dynamic>,
                        pendingPair[1].id)),
              ],
            ),
          ));
          gridItems.add(const SizedBox(height: 10));
          pendingPair.clear();
        }
      }
    }

    // Flush any remaining item
    if (pendingPair.isNotEmpty) {
      gridItems.add(SizedBox(
        height: 250,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _buildProductCard(
                    pendingPair[0].data() as Map<String, dynamic>,
                    pendingPair[0].id)),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ));
    }

    return gridItems;
  }

  Widget _buildFeaturedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 180,
      child: Stack(
        children: [
          // Background Image
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?w=600&auto=format&fit=crop&q=60'), // Placeholder TV
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.centerLeft,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nitro Gaming 4K OLED TV',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'It only sells out',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 16), // Space for overlapping cards
                ],
              ),
            ),
          ),
          // Ad Badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Ad',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ),
          // Overlapping Small Cards
        ],
      ),
    );
  }

  Widget _buildSellingFastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selling Fast',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    'Shop now',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE), // Light blue
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: Obx(() {
            if (controller.allActiveProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = controller.allActiveProducts.take(5).toList();
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final doc = products[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildSellingFastCard(data, doc.id);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSellingFastCard(Map<String, dynamic> data, String docId) {
    final name = data['productName'] ?? data['title'] ?? 'Unknown';

    final List<dynamic> images = data['images'] ?? [];
    String imageUrl = images.isNotEmpty
        ? images.first.toString()
        : (data['imageUrl']?.toString() ?? '');

    double price = (data['price'] as num?)?.toDouble() ?? 0.0;
    double discountPrice = (data['discountPrice'] as num?)?.toDouble() ?? 0.0;
    if (discountPrice <= 0) discountPrice = price;

    double rating = 0.0;
    if (data['rating'] is Map) {
      rating = ((data['rating'] as Map)['average'] as num?)?.toDouble() ?? 0.0;
    } else if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    }

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImg())
                      : _placeholderImg(),
                ),
                if (rating > 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.green, size: 8),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (price > discountPrice)
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough),
                        ),
                      if (price > discountPrice) const SizedBox(width: 4),
                      Text(
                        '₹${discountPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Hot Deal',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SPONSORED SUGGESTION',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=600&auto=format&fit=crop&q=60'), // Apple Watch placeholder
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.favorite_border,
                    color: Colors.grey, size: 18),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Tech Smartwatch Pro Series 5 - Midnight Black',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0), // Blue badge
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('4.8',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 4),
                        const Text('(1.2k)',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Feature chips
                    Row(
                      children: [
                        _buildFeatureChip('Heart Rate'),
                        const SizedBox(width: 4),
                        _buildFeatureChip('GPS'),
                        const SizedBox(width: 4),
                        _buildFeatureChip('Waterproof'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'WOW! ₹1,999',
                          style: TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹2,999',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Delivery by Tomorrow',
                        style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
    );
  }

  Widget _buildHorizontalProductCard(Map<String, dynamic> data, String docId) {
    final name = data['productName'] ?? data['title'] ?? 'Unknown Product';
    final brand = data['brand'] ?? '';

    // Image
    final List<dynamic> images = data['images'] ?? [];
    String imageUrl = images.isNotEmpty
        ? images.first.toString()
        : (data['imageUrl']?.toString() ?? '');

    // Pricing
    double originalPrice = 0.0;
    double discountedPrice = 0.0;
    if (data.containsKey('pricing') && data['pricing'] is Map) {
      final p = data['pricing'] as Map;
      originalPrice = (p['originalPrice'] as num?)?.toDouble() ?? 0.0;
      discountedPrice = (p['discountedPrice'] as num?)?.toDouble() ?? 0.0;
    } else {
      originalPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
      discountedPrice = (data['discountPrice'] as num?)?.toDouble() ?? 0.0;
    }
    if (discountedPrice <= 0) discountedPrice = originalPrice;
    final hasDiscount = originalPrice > discountedPrice && discountedPrice > 0;
    final discountPercent = hasDiscount
        ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
        : 0;

    // Rating
    double rating = 0.0;
    int reviewCount = 0;
    if (data['rating'] is Map) {
      final rm = data['rating'] as Map;
      rating = (rm['average'] as num?)?.toDouble() ?? 0.0;
      reviewCount = (rm['totalReviews'] as num?)?.toInt() ?? 0;
    } else if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    }

    final stock = (data['stockQuantity'] as num?)?.toInt() ??
        (data['stock'] as num?)?.toInt() ??
        0;
    final inStock =
        stock > 0 || data['status']?.toString().toLowerCase() == 'active';

    return GestureDetector(
      onTap: () {
        controller.saveSearch(name);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: StoreProductModel.fromMap(data, docId),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImg())
                          : _placeholderImg(),
                    ),
                  ),
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.favorite_border,
                        color: Colors.grey, size: 18),
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0), // Blue badge
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      Text('($reviewCount)',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildFeatureChip(brand.toUpperCase()),
                  ],
                  const SizedBox(height: 8),
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₹${discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_downward,
                            color: Colors.green, size: 10),
                        Text(
                          '$discountPercent%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (inStock && stock <= 5 && stock > 0) ...[
                    const SizedBox(height: 2),
                    const Text('Only few left',
                        style: TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String docId) {
    final name = data['productName'] ?? data['title'] ?? 'Unknown Product';
    final brand = data['brand'] ?? '';

    // Image
    final List<dynamic> images = data['images'] ?? [];
    String imageUrl = '';
    if (images.isNotEmpty) {
      imageUrl = images.first.toString();
    } else {
      imageUrl = (data['imageUrl']?.toString() ?? '').isNotEmpty
          ? data['imageUrl']
          : (data['coverImage']?.toString() ?? '');
    }

    // Pricing
    double originalPrice = 0.0;
    double discountedPrice = 0.0;
    if (data.containsKey('pricing') && data['pricing'] is Map) {
      final p = data['pricing'] as Map;
      originalPrice = (p['originalPrice'] as num?)?.toDouble() ?? 0.0;
      discountedPrice = (p['discountedPrice'] as num?)?.toDouble() ?? 0.0;
    } else {
      originalPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
      discountedPrice = (data['discountPrice'] as num?)?.toDouble() ?? 0.0;
    }
    if (discountedPrice <= 0) discountedPrice = originalPrice;
    final hasDiscount = originalPrice > discountedPrice && discountedPrice > 0;
    final discountPercent = hasDiscount
        ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
        : 0;
    // Rating
    double rating = 0.0;
    int reviewCount = 0;
    if (data['rating'] is Map) {
      final rm = data['rating'] as Map;
      rating = (rm['average'] as num?)?.toDouble() ?? 0.0;
      reviewCount = (rm['totalReviews'] as num?)?.toInt() ?? 0;
    } else if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    }

    // Stock
    final stock = (data['stockQuantity'] as num?)?.toInt() ??
        (data['stock'] as num?)?.toInt() ??
        0;
    final inStock =
        stock > 0 || data['status']?.toString().toLowerCase() == 'active';

    return GestureDetector(
      onTap: () {
        controller.saveSearch(name);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(
              product: StoreProductModel.fromMap(data, docId),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section ──
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImg(),
                            )
                          : _placeholderImg(),
                    ),
                  ),
                  // Discount badge (moved to price row, but keeping overlay for out of stock)
                  // Out of stock overlay
                  if (!inStock)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info Section ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.isNotEmpty) ...[
                      Text(
                        brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFFFFB300), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '($reviewCount)',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_downward,
                              color: Colors.green, size: 10),
                          Text(
                            '$discountPercent%',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (inStock && stock <= 5 && stock > 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Only few left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828), // A nice dark red
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY / SUGGESTION STATE ────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recent Searches ──
          Obx(() {
            if (controller.recentSearches.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Text(
                    'Recent Searches',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.recentSearches.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final s = controller.recentSearches[index];
                      return GestureDetector(
                        onTap: () {
                          _searchController.text = s;
                          controller.searchQuery.value = s;
                          controller.saveSearch(s);
                        },
                        onLongPress: () {
                          // Allow deletion on long press since we removed the X
                          controller.removeSearch(s);
                        },
                        child: SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[300]!),
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.grey,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[100], thickness: 8),
              ],
            );
          }),

          // ── Recommended Stores For You ──
          if (controller.allActiveProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Text(
                'Recommended Stores For You',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _getDynamicRecommendations(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  List<Widget> _getDynamicRecommendations() {
    final products = controller.allActiveProducts;
    final Map<String, String> recommended = {};

    // Find unique categories with images
    for (var doc in products) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final category =
          (data['category'] ?? data['categoryName'] ?? '').toString().trim();
      if (category.isNotEmpty && !recommended.containsKey(category)) {
        final List<dynamic> images = data['images'] ?? [];
        String imageUrl = '';
        if (images.isNotEmpty) {
          imageUrl = images.first.toString();
        } else {
          imageUrl = (data['imageUrl']?.toString() ?? '').isNotEmpty
              ? data['imageUrl']
              : (data['coverImage']?.toString() ?? '');
        }
        if (imageUrl.isNotEmpty) {
          recommended[category] = imageUrl;
        }
      }
      if (recommended.length >= 3) break;
    }

    if (recommended.isEmpty) return [const SizedBox.shrink()];

    final widgets = <Widget>[];
    int count = 0;
    recommended.forEach((category, imageUrl) {
      widgets.add(
          _buildDynamicRecommendedCard(title: category, imageUrl: imageUrl));
      if (count < 2) widgets.add(const SizedBox(width: 12));
      count++;
    });

    // If there are fewer than 3 items, add empty Expanded widgets to pad the row
    // so the existing items don't stretch to fill the entire width.
    while (count < 3) {
      widgets.add(const Expanded(child: SizedBox.shrink()));
      if (count < 2) widgets.add(const SizedBox(width: 12));
      count++;
    }

    return widgets;
  }

  Widget _buildDynamicRecommendedCard(
      {required String title, required String imageUrl}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _searchController.text = title;
          controller.searchQuery.value = title;
          controller.saveSearch(title);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 70,
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── NO RESULTS STATE ─────────────────────────────────────────────────────────
  Widget _buildNoResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Graphic
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Yellow document
                  Positioned(
                    right: 20,
                    top: 10,
                    child: Icon(
                      Icons.article,
                      size: 110,
                      color: Colors.amber[500],
                    ),
                  ),
                  // Phone
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      width: 64,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.red[400]!, width: 2),
                          ),
                          child: Icon(Icons.priority_high,
                              color: Colors.red[400], size: 18),
                        ),
                      ),
                    ),
                  ),
                  // Blue Magnifying glass
                  const Positioned(
                    right: 15,
                    bottom: 25,
                    child: Icon(
                      Icons.search,
                      size: 65,
                      color: Color(0xFF2956D3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sorry, no results found!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your spelling or search again with a\ndifferent word',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                controller.searchQuery.value = '';
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2956D3), // Matching blue
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Search Again',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOADING GRID ─────────────────────────────────────────────────────────────
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.80,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 60, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[200]),
                const SizedBox(height: 4),
                Container(height: 10, width: 100, color: Colors.grey[200]),
                const SizedBox(height: 10),
                Container(height: 14, width: 70, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImg() {
    return Container(
      height: 155,
      width: double.infinity,
      color: const Color(0xFFF0F4FF),
      child: const Icon(Icons.shopping_bag_outlined,
          color: Color(0xFFBFD3F8), size: 48),
    );
  }
}

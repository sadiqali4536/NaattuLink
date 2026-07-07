import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swiftclean_project/MVVM/model/models/product_model.dart';

class RecommendationController extends GetxController {
  static RecommendationController get to => Get.find();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  // Observable lists for the 14 home screen sections
  final recentlyViewed = <ProductModel>[].obs;
  final basedOnSearches = <ProductModel>[].obs;
  final continueShopping = <ProductModel>[].obs; // Cart items
  final recommendedForYou = <ProductModel>[].obs;
  final trendingNearYou = <ProductModel>[].obs;
  final homemadeCakes = <ProductModel>[].obs;
  final fashionPicks = <ProductModel>[].obs;
  final watches = <ProductModel>[].obs;
  final electronics = <ProductModel>[].obs;
  final carsAndBikes = <ProductModel>[].obs;
  final localBusinesses = <ProductModel>[].obs;
  final bestSellers = <ProductModel>[].obs;
  final flashSale = <ProductModel>[].obs;
  final newArrivals = <ProductModel>[].obs;

  final isLoading = false.obs;
  final isColdStart = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCachedRecommendations();
    fetchRecommendations();
    // Listen to auth state changes to re-fetch when user logs in/out
    _auth.authStateChanges().listen((user) {
      fetchRecommendations();
    });
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  // ── USER BEHAVIOR TRACKING METHODS ──────────────────────────────────────────

  Future<void> trackSearch(String keyword, String category) async {
    final userId = _currentUserId;
    if (userId == null || keyword.trim().isEmpty) return;

    try {
      await _firestore
          .collection('user_search_history')
          .doc(userId)
          .collection('searchId')
          .add({
        'keyword': keyword.trim(),
        'category': category.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Also increment category clicks implicitly as interest
      if (category.isNotEmpty) {
        await trackCategoryClick(category);
      }
    } catch (e) {
      print('Error tracking search: $e');
    }
  }

  Future<void> trackProductView(String productId) async {
    final userId = _currentUserId;
    if (userId == null || productId.isEmpty) return;

    try {
      await _firestore
          .collection('recently_viewed')
          .doc(userId)
          .collection('productId')
          .doc(productId)
          .set({
        'viewedAt': FieldValue.serverTimestamp(),
      });
      fetchRecommendations(); // Update recommendations dynamically
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  Future<void> trackWishlist(String productId, bool isAdded) async {
    final userId = _currentUserId;
    if (userId == null || productId.isEmpty) return;

    try {
      final docRef = _firestore
          .collection('wishlist')
          .doc(userId)
          .collection('productId')
          .doc(productId);

      if (isAdded) {
        await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      } else {
        await docRef.delete();
      }
      fetchRecommendations();
    } catch (e) {
      print('Error tracking wishlist: $e');
    }
  }

  Future<void> trackCart(String productId, bool isAdded) async {
    final userId = _currentUserId;
    if (userId == null || productId.isEmpty) return;

    try {
      final docRef = _firestore
          .collection('cart')
          .doc(userId)
          .collection('productId')
          .doc(productId);

      if (isAdded) {
        await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      } else {
        await docRef.delete();
      }
      fetchRecommendations();
    } catch (e) {
      print('Error tracking cart: $e');
    }
  }

  Future<void> trackPurchase(List<String> productIds, double total) async {
    final userId = _currentUserId;
    if (userId == null || productIds.isEmpty) return;

    try {
      await _firestore.collection('orders').add({
        'userId': userId,
        'products': productIds,
        'total': total,
        'orderedAt': FieldValue.serverTimestamp(),
      });
      fetchRecommendations();
    } catch (e) {
      print('Error tracking purchase: $e');
    }
  }

  Future<void> trackCategoryClick(String category) async {
    final userId = _currentUserId;
    if (userId == null || category.trim().isEmpty) return;

    try {
      final docRef = _firestore
          .collection('category_clicks')
          .doc(userId)
          .collection('category')
          .doc(category.trim());

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          transaction.set(docRef, {'count': 1});
        } else {
          final currentCount = snapshot.get('count') ?? 0;
          transaction.update(docRef, {'count': currentCount + 1});
        }
      });
    } catch (e) {
      print('Error tracking category click: $e');
    }
  }

  // ── RECOMMENDATION ENGINE ALGORITHM ─────────────────────────────────────────

  Future<void> fetchRecommendations() async {
    final userId = _currentUserId;
    if (userId == null) {
      isColdStart.value = true;
      await _fetchColdStartProducts();
      return;
    }

    isLoading.value = true;
    try {
      // 1. Fetch user activities from Firestore in parallel
      final futures = await Future.wait([
        _firestore.collection('orders').where('userId', isEqualTo: userId).get(),
        _firestore.collection('wishlist').doc(userId).collection('productId').get(),
        _firestore.collection('user_search_history').doc(userId).collection('searchId').orderBy('timestamp', descending: true).limit(20).get(),
        _firestore.collection('recently_viewed').doc(userId).collection('productId').orderBy('viewedAt', descending: true).limit(20).get(),
        _firestore.collection('cart').doc(userId).collection('productId').get(),
        _firestore.collection('category_clicks').doc(userId).collection('category').get(),
        _firestore.collection('products').limit(150).get(), // Load pool of products to rank
      ]);

      final ordersSnap = futures[0] as QuerySnapshot;
      final wishlistSnap = futures[1] as QuerySnapshot;
      final searchSnap = futures[2] as QuerySnapshot;
      final viewedSnap = futures[3] as QuerySnapshot;
      final cartSnap = futures[4] as QuerySnapshot;
      final clicksSnap = futures[5] as QuerySnapshot;
      final productsSnap = futures[6] as QuerySnapshot;

      // Map products
      final allProducts = productsSnap.docs.map((doc) {
        return ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      if (allProducts.isEmpty) {
        isLoading.value = false;
        return;
      }

      // Check if user has any active history. If not, it is a Cold Start.
      final hasHistory = ordersSnap.docs.isNotEmpty ||
          wishlistSnap.docs.isNotEmpty ||
          searchSnap.docs.isNotEmpty ||
          viewedSnap.docs.isNotEmpty ||
          cartSnap.docs.isNotEmpty ||
          clicksSnap.docs.isNotEmpty;

      isColdStart.value = !hasHistory;

      if (isColdStart.value) {
        await _fetchColdStartProducts(productsPool: allProducts);
        isLoading.value = false;
        return;
      }

      // Extract raw sets for specific categories
      final purchasedIds = <String>{};
      for (var doc in ordersSnap.docs) {
        final productsList = doc.get('products') as List<dynamic>?;
        if (productsList != null) {
          purchasedIds.addAll(productsList.map((e) => e.toString()));
        }
      }

      final wishlistIds = wishlistSnap.docs.map((doc) => doc.id).toSet();
      final cartIds = cartSnap.docs.map((doc) => doc.id).toSet();
      final viewedIds = viewedSnap.docs.map((doc) => doc.id).toSet();

      // Category click map
      final categoryClickMap = <String, int>{};
      for (var doc in clicksSnap.docs) {
        categoryClickMap[doc.id.toLowerCase()] = doc.get('count') as int? ?? 0;
      }

      // Search keyword list and categories
      final searchKeywords = <String>[];
      final searchCategories = <String>[];
      for (var doc in searchSnap.docs) {
        final keyword = (doc.get('keyword') ?? '').toString().toLowerCase();
        final category = (doc.get('category') ?? '').toString().toLowerCase();
        if (keyword.isNotEmpty) searchKeywords.add(keyword);
        if (category.isNotEmpty) searchCategories.add(category);
      }

      // Map to expand search terms (Rules: Watch -> Smart Watches, Men's Fashion, Electronics)
      final relatedCategoriesFromSearch = <String>{};
      for (var keyword in searchKeywords) {
        if (keyword.contains('cake')) {
          relatedCategoriesFromSearch.addAll(['bakery products', 'greeting cards', 'gift boxes', 'cake accessories', 'cake shops', 'homemade cakes']);
        } else if (keyword.contains('watch')) {
          relatedCategoriesFromSearch.addAll(['smart watches', 'men\'s fashion', 'electronics', 'watch accessories', 'watches']);
        } else if (keyword.contains('car') || keyword.contains('bike')) {
          relatedCategoriesFromSearch.addAll(['used cars', 'bikes', 'spare parts', 'nearby dealers', 'cars']);
        }
      }

      // Compute Recommendation Scores for each product
      final productScores = <String, double>{};
      for (var product in allProducts) {
        double score = 0.0;
        final category = product.category.toLowerCase().trim();
        final subCategory = product.subCategory.toLowerCase().trim();
        final prodId = product.productId;

        // 1. Purchase History (40% Weight)
        if (purchasedIds.contains(prodId)) {
          score += 40.0;
        } else {
          // If in the same category of any purchased item
          final hasPurchasedSameCat = allProducts
              .where((p) => purchasedIds.contains(p.productId))
              .any((p) => p.category.toLowerCase() == category);
          if (hasPurchasedSameCat) score += 20.0;
        }

        // 2. Wishlist (20% Weight)
        if (wishlistIds.contains(prodId)) {
          score += 20.0;
        } else {
          final hasWishlistedSameCat = allProducts
              .where((p) => wishlistIds.contains(p.productId))
              .any((p) => p.category.toLowerCase() == category);
          if (hasWishlistedSameCat) score += 10.0;
        }

        // 3. Search History (15% Weight)
        if (searchCategories.contains(category)) {
          score += 15.0;
        }
        // Apply rule-based related category boost
        if (relatedCategoriesFromSearch.contains(category)) {
          score += 10.0;
        }
        // Match product title / description with search keywords
        final matchCount = searchKeywords.where((kw) =>
            product.title.toLowerCase().contains(kw) ||
            product.description.toLowerCase().contains(kw)).length;
        score += matchCount * 5.0;

        // 4. Recently Viewed (10% Weight)
        if (viewedIds.contains(prodId)) {
          score += 10.0;
        } else {
          final hasViewedSameCat = allProducts
              .where((p) => viewedIds.contains(p.productId))
              .any((p) => p.category.toLowerCase() == category);
          if (hasViewedSameCat) score += 5.0;
        }

        // 5. Cart Items (5% Weight)
        if (cartIds.contains(prodId)) {
          score += 5.0;
        }

        // 6. Category Clicks (5% Weight)
        final clickCount = categoryClickMap[category] ?? 0;
        score += (clickCount > 5 ? 5.0 : clickCount.toDouble());

        // 7. Trending Products Boost (5% Weight)
        if (product.isTrending) {
          score += 5.0;
        }

        // Rating bias (Favor higher rated items)
        score *= (0.5 + (product.rating / 10.0));

        productScores[prodId] = score;
      }

      // Rank products by score
      allProducts.sort((a, b) {
        final scoreA = productScores[a.productId] ?? 0.0;
        final scoreB = productScores[b.productId] ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

      // ── Populate the 14 sections ──

      // 1. Recently Viewed
      recentlyViewed.value = allProducts.where((p) => viewedIds.contains(p.productId)).take(15).toList();

      // 2. Based on Your Searches
      basedOnSearches.value = allProducts.where((p) {
        final cat = p.category.toLowerCase();
        return searchCategories.contains(cat) || relatedCategoriesFromSearch.contains(cat);
      }).take(15).toList();

      // 3. Continue Shopping (items in cart)
      continueShopping.value = allProducts.where((p) => cartIds.contains(p.productId)).take(15).toList();

      // 4. Recommended for You (top ranked items, excluding cart items)
      recommendedForYou.value = allProducts.where((p) => !cartIds.contains(p.productId)).take(20).toList();

      // 5. Trending Near You
      trendingNearYou.value = allProducts.where((p) => p.isTrending).take(15).toList();

      // 6. Homemade Cakes
      homemadeCakes.value = allProducts.where((p) => p.category.toLowerCase() == 'homemade cakes').take(15).toList();

      // 7. Fashion Picks (Fashion & Shoes)
      fashionPicks.value = allProducts.where((p) =>
          p.category.toLowerCase() == 'men\'s, women\'s & kids fashion' ||
          p.category.toLowerCase() == 'shoes & footwear').take(15).toList();

      // 8. Watches
      watches.value = allProducts.where((p) => p.category.toLowerCase() == 'watches').take(15).toList();

      // 9. Electronics
      electronics.value = allProducts.where((p) => p.category.toLowerCase() == 'electronics').take(15).toList();

      // 10. Cars & Bikes
      carsAndBikes.value = allProducts.where((p) =>
          p.category.toLowerCase() == 'cars' ||
          p.category.toLowerCase() == 'bikes').take(15).toList();

      // 11. Local Businesses
      localBusinesses.value = allProducts.where((p) => p.category.toLowerCase() == 'local businesses & services').take(15).toList();

      // 12. Best Sellers
      bestSellers.value = allProducts.where((p) => p.isBestSeller).take(15).toList();

      // 13. Flash Sale (e.g. top items by rating/discount or random mix)
      flashSale.value = allProducts.where((p) => p.isBestSeller || p.isTrending).take(15).toList();

      // 14. New Arrivals
      final sortedByDate = List<ProductModel>.from(allProducts);
      sortedByDate.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      newArrivals.value = sortedByDate.take(15).toList();

      // Cache locally for offline availability
      _cacheRecommendations();
    } catch (e) {
      print('Error generating recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch Fallback Products for Cold Start (New users or offline)
  Future<void> _fetchColdStartProducts({List<ProductModel>? productsPool}) async {
    try {
      List<ProductModel> pool = [];
      if (productsPool != null) {
        pool = productsPool;
      } else {
        final snap = await _firestore.collection('products').limit(100).get();
        pool = snap.docs.map((doc) {
          return ProductModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      }

      if (pool.isEmpty) return;

      // Reset personalized sections
      recentlyViewed.clear();
      basedOnSearches.clear();
      continueShopping.clear();
      recommendedForYou.clear();

      // Populate cold start sections
      trendingNearYou.value = pool.where((p) => p.isTrending).take(15).toList();
      bestSellers.value = pool.where((p) => p.isBestSeller).take(15).toList();
      newArrivals.value = List<ProductModel>.from(pool)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      newArrivals.value = newArrivals.take(15).toList();

      homemadeCakes.value = pool.where((p) => p.category.toLowerCase() == 'homemade cakes').take(10).toList();
      fashionPicks.value = pool.where((p) =>
          p.category.toLowerCase() == 'men\'s, women\'s & kids fashion' ||
          p.category.toLowerCase() == 'shoes & footwear').take(10).toList();
      watches.value = pool.where((p) => p.category.toLowerCase() == 'watches').take(10).toList();
      electronics.value = pool.where((p) => p.category.toLowerCase() == 'electronics').take(10).toList();
      carsAndBikes.value = pool.where((p) =>
          p.category.toLowerCase() == 'cars' ||
          p.category.toLowerCase() == 'bikes').take(10).toList();
      localBusinesses.value = pool.where((p) => p.category.toLowerCase() == 'local businesses & services').take(10).toList();

      flashSale.value = pool.where((p) => p.isBestSeller).take(10).toList();
    } catch (e) {
      print('Error fetching cold start recommendations: $e');
    }
  }

  // ── LOCAL OFFLINE CACHING METHODS ──────────────────────────────────────────

  void _cacheRecommendations() {
    try {
      final data = {
        'recentlyViewed': recentlyViewed.map((e) => e.toJson()).toList(),
        'basedOnSearches': basedOnSearches.map((e) => e.toJson()).toList(),
        'continueShopping': continueShopping.map((e) => e.toJson()).toList(),
        'recommendedForYou': recommendedForYou.map((e) => e.toJson()).toList(),
        'trendingNearYou': trendingNearYou.map((e) => e.toJson()).toList(),
        'homemadeCakes': homemadeCakes.map((e) => e.toJson()).toList(),
        'fashionPicks': fashionPicks.map((e) => e.toJson()).toList(),
        'watches': watches.map((e) => e.toJson()).toList(),
        'electronics': electronics.map((e) => e.toJson()).toList(),
        'carsAndBikes': carsAndBikes.map((e) => e.toJson()).toList(),
        'localBusinesses': localBusinesses.map((e) => e.toJson()).toList(),
        'bestSellers': bestSellers.map((e) => e.toJson()).toList(),
        'flashSale': flashSale.map((e) => e.toJson()).toList(),
        'newArrivals': newArrivals.map((e) => e.toJson()).toList(),
      };
      _storage.write('cached_recommendations', data);
    } catch (e) {
      print('Error caching recommendations: $e');
    }
  }

  void loadCachedRecommendations() {
    try {
      final data = _storage.read<Map<String, dynamic>>('cached_recommendations');
      if (data == null) return;

      final parseList = (List<dynamic>? list) {
        if (list == null) return <ProductModel>[];
        return list.map((e) => ProductModel.fromFirestore('', e as Map<String, dynamic>)).toList();
      };

      recentlyViewed.value = parseList(data['recentlyViewed'] as List<dynamic>?);
      basedOnSearches.value = parseList(data['basedOnSearches'] as List<dynamic>?);
      continueShopping.value = parseList(data['continueShopping'] as List<dynamic>?);
      recommendedForYou.value = parseList(data['recommendedForYou'] as List<dynamic>?);
      trendingNearYou.value = parseList(data['trendingNearYou'] as List<dynamic>?);
      homemadeCakes.value = parseList(data['homemadeCakes'] as List<dynamic>?);
      fashionPicks.value = parseList(data['fashionPicks'] as List<dynamic>?);
      watches.value = parseList(data['watches'] as List<dynamic>?);
      electronics.value = parseList(data['electronics'] as List<dynamic>?);
      carsAndBikes.value = parseList(data['carsAndBikes'] as List<dynamic>?);
      localBusinesses.value = parseList(data['localBusinesses'] as List<dynamic>?);
      bestSellers.value = parseList(data['bestSellers'] as List<dynamic>?);
      flashSale.value = parseList(data['flashSale'] as List<dynamic>?);
      newArrivals.value = parseList(data['newArrivals'] as List<dynamic>?);
    } catch (e) {
      print('Error reading cached recommendations: $e');
    }
  }
}

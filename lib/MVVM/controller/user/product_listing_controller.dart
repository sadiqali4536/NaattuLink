import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import '../../model/repository/product_listing_repository.dart';
import '../../model/repository/store_analytics_repository.dart';
import 'package:http/http.dart' as http;

class ProductListingController extends GetxController {
  static ProductListingController get to => Get.find();

  final ProductListingRepository _repository = ProductListingRepository();
  final StoreAnalyticsRepository _analyticsRepository =
      StoreAnalyticsRepository();
  final GetStorage _storage = GetStorage();

  // Engine Lists
  final RxList<StoreProductModel> featuredItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> relatedItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> bestSellingItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> topDealItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> topPickItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> nearbyItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> suggestedItems = <StoreProductModel>[].obs;
  final RxList<StoreProductModel> recentlyViewedItems =
      <StoreProductModel>[].obs;
  final RxList<StoreProductModel> similarItems = <StoreProductModel>[].obs;

  // Main Products Grid
  final RxList<StoreProductModel> products = <StoreProductModel>[].obs;

  // Search
  final RxList<String> recentSearches = <String>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString selectedDiscountFilter = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Highlighted product to show first
  StoreProductModel? highlightedProduct;

  List<StoreProductModel> get displayProducts {
    if (selectedDiscountFilter.value == '50% or more') {
      return products.where((p) => p.discountPercentage >= 50).toList();
    } else if (selectedDiscountFilter.value == '50% or less') {
      return products
          .where((p) => p.discountPercentage > 0 && p.discountPercentage <= 50)
          .toList();
    }
    return products;
  }

  // Loading States
  final RxBool isLoading = true.obs;
  final RxBool isFeaturedLoading = true.obs;
  final RxBool isBestSellingLoading = true.obs;
  final RxBool isTopDealsLoading = true.obs;
  final RxBool isTopPicksLoading = true.obs;
  final RxBool isNearbyLoading = true.obs;
  final RxBool isSuggestedLoading = true.obs;
  final RxBool isRecentlyViewedLoading = true.obs;
  final RxBool isSimilarLoading = true.obs;

  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  DocumentSnapshot? _lastDocument;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    loadStoreEngines();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Sets initial data from navigation and refreshes
  void setInitialData(String category, StoreProductModel? product) {
    bool changed = false;
    if (selectedCategory.value != category) {
      selectedCategory.value = category;
      changed = true;
    }
    if (highlightedProduct?.id != product?.id) {
      highlightedProduct = product;
      changed = true;
    }

    if (changed) {
      if (searchQuery.value.isNotEmpty) {
        searchController.clear();
        searchQuery.value = '';
        relatedItems.clear();
      }
      refreshProducts();
    }
  }

  /// Selects a category and refreshes engines
  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    highlightedProduct =
        null; // Clear highlighted product when changing category manually
    selectedDiscountFilter.value = 'All'; // Reset discount filter

    if (searchQuery.value.isNotEmpty) {
      searchController.clear();
      searchQuery.value = '';
      relatedItems.clear();
    }

    refreshProducts();
  }

  /// Sets the discount filter
  void setDiscountFilter(String filter) {
    if (selectedDiscountFilter.value == filter) return;
    selectedDiscountFilter.value = filter;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isNotEmpty) {
      _saveRecentSearch(query);
      _loadRelatedProducts(query);
    } else {
      relatedItems.clear();
    }
  }

  void _loadRecentSearches() {
    final List<dynamic>? searches =
        _storage.read<List<dynamic>>('recent_searches');
    if (searches != null) {
      recentSearches.assignAll(searches.cast<String>());
    }
  }

  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    if (recentSearches.contains(query)) {
      recentSearches.remove(query);
    }
    recentSearches.insert(0, query);
    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }
    _storage.write('recent_searches', recentSearches.toList());
  }

  /// Refreshes all sections independently
  Future<void> refreshProducts() async {
    _lastDocument = null;
    hasMore.value = true;
    products.clear();

    loadStoreEngines();
  }

  void loadStoreEngines() {
    // Fire off independent async loads so they don't block each other
    final featuredFuture = _loadFeaturedProducts();
    final bestSellingFuture = _loadBestSellingProducts();
    final topDealsFuture = _loadTopDeals();
    final topPicksFuture = _loadTopPicks();
    final nearbyFuture = _loadNearbyProducts();
    final recentlyViewedFuture = _loadRecentlyViewedProducts();
    final similarFuture = _loadSimilarProducts();

    // Load suggested products after others have populated to avoid duplicates
    Future.wait([
      featuredFuture,
      bestSellingFuture,
      topDealsFuture,
      topPicksFuture,
      nearbyFuture,
      recentlyViewedFuture,
      similarFuture,
    ]).then((_) {
      _loadSuggestedProducts();
    });

    _loadMainProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    isFeaturedLoading.value = true;
    try {
      final raw = await _repository.fetchFeaturedProducts();
      featuredItems.assignAll(
          raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      _filterInvalidImages(featuredItems);
    } catch (e) {
      debugPrint("Error loading featured: $e");
    } finally {
      isFeaturedLoading.value = false;
    }
  }

  Future<void> _filterInvalidImages(RxList<StoreProductModel> list) async {
    // 1. Instantly remove products with no images at all
    final validProducts = list
        .where((p) => p.coverImage.isNotEmpty || p.images.isNotEmpty)
        .toList();
    if (validProducts.length != list.length) {
      list.assignAll(validProducts);
    }

    // 2. Asynchronously verify image URLs in the background without blocking the UI
    for (int i = 0; i < validProducts.length; i++) {
      final p = validProducts[i];
      final url = p.coverImage.isNotEmpty ? p.coverImage : p.images.first;

      try {
        final uri = Uri.parse(url);
        final response =
            await http.head(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode == 404) {
          list.remove(p);
        }
      } catch (e) {
        // If the URL is completely malformed or host lookup fails
        list.remove(p);
      }
    }
  }

  Future<void> _loadBestSellingProducts() async {
    isBestSellingLoading.value = true;
    try {
      final raw = await _analyticsRepository.getBestSellingProducts(
        category: selectedCategory.value,
      );
      bestSellingItems.assignAll(
          raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      _filterInvalidImages(bestSellingItems);
    } catch (e) {
      debugPrint("Error loading bestselling: $e");
    } finally {
      isBestSellingLoading.value = false;
    }
  }

  Future<void> _loadTopDeals() async {
    isTopDealsLoading.value = true;
    try {
      final raw = await _analyticsRepository.getTopDeals(
        category: selectedCategory.value,
      );
      topDealItems.assignAll(
          raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      _filterInvalidImages(topDealItems);
    } catch (e) {
      debugPrint("Error loading top deals: $e");
    } finally {
      isTopDealsLoading.value = false;
    }
  }

  Future<void> _loadTopPicks() async {
    isTopPicksLoading.value = true;
    try {
      final raw = await _analyticsRepository.getTopPicks(
        category: selectedCategory.value,
      );
      topPickItems.assignAll(
          raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      _filterInvalidImages(topPickItems);
    } catch (e) {
      debugPrint("Error loading top picks: $e");
    } finally {
      isTopPicksLoading.value = false;
    }
  }

  Future<void> _loadRecentlyViewedProducts() async {
    isRecentlyViewedLoading.value = true;
    try {
      final List<dynamic>? viewedIds =
          _storage.read<List<dynamic>>('recently_viewed_products');
      if (viewedIds != null && viewedIds.isNotEmpty) {
        final docs = await FirebaseFirestore.instance
            .collection('store_products')
            .where(FieldPath.documentId, whereIn: viewedIds.take(10).toList())
            .get();
        recentlyViewedItems.assignAll(docs.docs
            .map((e) => StoreProductModel.fromMap(e.data(), e.id))
            .toList());
        _filterInvalidImages(recentlyViewedItems);
      } else {
        recentlyViewedItems.clear();
      }
    } catch (e) {
      debugPrint("Error loading recently viewed: $e");
    } finally {
      isRecentlyViewedLoading.value = false;
    }
  }

  Future<void> _loadSimilarProducts() async {
    isSimilarLoading.value = true;
    try {
      // Just fetch some random products in the same category as similar items
      final raw = await _analyticsRepository.getTopPicks(
        category: selectedCategory.value,
      );
      // Shuffle to make it look like random similar ones
      raw.shuffle();
      similarItems.assignAll(raw
          .take(6)
          .map((e) => StoreProductModel.fromMap(e, e['id']))
          .toList());
      _filterInvalidImages(similarItems);
    } catch (e) {
      debugPrint("Error loading similar items: $e");
    } finally {
      isSimilarLoading.value = false;
    }
  }

  Future<void> _loadSuggestedProducts() async {
    try {
      isSuggestedLoading.value = true;
      List<StoreProductModel> items = [];

      final Set<String> existingIds = {
        ...featuredItems.map((e) => e.id),
        ...bestSellingItems.map((e) => e.id),
        ...topDealItems.map((e) => e.id),
        ...topPickItems.map((e) => e.id),
        ...nearbyItems.map((e) => e.id),
      };

      if (recentSearches.isNotEmpty) {
        // Fetch based on most recent search to personalize
        try {
          final raw = await _repository.fetchRelatedProducts(
              recentSearches.first, 'All');
          items =
              raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList();
        } catch (e) {
          debugPrint("Error fetching personalized suggested items: $e");
        }
      }

      // If no recent searches or search yielded no results, fallback to general pool
      if (items.isEmpty) {
        final docs = await FirebaseFirestore.instance
            .collection('store_products')
            .where('status', isEqualTo: 'ACTIVE')
            .limit(30)
            .get();
        items = docs.docs
            .map((doc) => StoreProductModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      items = items.where((item) => !existingIds.contains(item.id)).toList();
      items.shuffle(); // Randomize
      suggestedItems.assignAll(items.take(12));
      _filterInvalidImages(suggestedItems);
    } catch (e) {
      print('Error loading suggested items: $e');
    } finally {
      isSuggestedLoading.value = false;
    }
  }

  Future<void> _loadNearbyProducts() async {
    isNearbyLoading.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        nearbyItems.clear();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Do not spam request, just fail gracefully
        nearbyItems.clear();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      final raw = await _analyticsRepository.getNearbyProducts(position);

      if (selectedCategory.value != 'All') {
        final filtered = raw
            .where((r) => r['categoryName'] == selectedCategory.value)
            .toList();
        nearbyItems.assignAll(filtered
            .map((e) => StoreProductModel.fromMap(e, e['id']))
            .toList());
      } else {
        nearbyItems.assignAll(
            raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      }
      _filterInvalidImages(nearbyItems);
    } catch (e) {
      debugPrint("Error loading nearby products: $e");
      nearbyItems.clear();
    } finally {
      isNearbyLoading.value = false;
    }
  }

  Future<void> _loadRelatedProducts(String query) async {
    try {
      final raw =
          await _repository.fetchRelatedProducts(query, selectedCategory.value);
      relatedItems.assignAll(
          raw.map((e) => StoreProductModel.fromMap(e, e['id'])).toList());
      _filterInvalidImages(relatedItems);
    } catch (e) {
      debugPrint("Error loading related products: $e");
    }
  }

  Future<void> _loadMainProducts() async {
    isLoading.value = true;
    try {
      final snapshot = await _repository.fetchProducts(
        category: selectedCategory.value,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final fetched = snapshot.docs
            .map((doc) => StoreProductModel.fromMap(doc.data(), doc.id))
            .toList();

        // Move highlighted product to the top if present
        if (highlightedProduct != null) {
          fetched.removeWhere((p) => p.id == highlightedProduct!.id);
          fetched.insert(0, highlightedProduct!);
        }

        products.assignAll(fetched);
        _filterInvalidImages(products);
        if (snapshot.docs.length < 10) hasMore.value = false;
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Error loading main products: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMore.value || _lastDocument == null) return;

    // During search, main products grid might be repurposed or hidden
    if (searchQuery.value.trim().isNotEmpty) return;

    isLoadingMore.value = true;
    try {
      final snapshot = await _repository.fetchProducts(
        startAfter: _lastDocument,
        category: selectedCategory.value,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        products.addAll(snapshot.docs
            .map((doc) => StoreProductModel.fromMap(doc.data(), doc.id))
            .toList());
        _filterInvalidImages(products);
        if (snapshot.docs.length < 10) hasMore.value = false;
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("Error loading more products: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }
}

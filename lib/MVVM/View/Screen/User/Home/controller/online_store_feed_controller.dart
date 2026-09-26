import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'dart:math';

enum FeedItemType {
  topAdBanner, // The fixed first banner carousel
  banner,
  spotlight,
  brandSection,
  categorySection,
  productGrid,
  horizontalProducts,
  topValueDeals,
  dealsOfDay,
  brandsInSpotlight,
  flashDeals,
  popularNearby,
  afternoonPicks,
  suggestedForYou,
  loading
}

class OnlineFeedItem {
  final FeedItemType type;
  final String title;
  final List<dynamic> items;
  final Map<String, dynamic>? extraData;

  OnlineFeedItem({
    required this.type,
    this.title = '',
    this.items = const [],
    this.extraData,
  });
}

class OnlineStoreFeedController extends GetxController {
  final _firestore = FirebaseFirestore.instance;

  // State
  final feedItems = <OnlineFeedItem>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;

  // Pools
  final List<StoreProductModel> _productsPool = [];
  final List<DocumentSnapshot> _bannersPool = [];
  final List<DocumentSnapshot> _spotlightsPool = [];

  // Memory constraints
  final Set<String> _alreadyDisplayedProductIds = {};
  final Set<String> _alreadyDisplayedBannerIds = {};
  final Set<String> _alreadyDisplayedSpotlightIds = {};

  DocumentSnapshot? _lastProductDocument;
  final int _pageSize = 20;

  // Feed Session
  final List<String> _dynamicSectionPool = [
    'Top Value Deals',
    "Today\\'s Top Picks",
    'Brands in Spotlight',
    'Popular Near You',
    'Suggested For You',
    'Explore Similar Trends',
    'More From This Category',
    'You May Also Like',
    'Flash Deals',
  ];

  // We keep a running queue of what section type to insert next
  final List<String> _sessionSectionQueue = [];
  String? _lastInsertedSectionType;

  @override
  void onInit() {
    super.onInit();
    startNewFeedSession();
  }

  void startNewFeedSession() async {
    isLoading.value = true;
    _alreadyDisplayedProductIds.clear();
    _alreadyDisplayedBannerIds.clear();
    _alreadyDisplayedSpotlightIds.clear();
    _productsPool.clear();
    _bannersPool.clear();
    _spotlightsPool.clear();
    feedItems.clear();
    _lastProductDocument = null;
    hasMore.value = true;

    // Prepare session queue
    _sessionSectionQueue.clear();
    _fillSessionQueue();

    await Future.wait([
      _fetchInitialProducts(),
      _fetchBanners(),
      _fetchSpotlights(),
    ]);

    _composeInitialFeed();
    isLoading.value = false;
  }

  void _fillSessionQueue() {
    // Shuffle the available sections for this session
    final List<String> availableSections = List.from(_dynamicSectionPool);
    availableSections.shuffle(Random());
    _sessionSectionQueue.addAll(availableSections);
  }

  Future<void> _fetchInitialProducts() async {
    try {
      final query = _firestore
          .collection('store_products')
          .where('status', isEqualTo: 'active')
          .limit(_pageSize);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastProductDocument = snapshot.docs.last;
        final products = snapshot.docs
            .map((doc) => StoreProductModel.fromMap(doc.data(), doc.id))
            .toList();
        products.shuffle(Random());
        _productsPool.addAll(products);
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final snapshot = await _firestore.collection('banners').get();
      _bannersPool.addAll(snapshot.docs);
      _bannersPool.shuffle(Random());
    } catch (e) {
      print("Error fetching banners: $e");
    }
  }

  Future<void> _fetchSpotlights() async {
    try {
      final snapshot = await _firestore
          .collection('spotlights')
          .where('isActive', isEqualTo: true)
          .get();
      _spotlightsPool.addAll(snapshot.docs);
      _spotlightsPool.shuffle(Random());
    } catch (e) {
      print("Error fetching spotlights: $e");
    }
  }

  void _composeInitialFeed() {
    // 1. FIXED: Ad Banner
    feedItems.add(OnlineFeedItem(type: FeedItemType.topAdBanner));

    // 2. FIXED: Great Finds Are Waiting For You
    if (_productsPool.length >= 4) {
      final batch = _productsPool.take(4).toList();
      _productsPool.removeRange(0, 4);
      for (var p in batch) {
        _alreadyDisplayedProductIds.add(p.id);
      }
      feedItems.add(OnlineFeedItem(
        type: FeedItemType.productGrid,
        title: "Great Finds Are Waiting For You",
        items: batch,
      ));
    }

    _composeNextFeedBatch();
  }

  void _composeNextFeedBatch() {
    // We try to add 2-3 dynamic blocks per pagination
    int blocksToAdd = 3;

    while (blocksToAdd > 0) {
      if (_sessionSectionQueue.isEmpty) {
        // Reshuffle and refill if we run out of unique sections
        _fillSessionQueue();
      }

      // Determine what to add next to prevent identical consecutive items
      bool insertedPromo = false;

      // Try inserting a banner or spotlight between product sections
      if (_lastInsertedSectionType == 'product' && Random().nextBool()) {
        if (_spotlightsPool.isNotEmpty &&
            _lastInsertedSectionType != 'spotlight' &&
            Random().nextBool()) {
          final spotlight = _spotlightsPool.removeAt(0);
          _alreadyDisplayedSpotlightIds.add(spotlight.id);
          feedItems.add(
              OnlineFeedItem(type: FeedItemType.spotlight, items: [spotlight]));
          _lastInsertedSectionType = 'spotlight';
          insertedPromo = true;
          blocksToAdd--;
        } else if (_bannersPool.isNotEmpty &&
            _lastInsertedSectionType != 'banner') {
          final banner = _bannersPool.removeAt(0);
          _alreadyDisplayedBannerIds.add(banner.id);
          feedItems
              .add(OnlineFeedItem(type: FeedItemType.banner, items: [banner]));
          _lastInsertedSectionType = 'banner';
          insertedPromo = true;
          blocksToAdd--;
        }
      }

      if (blocksToAdd <= 0) break;

      // Insert a dynamic product section
      if (_productsPool.length >= 4) {
        String nextSectionTitle = _sessionSectionQueue.removeAt(0);

        final batch = _productsPool.take(4).toList();
        _productsPool.removeRange(0, 4);
        for (var p in batch) {
          _alreadyDisplayedProductIds.add(p.id);
        }

        FeedItemType sectionType = FeedItemType.horizontalProducts;
        if (nextSectionTitle == 'Top Value Deals') sectionType = FeedItemType.topValueDeals;
        else if (nextSectionTitle == 'Today\'s Top Picks') sectionType = FeedItemType.dealsOfDay;
        else if (nextSectionTitle == 'Brands in Spotlight') sectionType = FeedItemType.brandsInSpotlight;
        else if (nextSectionTitle == 'Flash Deals') sectionType = FeedItemType.flashDeals;
        else if (nextSectionTitle == 'Popular Near You') sectionType = FeedItemType.popularNearby;
        else if (nextSectionTitle == 'Afternoon Picks') sectionType = FeedItemType.afternoonPicks;
        else if (nextSectionTitle == 'Suggested For You') sectionType = FeedItemType.suggestedForYou;
        else sectionType = Random().nextBool() ? FeedItemType.productGrid : FeedItemType.horizontalProducts;

            
        feedItems.add(OnlineFeedItem(
          type: sectionType,
          title: nextSectionTitle,
          items: batch,
        ));
        _lastInsertedSectionType = 'product';
        blocksToAdd--;
      } else {
        // Not enough products to form a block, stop composing until loadMore completes
        break;
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;
    try {
      var query = _firestore
          .collection('store_products')
          .where('status', isEqualTo: 'active')
          .limit(_pageSize);

      if (_lastProductDocument != null) {
        query = query.startAfterDocument(_lastProductDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastProductDocument = snapshot.docs.last;
        final newProducts = snapshot.docs
            .map((doc) => StoreProductModel.fromMap(doc.data(), doc.id))
            .where((p) => !_alreadyDisplayedProductIds.contains(p.id))
            .toList();

        newProducts.shuffle(Random());
        _productsPool.addAll(newProducts);
        _composeNextFeedBatch();
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      print("Error loading more products: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshFeed() async {
    startNewFeedSession();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/repository/store_product_repository.dart';

class ProductSearchController extends GetxController {
  static ProductSearchController get to => Get.find();

  final StoreProductRepository _repository = StoreProductRepository();

  final RxString searchQuery = ''.obs;
  final RxList<String> recentSearches = <String>[].obs;
  final RxList<DocumentSnapshot> allActiveProducts = <DocumentSnapshot>[].obs;
  final RxList<DocumentSnapshot> searchResults = <DocumentSnapshot>[].obs;
  final RxBool isLoading = true.obs; // true until first Firestore response

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
    _listenToProducts();

    // Rebuild searchResults whenever query or product list changes
    ever(searchQuery, (_) => _updateResults());
    ever(allActiveProducts, (_) => _updateResults());
  }

  void _listenToProducts() {
    _repository.getActiveProductsStream().listen((products) {
      allActiveProducts.value = products;
      isLoading.value = false; // data has arrived (even if empty)
    }, onError: (_) {
      isLoading.value = false; // stop spinner on error too
    });
  }

  void _updateResults() {
    final sq = searchQuery.value.trim().toLowerCase();
    if (sq.isEmpty) {
      searchResults.clear();
      return;
    }

    searchResults.value = allActiveProducts.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      final title =
          (data['productName'] ?? data['title'] ?? '').toString().toLowerCase();
      // Firestore stores it as productTypeName AND productTypeId (not 'productType')
      final type = (data['productTypeName'] ??
              data['productTypeId'] ??
              data['productType'] ??
              '')
          .toString()
          .toLowerCase();
      final category = (data['category'] ?? data['categoryName'] ?? '')
          .toString()
          .toLowerCase();
      final subcategory = (data['subcategory'] ?? data['subcategoryName'] ?? '')
          .toString()
          .toLowerCase();
      final brand = (data['brand'] ?? '').toString().toLowerCase();
      final tags = (data['tags'] ?? []).toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();

      return title.contains(sq) ||
          type.contains(sq) ||
          category.contains(sq) ||
          subcategory.contains(sq) ||
          brand.contains(sq) ||
          tags.contains(sq) ||
          description.contains(sq);
    }).toList();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    recentSearches.value = searches;
  }

  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final sq = query.trim().toLowerCase();
    recentSearches.removeWhere((item) => item.toLowerCase() == sq);
    recentSearches.insert(0, query.trim());

    if (recentSearches.length > 10) {
      recentSearches.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
  }

  Future<void> removeSearch(String query) async {
    recentSearches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recentSearches);
  }

  Future<void> clearAllSearches() async {
    recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', []);
  }
}

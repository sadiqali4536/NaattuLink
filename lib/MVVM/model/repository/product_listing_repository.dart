import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a paginated list of active products.
  ///
  /// [startAfter] Optional document snapshot to start the query after (for pagination).
  /// [category] Optional category filter.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchProducts({
    DocumentSnapshot? startAfter,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('store_products')
        .where('status', isEqualTo: 'active');

    // If category is provided and is not 'All', filter by it.
    if (category != null && category.isNotEmpty && category != 'All') {
      // Trying categoryName first since existing code relies on it, or categoryId
      // StoreProductModel has `categoryName` but Firestore might store it under `categoryName` or `category`.
      // The current seller product add screen saves it as `categoryName` mostly.
      query = query.where('categoryName', isEqualTo: category);
    }

    // To be safe and avoid composite index requirements for (status + categoryName + pagination),
    // we use simple limit and startAfter without orderBy.
    query = query.limit(10);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  /// Fetches featured products for the promotion carousel.
  Future<List<Map<String, dynamic>>> fetchFeaturedProducts() async {
    // Note: status casing could be 'Active' or 'active', querying 'active' based on existing codebase conventions.
    // If the database uses 'Active', this needs to be adjusted or OR-queried.
    final snapshot = await _firestore
        .collection('store_products')
        // .where('status', isEqualTo: 'active') // For compatibility, you might need to handle both
        .where('isFeatured', isEqualTo: true)
        .limit(10)
        .get();

    // Do filtering client-side for status to handle mixed casing without needing composite indexes for everything
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((data) => data['status']?.toString().toLowerCase() == 'active')
        .toList();
  }

  /// Fetches products related to a search term or category.
  Future<List<Map<String, dynamic>>> fetchRelatedProducts(
    String searchTerm,
    String category,
  ) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('store_products')
        .where('status', isEqualTo: 'active');

    if (category.isNotEmpty && category != 'All') {
      query = query.where('categoryName', isEqualTo: category);
    }
    
    final snapshot = await query.limit(20).get();
    
    // Fallback: If we have a searchTerm but no complex search index (like Algolia/Elastic),
    // we do basic client-side filtering on the fetched category items.
    var docs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    if (searchTerm.isNotEmpty) {
      final term = searchTerm.toLowerCase();
      docs = docs.where((data) {
        final name = (data['productName'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        final brand = (data['brand'] ?? '').toString().toLowerCase();
        return name.contains(term) || desc.contains(term) || brand.contains(term);
      }).toList();
    }
    
    return docs;
  }
}

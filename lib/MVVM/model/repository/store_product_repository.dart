import 'package:cloud_firestore/cloud_firestore.dart';

class StoreProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches all products from the store_products collection.
  /// Filtering by status is done client-side to handle case variations
  /// and boolean `isActive` flags without needing composite Firestore indexes.
  Stream<List<DocumentSnapshot>> getActiveProductsStream() {
    return _firestore
        .collection('store_products')
        .snapshots()
        .map((snapshot) => snapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) return false;

              // Support boolean isActive field
              if (data['isActive'] == true) return true;

              // Support string status field (case-insensitive)
              final status = (data['status'] ?? '').toString().toLowerCase();
              return status == 'active';
            }).toList());
  }
}

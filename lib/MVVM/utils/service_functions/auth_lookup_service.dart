import 'package:cloud_firestore/cloud_firestore.dart';

class AuthLookupService {
  /// Centralized lookup for a User document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getUserByAuthUid(String uid) async {
    // 1. New Architecture: Try authUid query
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    // 2. Old Architecture: Fallback to doc(uid)
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc;
    }
    return null;
  }

  /// Centralized lookup for a Seller document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getSellerByAuthUid(String uid) async {
    final query = await FirebaseFirestore.instance
        .collection('sellers')
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;

    final doc =
        await FirebaseFirestore.instance.collection('sellers').doc(uid).get();
    if (doc.exists) return doc;
    return null;
  }

  /// Centralized lookup for a Worker document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getWorkerByAuthUid(String uid) async {
    final query = await FirebaseFirestore.instance
        .collection('workers')
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;

    final doc =
        await FirebaseFirestore.instance.collection('workers').doc(uid).get();
    if (doc.exists) return doc;
    return null;
  }

  /// Centralized lookup for a Transport document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getTransportByAuthUid(String uid) async {
    final query = await FirebaseFirestore.instance
        .collection('transports')
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;

    final doc = await FirebaseFirestore.instance
        .collection('transports')
        .doc(uid)
        .get();
    if (doc.exists) return doc;
    return null;
  }

  /// Centralized lookup for a Healthcare document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getHealthcareByAuthUid(String uid) async {
    final query = await FirebaseFirestore.instance
        .collection('healthcare')
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;

    final doc = await FirebaseFirestore.instance
        .collection('healthcare')
        .doc(uid)
        .get();
    if (doc.exists) return doc;
    return null;
  }

  /// Centralized lookup for a Business document by Firebase Auth UID.
  static Future<DocumentSnapshot?> getBusinessByAuthUid(String uid,
      {bool useShopsBusinesses = false}) async {
    String collection = useShopsBusinesses ? 'shops_businesses' : 'businesses';
    final query = await FirebaseFirestore.instance
        .collection(collection)
        .where('authUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;

    final doc =
        await FirebaseFirestore.instance.collection(collection).doc(uid).get();
    if (doc.exists) return doc;
    return null;
  }
}

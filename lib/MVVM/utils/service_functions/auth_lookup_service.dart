import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Resolves a user's identity across ALL possible collections.
  static Future<ParticipantIdentity?> resolveUniversalParticipant(
      String uid) async {
    // Check order matters for priority
    final collectionsToCheck = [
      {'collection': 'users', 'type': 'user'},
      {'collection': 'businesses', 'type': 'business'},
      {'collection': 'shops_businesses', 'type': 'business'},
      {'collection': 'workers', 'type': 'worker'},
      {'collection': 'healthcare', 'type': 'healthcare'},
      {'collection': 'transports', 'type': 'transport'},
      {'collection': 'sellers', 'type': 'seller'},
    ];

    ParticipantIdentity? fallbackIdentity;

    for (final col in collectionsToCheck) {
      final collectionName = col['collection']!;
      final type = col['type']!;

      final query = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('authUid', isEqualTo: uid)
          .limit(1)
          .get();

      DocumentSnapshot? doc;
      if (query.docs.isNotEmpty) {
        doc = query.docs.first;
      } else {
        final docById = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(uid)
            .get();
        if (docById.exists) doc = docById;
      }

      if (doc != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Skip ghost documents created by FirebaseAuthServices.createUser but never updated
        // because the user registered in a different collection (e.g., worker).
        if (data.containsKey('role') &&
            data['role'] != null &&
            data['role'] != type &&
            data['role'] != '') {
          continue;
        }

        // Try to extract standard fields robustly
        String publicId = data['publicId'] ??
            data['businessPublicId'] ??
            data['workerPublicId'] ??
            doc.id;
        String? nameVal = data['name'] ??
            data['username'] ??
            data['facility_name'] ??
            data['businessName'] ??
            data['fullName'] ??
            data['first_name'];
        String? phone =
            data['phone'] ?? data['phoneNumber'] ?? data['contact_number'];
        if (phone == null || phone.trim().isEmpty) {
          phone = FirebaseAuth.instance.currentUser?.phoneNumber;
        }

        String? image =
            data['profile_img'] ?? data['profileImage'] ?? data['imageUrl'];

        bool hasRealName =
            nameVal != null && nameVal.toString().trim().isNotEmpty;
        bool hasRealPhone = phone != null && phone.trim().isNotEmpty;

        if (nameVal == null || nameVal.toString().trim().isEmpty) {
          nameVal = FirebaseAuth.instance.currentUser?.displayName;
        }
        if (nameVal == null || nameVal.toString().trim().isEmpty) {
          nameVal = phone;
        }
        if (nameVal == null || nameVal.toString().trim().isEmpty) {
          nameVal = FirebaseAuth.instance.currentUser?.phoneNumber;
        }
        if (nameVal == null || nameVal.toString().trim().isEmpty) {
          nameVal = data['email'] ??
              FirebaseAuth.instance.currentUser?.email ??
              'User';
        }

        String name = nameVal.toString();

        final identity = ParticipantIdentity(
          collection: collectionName,
          documentId: doc.id,
          publicId: publicId,
          type: type,
          name: name,
          phone: phone,
          image: image,
        );

        if (hasRealName && hasRealPhone) {
          return identity; // Perfect match found
        } else if (hasRealName || hasRealPhone) {
          fallbackIdentity =
              identity; // Good fallback, but continue searching for a perfect one
        } else {
          fallbackIdentity ??=
              identity; // Keep as worst-case fallback, but continue searching
        }
      }
    }

    return fallbackIdentity;
  }
}

class ParticipantIdentity {
  final String collection;
  final String documentId;
  final String publicId;
  final String type;
  final String name;
  final String? phone;
  final String? image;

  ParticipantIdentity({
    required this.collection,
    required this.documentId,
    required this.publicId,
    required this.type,
    required this.name,
    this.phone,
    this.image,
  });
}

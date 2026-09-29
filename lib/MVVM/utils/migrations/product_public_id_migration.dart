import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:naattulink/MVVM/utils/public_id_generator.dart';

class PublicIdMigration {
  static Future<void> migrateAll() async {
    debugPrint('Starting Full Public ID Migration...');
    await _migrateCollection('users', 'userPublicId', PublicIdGenerator.generateUserId);
    await _migrateCollection('sellers', 'sellerPublicId', PublicIdGenerator.generateSellerId);
    await _migrateCollection('workers', 'workerPublicId', PublicIdGenerator.generateWorkerId);
    await _migrateCollection('transports', 'transportPublicId', PublicIdGenerator.generateTransportId);
    await _migrateCollection('healthcare', 'healthcarePublicId', PublicIdGenerator.generateHealthcareId);
    await _migrateCollection('businesses', 'businessPublicId', PublicIdGenerator.generateBusinessId);
    await _migrateCollection('store_products', 'productPublicId', PublicIdGenerator.generateProductId);
    debugPrint('Full Public ID Migration Completed.');
  }

  static Future<void> _migrateCollection(
    String collectionName,
    String fieldName,
    Future<String> Function() generator,
  ) async {
    debugPrint('Migrating $collectionName...');
    int migratedCount = 0;
    int skippedCount = 0;
    
    DocumentSnapshot? lastDocument;
    bool hasMore = true;
    final int batchSize = 100;

    while (hasMore) {
      Query query = FirebaseFirestore.instance.collection(collectionName).limit(batchSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      lastDocument = snapshot.docs.last;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? existingPublicId = data[fieldName] as String?;

        if (existingPublicId == null || existingPublicId.isEmpty) {
          try {
            final newId = await generator();
            await doc.reference.update({
              fieldName: newId,
            });
            migratedCount++;
            debugPrint('Migrated $collectionName: ${doc.id} -> $newId');
          } catch (e) {
            debugPrint('Error migrating $collectionName ${doc.id}: $e');
          }
        } else {
          skippedCount++;
        }
      }
    }

    debugPrint('$collectionName: Migrated=$migratedCount, Skipped=$skippedCount');
  }
}

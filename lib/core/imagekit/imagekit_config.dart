import 'package:cloud_firestore/cloud_firestore.dart';
import 'imagekit_models.dart';

class ImageKitConfigManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, ImageKitConfig> _cache = {};

  static Future<ImageKitConfig> getConfig({
    required String storageType,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(storageType)) {
      return _cache[storageType]!;
    }

    var snapshot = await _firestore
        .collection('imagekit_providers')
        .where('storageType', isEqualTo: storageType)
        .where('enabled', isEqualTo: true)
        .orderBy('priority')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Try falling back to base storage type by removing trailing _number (e.g. seller_product_1 -> seller_product)
      final cleanStorageType = storageType.replaceAll(RegExp(r'_\d+$'), '');
      if (cleanStorageType != storageType) {
        snapshot = await _firestore
            .collection('imagekit_providers')
            .where('storageType', isEqualTo: cleanStorageType)
            .where('enabled', isEqualTo: true)
            .orderBy('priority')
            .limit(1)
            .get();
      }
    }

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'No enabled ImageKit provider found for storageType: $storageType',
      );
    }

    final data = snapshot.docs.first.data();

    final config = ImageKitConfig(
      storageType: data['storageType'] ?? storageType,
      publicKey: data['publicKey'] ?? '',
      privateKey: '', // Never expose private key
      urlEndpoint: data['urlEndpoint'] ?? '',
      defaultFolder: data['defaultFolder'] ?? '',
      accountName: data['accountName'] ?? data['name'] ?? '',
    );

    _cache[storageType] = config;
    return config;
  }

  static void clearCache() {
    _cache.clear();
  }
}

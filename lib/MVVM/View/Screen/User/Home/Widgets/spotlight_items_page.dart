import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/product/product_details_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpotlightItemsPage extends StatelessWidget {
  final List<dynamic> items;
  final String? title;

  const SpotlightItemsPage({Key? key, required this.items, this.title})
      : super(key: key);

  Future<Map<String, dynamic>?> _fetchItem(String id, String type) async {
    if (type == 'product') {
      final doc = await FirebaseFirestore.instance
          .collection('store_products')
          .doc(id)
          .get();
      if (doc.exists) return {'doc': doc, 'type': 'product'};
    } else if (type == 'service') {
      final doc =
          await FirebaseFirestore.instance.collection('services').doc(id).get();
      if (doc.exists) return {'doc': doc, 'type': 'service'};
    } else {
      final pDoc = await FirebaseFirestore.instance
          .collection('store_products')
          .doc(id)
          .get();
      if (pDoc.exists) return {'doc': pDoc, 'type': 'product'};
      final sDoc =
          await FirebaseFirestore.instance.collection('services').doc(id).get();
      if (sDoc.exists) return {'doc': sDoc, 'type': 'service'};
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchAllItems() async {
    List<Map<String, dynamic>> results = [];
    for (var item in items) {
      String id = '';
      String type = '';
      if (item is Map) {
        id = item['id']?.toString() ?? '';
        type = item['type']?.toString() ?? '';
      } else {
        id = item.toString();
      }
      if (id.isNotEmpty) {
        final data = await _fetchItem(id, type);
        if (data != null) {
          results.add(data);
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotlight',
            style: TextStyle(
                color: Color(0xFF0F2E5A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F2E5A)),
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.wifi_off_outlined, color: Colors.grey, size: 60),
                  SizedBox(height: 16),
                  Text('No internet connection',
                      style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No items available in this spotlight.'));
          }

          final data = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = data[index];
              final doc = item['doc'] as DocumentSnapshot;
              final type = item['type'] as String;

              if (type == 'product') {
                return _buildProductCard(context, doc);
              } else {
                return _buildServiceCard(context, doc);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final product = StoreProductModel.fromMap(data, doc.id);
    return ListTile(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProductDetailsPage(product: product)));
      },
      contentPadding: const EdgeInsets.all(8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.coverImage,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image)),
        ),
      ),
      title: Text(product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text('₹${product.sellingPrice}',
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildServiceCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['service_name'] ?? 'Service').toString();
    final image = (data['image_url'] ?? data['image'] ?? '').toString();
    final price =
        data['discount_price'] ?? data['price'] ?? data['original_price'] ?? 0;

    return ListTile(
      onTap: () {
        final category = (data['category'] ?? '').toString();
        final dynamic rawRating = data['rating'];
        double rating = 0.0;
        if (rawRating is num)
          rating = rawRating.toDouble();
        else if (rawRating is Map && rawRating['average'] is num)
          rating = rawRating['average'].toDouble();

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ServiceDetailsPage(
                      category: category,
                      serviceName: name,
                      rating: rating,
                      originalPrice: data['original_price'] ?? 0,
                      discount: data['discount'] ?? 0,
                      image: image,
                      discountPrice:
                          data['discount_price'] ?? data['price'] ?? 0,
                      serviceType: data['service_type'],
                      businessLat: (data['businessLat'] as num?)?.toDouble(),
                      businessLng: (data['businessLng'] as num?)?.toDouble(),
                      businessAddress: data['businessAddress'] as String?,
                      businessMapsUrl: data['businessMapsUrl'] as String?,
                      serviceId: doc.id,
                      providerId: data['providerId']?.toString() ??
                          data['uid']?.toString() ??
                          'Unknown',
                      providerName: data['providerName']?.toString() ??
                          data['workerName']?.toString() ??
                          'Unknown',
                      providerPhone: data['providerPhone']?.toString() ??
                          data['phone']?.toString() ??
                          '',
                      serviceDescription: data['description']?.toString() ??
                          data['about']?.toString() ??
                          '',
                    )));
      },
      contentPadding: const EdgeInsets.all(8),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: const Icon(Icons.design_services)),
        ),
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text('₹$price',
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}

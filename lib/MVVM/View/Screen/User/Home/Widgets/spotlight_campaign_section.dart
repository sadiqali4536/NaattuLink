import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

import 'package:url_launcher/url_launcher.dart';
import 'spotlight_items_page.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/View/Screen/User/product/product_details_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';

class SpotlightCampaignSection extends StatefulWidget {
  final bool isOnlineStore;
  final bool showTitle;
  const SpotlightCampaignSection({
    Key? key,
    this.isOnlineStore = false,
    this.showTitle = true,
  }) : super(key: key);

  @override
  State<SpotlightCampaignSection> createState() =>
      _SpotlightCampaignSectionState();
}

class _SpotlightCampaignSectionState extends State<SpotlightCampaignSection>
    with WidgetsBindingObserver {
  QuerySnapshot? _lastSnapshot;
  List<DocumentSnapshot> _shuffledDocs = [];
  final Map<String, String> _brandCache = {};

  Future<String?> _fetchBrandName(Map<String, dynamic> data) async {
    final exploreAction = data['exploreAction'] as Map<String, dynamic>?;
    final campaignType = data['campaignType']?.toString() ?? '';
    final targetIds = data['targetIds'] as List<dynamic>? ?? [];

    String type = '';
    List<dynamic> items = [];

    if (exploreAction != null) {
      type = (exploreAction['type']?.toString() ?? '').toLowerCase();
      items = exploreAction['items'] ?? exploreAction['targetIds'] ?? targetIds;
    } else {
      type = campaignType.toLowerCase();
      items = targetIds;
    }

    if (type == 'product' && items.isNotEmpty) {
      final id = items.first;
      final docId = (id is Map) ? id['id']?.toString() : id.toString();
      if (docId != null && docId.isNotEmpty) {
        if (_brandCache.containsKey(docId)) return _brandCache[docId];

        try {
          final doc = await FirebaseFirestore.instance
              .collection('store_products')
              .doc(docId)
              .get();
          if (doc.exists) {
            final pData = doc.data() as Map<String, dynamic>;
            final brand = pData['brand']?.toString();
            if (brand != null && brand.isNotEmpty) {
              _brandCache[docId] = brand;
              return brand;
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_shuffledDocs.isNotEmpty) {
        setState(() {
          _shuffledDocs.shuffle();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spotlights')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        if (_lastSnapshot != snapshot.data) {
          _lastSnapshot = snapshot.data;

          final now = DateTime.now();
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final startTimestamp = data['startDate'] as Timestamp?;
            final endTimestamp = data['endDate'] as Timestamp?;

            if (startTimestamp != null &&
                startTimestamp.toDate().isAfter(now)) {
              return false;
            }
            if (endTimestamp != null && endTimestamp.toDate().isBefore(now)) {
              return false;
            }
            return true;
          }).toList();

          // Shuffle the documents dynamically
          docs.shuffle();
          _shuffledDocs = docs;
        }

        if (_shuffledDocs.isEmpty) {
          return const SizedBox.shrink();
        }

        Widget content;
        if (widget.isOnlineStore || _shuffledDocs.length == 1) {
          content = widget.isOnlineStore
              ? _buildOnlineStoreSpotlightCard(
                  context, _shuffledDocs.first.data() as Map<String, dynamic>)
              : _buildSpotlightCard(
                  context, _shuffledDocs.first.data() as Map<String, dynamic>);
        } else {
          content = CarouselSlider(
            items: _shuffledDocs
                .map((doc) => widget.isOnlineStore
                    ? _buildOnlineStoreSpotlightCard(
                        context, doc.data() as Map<String, dynamic>)
                    : _buildSpotlightCard(
                        context, doc.data() as Map<String, dynamic>))
                .toList(),
            options: CarouselOptions(
              height: widget.isOnlineStore ? 180 : 220,
              autoPlay: false, // Do not autoplay to respect admin priority
              enlargeCenterPage: false,
              padEnds: false,
              viewportFraction: 0.8,
              enableInfiniteScroll: false,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isOnlineStore
                          ? 'brands_in_spotlight'.tr
                          : 'spotlight_campaigns'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2E5A),
                      ),
                    ),
                    if (!widget.isOnlineStore)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Featured",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E5A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            content,
          ],
        );
      },
    );
  }

  Widget _buildOnlineStoreSpotlightCard(
      BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final bannerImageUrl = data['bannerImageUrl']?.toString() ?? '';
    final campaignType = data['campaignType']?.toString() ?? '';
    final targetIds = data['targetIds'] as List<dynamic>? ?? [];

    return FutureBuilder<String?>(
      future: _fetchBrandName(data),
      builder: (context, snapshot) {
        final fetchedBrand = snapshot.data;
        final displayBrand = (fetchedBrand != null && fetchedBrand.isNotEmpty)
            ? fetchedBrand
            : (subtitle.isNotEmpty ? subtitle : "Brand");

        return GestureDetector(
          onTap: () {
            _handleTap(context, campaignType, targetIds, data);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: bannerImageUrl.isEmpty ? const Color(0xFF2563EB) : null,
              borderRadius: BorderRadius.circular(16),
              image: bannerImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(bannerImageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayBrand,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 14,
                            width: 1,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24), // Yellow
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  "Featured",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.bolt,
                                  size: 10,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (subtitle.isNotEmpty && subtitle != displayBrand) ...[
                        SizedBox(height: title.isNotEmpty ? 4 : 12),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: const [
                          Text(
                            "Explore Now",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "AD",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpotlightCard(BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final subtitle = data['subtitle']?.toString() ?? '';
    final bannerImageUrl = data['bannerImageUrl']?.toString() ?? '';
    final campaignType = data['campaignType']?.toString() ?? '';
    final targetIds = data['targetIds'] as List<dynamic>? ?? [];

    return GestureDetector(
      onTap: () {
        _handleTap(context, campaignType, targetIds, data);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Image
              Expanded(
                child: bannerImageUrl.isNotEmpty
                    ? Image.network(
                        bannerImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return ShimmerEffect(
                            child: SkeletonPlaceholder(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _buildFallbackImage(),
                      )
                    : _buildFallbackImage(),
              ),
              // Content Area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2E5A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: const [
                        Text(
                          "Explore",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F2E5A),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFF0F2E5A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.campaign, color: Colors.grey, size: 40),
      ),
    );
  }

  void _handleTap(BuildContext context, String campaignType,
      List<dynamic> targetIds, Map<String, dynamic> data) async {
    final exploreAction = data['exploreAction'] as Map<String, dynamic>?;

    String type = '';
    List<dynamic> items = [];

    if (exploreAction != null) {
      type = (exploreAction['type']?.toString() ?? '').toLowerCase();
      items = exploreAction['items'] ?? exploreAction['targetIds'] ?? targetIds;
    } else {
      type = campaignType.toLowerCase();
      items = targetIds;
    }

    if (type == 'product') {
      if (items.isNotEmpty) {
        _openProduct(context, _extractId(items.first));
      }
    } else if (type == 'service') {
      if (items.isNotEmpty) {
        _openService(context, _extractId(items.first));
      }
    } else if (type == 'multiple') {
      if (items.length >= 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpotlightItemsPage(items: items),
          ),
        );
      } else if (items.length == 1) {
        // Fallback if configured as multiple but only 1 exists
        final item = items.first;
        final itemType = (item is Map) ? item['type']?.toString() : '';
        if (itemType == 'product') {
          _openProduct(context, _extractId(item));
        } else if (itemType == 'service') {
          _openService(context, _extractId(item));
        }
      }
    } else if (type == 'external_link') {
      final url = exploreAction?['url']?.toString() ?? data['url']?.toString();
      if (url != null && url.isNotEmpty) {
        _openExternalLink(context, url);
      }
    } else if (type == 'whatsapp') {
      final number =
          exploreAction?['number']?.toString() ?? data['number']?.toString();
      final message =
          exploreAction?['message']?.toString() ?? data['message']?.toString();
      if (number != null && number.isNotEmpty) {
        _openWhatsApp(context, number, message ?? '');
      }
    }
  }

  String _extractId(dynamic item) {
    if (item is Map) return item['id']?.toString() ?? '';
    return item.toString();
  }

  Future<void> _openProduct(BuildContext context, String productId) async {
    if (productId.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('store_products')
          .doc(productId)
          .get();
      if (context.mounted) Navigator.pop(context);
      if (doc.exists) {
        final product = StoreProductModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        if (context.mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(product: product)));
        }
      } else {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Product not found.')));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load product.')));
    }
  }

  Future<void> _openService(BuildContext context, String serviceId) async {
    if (serviceId.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final doc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();
      if (context.mounted) Navigator.pop(context);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status = (data['status'] ?? '').toString().toLowerCase();
        if (status == 'inactive') {
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Service is no longer available.')));
          return;
        }

        final name = (data['service_name'] ?? 'Service').toString();
        final category = (data['category'] ?? '').toString();
        final image = (data['image_url'] ?? data['image'] ?? '').toString();
        final dynamic rawRating = data['rating'];
        double rating = 0.0;
        if (rawRating is num)
          rating = rawRating.toDouble();
        else if (rawRating is Map && rawRating['average'] is num)
          rating = rawRating['average'].toDouble();

        if (context.mounted) {
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
        }
      } else {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Service not found.')));
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load service.')));
    }
  }

  Future<void> _openExternalLink(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Could not open link.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid link.')));
      }
    }
  }

  Future<void> _openWhatsApp(
      BuildContext context, String number, String message) async {
    final urlString =
        'https://wa.me/$number?text=${Uri.encodeComponent(message)}';
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open WhatsApp.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Invalid WhatsApp number.')));
      }
    }
  }
}

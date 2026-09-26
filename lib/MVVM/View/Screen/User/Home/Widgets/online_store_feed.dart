import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/online_store_feed_controller.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Widgets/spotlight_campaign_section.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Widgets/online_store_product_card.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Widgets/online_store_horizontal_list.dart';
import 'package:naattulink/MVVM/View/Screen/User/Home/Widgets/online_store_promo_card.dart';
import 'package:naattulink/MVVM/model/seller/store_product_model.dart';
import 'package:naattulink/MVVM/utils/dynamic_theme_manager.dart';

class OnlineStoreFeed extends StatelessWidget {
  const OnlineStoreFeed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lazily initialize the controller
    final controller = Get.put(OnlineStoreFeedController());

    return Obx(() {
      if (controller.isLoading.value && controller.feedItems.isEmpty) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return SliverList.builder(
        itemCount:
            controller.feedItems.length + (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.feedItems.length) {
            // Trigger pagination before reaching the very end
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.loadMore();
            });
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = controller.feedItems[index];

          switch (item.type) {
            case FeedItemType.topAdBanner:
              return _buildTopAdBanner(item);
            case FeedItemType.banner:
              return _buildBanner(item);
            case FeedItemType.productGrid:
              return _buildProductGrid(item);
            case FeedItemType.horizontalProducts:
            case FeedItemType.suggestedForYou:
            case FeedItemType.dealsOfDay:
            case FeedItemType.brandsInSpotlight:
            case FeedItemType.flashDeals:
            case FeedItemType.popularNearby:
              return _buildGenericHorizontalList(item);
            case FeedItemType.topValueDeals:
              return _buildTopValueDeals(item);
            case FeedItemType.afternoonPicks:
              return _buildAfternoonPicks(item);
            case FeedItemType.spotlight:
              return const SpotlightCampaignSection(isOnlineStore: true);
            default:
              return const SizedBox.shrink();
          }
        },
      );
    });
  }

  Widget _buildTopAdBanner(OnlineFeedItem item) {
    // If your top ad banner was a Carousel, you can either inject it here or use PromoCard
    // Returning an empty shrink for now, because usually Homepage CustomScrollView has the top carousel directly before this feed.
    return const SizedBox.shrink();
  }

  Widget _buildBanner(OnlineFeedItem item) {
    if (item.items.isEmpty) return const SizedBox.shrink();
    final doc = item.items[0];
    final data = doc.data() as Map<String, dynamic>;

    return OnlineStorePromoCard(
      imageUrl: data['imageUrl'] ?? '',
      bannerImageUrl: data['bannerImageUrl'],
      title: data['title'] ?? '',
    );
  }

  Widget _buildProductGrid(OnlineFeedItem item) {
    // The existing 2-column grid format
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: item.items.length,
          itemBuilder: (context, index) {
            final product = item.items[index];
            return OnlineStoreProductCard(
              product: product,
              onTap: () {
                // Navigate to product details
                // This logic should eventually match Homepage's navigation
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGenericHorizontalList(OnlineFeedItem item) {
    IconData icon = Icons.local_offer;
    Color iconColor = Colors.blue;
    bool isFlash = false;

    if (item.type == FeedItemType.dealsOfDay) {
      icon = Icons.bolt;
      iconColor = Colors.orange;
    } else if (item.type == FeedItemType.brandsInSpotlight) {
      icon = Icons.star_border;
      iconColor = const Color(0xFF7C3AED);
    } else if (item.type == FeedItemType.flashDeals) {
      icon = Icons.local_offer;
      iconColor = Colors.red;
      isFlash = true;
    } else if (item.type == FeedItemType.popularNearby) {
      icon = Icons.location_on_outlined;
      iconColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: OnlineStoreHorizontalList(
        title: item.title,
        icon: icon,
        iconColor: iconColor,
        isFlash: isFlash,
        products: item.items.cast(),
      ),
    );
  }

  Widget _buildTopValueDeals(OnlineFeedItem item) {
    final topValueDeals = item.items.cast<StoreProductModel>();
    final storeTheme = DynamicThemeManager.generateTheme();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: storeTheme.sectionBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Value Deals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: storeTheme.textColor,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  "VALUE 365",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topValueDeals.length,
              itemBuilder: (context, index) {
                final p = topValueDeals[index];
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: p.coverImage.isNotEmpty
                                  ? Image.network(
                                      p.coverImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Container(color: Colors.grey[200]),
                                    )
                                  : Container(color: Colors.grey[200]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.hasDiscount
                              ? "${p.discountPercentage.round()}% Off"
                              : "₹${p.sellingPrice.round()}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAfternoonPicks(OnlineFeedItem item) {
    final products = item.items.cast<StoreProductModel>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FE),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Afternoon Picks for You",
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 145,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final String imageUrl = p.coverImage;

                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.image_outlined,
                                                color: Colors.grey, size: 30),
                                  )
                                : const Icon(Icons.image_outlined,
                                    color: Colors.grey, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.productName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.hasDiscount ? "Upgrade Now" : "Shop Now",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

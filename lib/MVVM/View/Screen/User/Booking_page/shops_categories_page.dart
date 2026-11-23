import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/food_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:get/get.dart';

class ShopsCategoriesPage extends StatefulWidget {
  const ShopsCategoriesPage({Key? key}) : super(key: key);

  @override
  State<ShopsCategoriesPage> createState() => _ShopsCategoriesPageState();
}

class _ShopsCategoriesPageState extends State<ShopsCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final Future<QuerySnapshot> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = FirebaseFirestore.instance
        .collection('businesses')
        .where('category', isEqualTo: 'Shops & Businesses')
        .get();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToListing(BuildContext context, String dbKey, String uiKey) {
    if (dbKey == "Restaurant") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FoodPage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GenericListingPage(title: uiKey.tr, profession: dbKey),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getAllCategories() {
    return [
      {
        'dbKey': 'Restaurant',
        'uiKey': 'shop_restaurant',
        'title': 'shop_restaurant'.tr,
        'subtitle': 'shop_restaurant_desc'.tr,
        'icon': Icons.restaurant_outlined,
      },
      {
        'dbKey': 'Bakery',
        'uiKey': 'shop_bakery',
        'title': 'shop_bakery'.tr,
        'subtitle': 'shop_bakery_desc'.tr,
        'icon': Icons.cake_outlined,
      },
      {
        'dbKey': 'Grocery',
        'uiKey': 'shop_grocery',
        'title': 'shop_grocery'.tr,
        'subtitle': 'shop_grocery_desc'.tr,
        'icon': Icons.local_grocery_store_outlined,
      },
      {
        'dbKey': 'Supermarket',
        'uiKey': 'shop_supermarket',
        'title': 'shop_supermarket'.tr,
        'subtitle': 'shop_supermarket_desc'.tr,
        'icon': Icons.store_outlined,
      },
      {
        'dbKey': 'Online Store',
        'uiKey': 'shop_online_store',
        'title': 'shop_online_store'.tr,
        'subtitle': 'shop_online_store_desc'.tr,
        'icon': Icons.shopping_cart_outlined,
      },
      {
        'dbKey': 'Fruits & Vegetables',
        'uiKey': 'shop_fruits_veg',
        'title': 'shop_fruits_veg'.tr,
        'subtitle': 'shop_fruits_veg_desc'.tr,
        'icon': Icons.eco_outlined,
      },
      {
        'dbKey': 'Meat & Fish',
        'uiKey': 'shop_meat_fish',
        'title': 'shop_meat_fish'.tr,
        'subtitle': 'shop_meat_fish_desc'.tr,
        'icon': Icons.set_meal_outlined,
      },
      {
        'dbKey': 'Stationery',
        'uiKey': 'shop_stationery',
        'title': 'shop_stationery'.tr,
        'subtitle': 'shop_stationery_desc'.tr,
        'icon': Icons.menu_book_outlined,
      },
      {
        'dbKey': 'Mobile Shop',
        'uiKey': 'shop_mobile',
        'title': 'shop_mobile'.tr,
        'subtitle': 'shop_mobile_desc'.tr,
        'icon': Icons.phone_android_outlined,
      },
      {
        'dbKey': 'Electronics',
        'uiKey': 'shop_electronics',
        'title': 'shop_electronics'.tr,
        'subtitle': 'shop_electronics_desc'.tr,
        'icon': Icons.electrical_services_outlined,
      },
      {
        'dbKey': 'Fashion',
        'uiKey': 'shop_fashion',
        'title': 'shop_fashion'.tr,
        'subtitle': 'shop_fashion_desc'.tr,
        'icon': Icons.checkroom_outlined,
      },
      {
        'dbKey': 'Footwear',
        'uiKey': 'shop_footwear',
        'title': 'shop_footwear'.tr,
        'subtitle': 'shop_footwear_desc'.tr,
        'icon': Icons.dry_cleaning_outlined,
      },
      {
        'dbKey': 'Jewellery',
        'uiKey': 'shop_jewellery',
        'title': 'shop_jewellery'.tr,
        'subtitle': 'shop_jewellery_desc'.tr,
        'icon': Icons.diamond_outlined,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PremiumAppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: AppBackButton(),
          ),
          centerTitle: true,
          title: Text(
            'shops_title'.tr,
            style: const TextStyle(
              color: Color(0xFF0F2E5A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error loading categories',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            final dynamicCategoriesMap = <String, Map<String, dynamic>>{};

            if (snapshot.hasData && snapshot.data != null) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final profession = data['profession'] as String?;
                final iconCode = data['category_icon'] as int?;

                if (profession != null && profession.isNotEmpty) {
                  if (!dynamicCategoriesMap.containsKey(profession)) {
                    dynamicCategoriesMap[profession] = {
                      'dbKey': profession,
                      'uiKey': profession,
                      'title': profession,
                      'subtitle': 'Explore $profession services',
                      'hasCustomIcon': iconCode != null,
                      'icon': iconCode != null
                          ? IconData(iconCode, fontFamily: 'MaterialIcons')
                          : Icons.storefront_outlined,
                    };
                  }
                }
              }
            }

            final allPredefinedCategories = _getAllCategories();

            final allCategories = dynamicCategoriesMap.values.map((dynamicCat) {
              final predefined = allPredefinedCategories.firstWhere(
                (c) => c['dbKey'] == dynamicCat['dbKey'],
                orElse: () => <String, dynamic>{},
              );

              if (predefined.isNotEmpty) {
                final bool hasCustomIcon = dynamicCat['hasCustomIcon'] == true;
                return {
                  'dbKey': predefined['dbKey'],
                  'uiKey': predefined['uiKey'],
                  'title': predefined['title'],
                  'subtitle': predefined['subtitle'],
                  'icon':
                      hasCustomIcon ? dynamicCat['icon'] : predefined['icon'],
                };
              }
              return dynamicCat;
            }).toList();

            final query = _searchQuery.trim().toLowerCase();
            final displayedCategories = query.isEmpty
                ? allCategories
                : allCategories.where((c) {
                    final title = (c['title'] ?? '').toString().toLowerCase();
                    final subtitle =
                        (c['subtitle'] ?? '').toString().toLowerCase();
                    final dbKey = (c['dbKey'] ?? '').toString().toLowerCase();
                    return title.contains(query) ||
                        subtitle.contains(query) ||
                        dbKey.contains(query);
                  }).toList();

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F2E5A).withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF0F2E5A), size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF94A3B8), size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),

                // Categories Grid
                Expanded(
                  child: displayedCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F2E5A)
                                      .withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_off_rounded,
                                    color: Color(0xFF0F2E5A), size: 36),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No categories match "$_searchQuery"',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: displayedCategories.length,
                          itemBuilder: (context, index) {
                            final c = displayedCategories[index];
                            return _buildCategoryCard(
                              context,
                              title: c['title'] as String,
                              subtitle: c['subtitle'] as String,
                              iconData: c['icon'] as IconData,
                              onTap: () => _navigateToListing(
                                context,
                                c['dbKey'] as String,
                                c['uiKey'] as String,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2E5A).withValues(alpha: 0.04),
              spreadRadius: 2,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE2E8F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2E5A).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(iconData, color: const Color(0xFF0F2E5A), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E5A),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

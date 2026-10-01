import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/food_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:get/get.dart';

class ShopsCategoriesPage extends StatelessWidget {
  const ShopsCategoriesPage({Key? key}) : super(key: key);

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
          builder: (_) => GenericListingPage(title: uiKey.tr),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumAppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        centerTitle: true,
        title: Text(
          'shops_title'.tr,
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildCategoryCard(
                  context,
                  title: 'shop_restaurant'.tr,
                  subtitle: 'shop_restaurant_desc'.tr,
                  iconData: Icons.restaurant_outlined,
                  onTap: () => _navigateToListing(
                      context, "Restaurant", "shop_restaurant"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_bakery'.tr,
                  subtitle: 'shop_bakery_desc'.tr,
                  iconData: Icons.cake_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Bakery", "shop_bakery"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_grocery'.tr,
                  subtitle: 'shop_grocery_desc'.tr,
                  iconData: Icons.local_grocery_store_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Grocery", "shop_grocery"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_supermarket'.tr,
                  subtitle: 'shop_supermarket_desc'.tr,
                  iconData: Icons.store_outlined,
                  onTap: () => _navigateToListing(
                      context, "Supermarket", "shop_supermarket"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_online_store'.tr,
                  subtitle: 'shop_online_store_desc'.tr,
                  iconData: Icons.shopping_cart_outlined,
                  onTap: () => _navigateToListing(
                      context, "Online Store", "shop_online_store"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_fruits_veg'.tr,
                  subtitle: 'shop_fruits_veg_desc'.tr,
                  iconData: Icons.eco_outlined,
                  onTap: () => _navigateToListing(
                      context, "Fruits & Vegetables", "shop_fruits_veg"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_meat_fish'.tr,
                  subtitle: 'shop_meat_fish_desc'.tr,
                  iconData: Icons.set_meal_outlined,
                  onTap: () => _navigateToListing(
                      context, "Meat & Fish", "shop_meat_fish"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_stationery'.tr,
                  subtitle: 'shop_stationery_desc'.tr,
                  iconData: Icons.menu_book_outlined,
                  onTap: () => _navigateToListing(
                      context, "Stationery", "shop_stationery"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_mobile'.tr,
                  subtitle: 'shop_mobile_desc'.tr,
                  iconData: Icons.phone_android_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Mobile Shop", "shop_mobile"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_electronics'.tr,
                  subtitle: 'shop_electronics_desc'.tr,
                  iconData: Icons.electrical_services_outlined,
                  onTap: () => _navigateToListing(
                      context, "Electronics", "shop_electronics"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_fashion'.tr,
                  subtitle: 'shop_fashion_desc'.tr,
                  iconData: Icons.checkroom_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Fashion", "shop_fashion"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_footwear'.tr,
                  subtitle: 'shop_footwear_desc'.tr,
                  iconData: Icons.dry_cleaning_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Footwear", "shop_footwear"),
                ),
                _buildCategoryCard(
                  context,
                  title: 'shop_jewellery'.tr,
                  subtitle: 'shop_jewellery_desc'.tr,
                  iconData: Icons.diamond_outlined,
                  onTap: () => _navigateToListing(
                      context, "Jewellery", "shop_jewellery"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ));
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
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2E5A).withOpacity(0.04),
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
                    color: const Color(0xFF0F2E5A).withOpacity(0.08),
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

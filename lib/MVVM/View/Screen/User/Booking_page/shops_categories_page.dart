import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/food_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class ShopsCategoriesPage extends StatelessWidget {
  const ShopsCategoriesPage({Key? key}) : super(key: key);

  void _navigateToListing(BuildContext context, String title) {
    if (title == "Restaurant") {
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
          builder: (_) => GenericListingPage(title: title),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        centerTitle: true,
        title: const Text(
          "Shops",
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
                  title: "Restaurant",
                  subtitle: "Dine-in, takeaway &\ndelivery",
                  iconData: Icons.restaurant_outlined,
                  onTap: () => _navigateToListing(context, "Restaurant"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Bakery",
                  subtitle: "Cakes, pastries &\nbreads",
                  iconData: Icons.cake_outlined,
                  onTap: () => _navigateToListing(context, "Bakery"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Grocery",
                  subtitle: "Daily essentials &\nprovisions",
                  iconData: Icons.local_grocery_store_outlined,
                  onTap: () => _navigateToListing(context, "Grocery"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Supermarket",
                  subtitle: "All your shopping in\none place",
                  iconData: Icons.store_outlined,
                  onTap: () => _navigateToListing(context, "Supermarket"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Online Store",
                  subtitle: "Shop online for\nhome delivery",
                  iconData: Icons.shopping_cart_outlined,
                  onTap: () => _navigateToListing(context, "Online Store"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Fruits & Vegetables",
                  subtitle: "Fresh farm\nproduce",
                  iconData: Icons.eco_outlined,
                  onTap: () => _navigateToListing(context, "Fruits & Vegetables"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Meat & Fish",
                  subtitle: "Fresh meat, poultry &\nseafood",
                  iconData: Icons.set_meal_outlined,
                  onTap: () => _navigateToListing(context, "Meat & Fish"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Stationery",
                  subtitle: "Office & school\nsupplies",
                  iconData: Icons.menu_book_outlined,
                  onTap: () => _navigateToListing(context, "Stationery"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Mobile Shop",
                  subtitle: "Smartphones &\naccessories",
                  iconData: Icons.phone_android_outlined,
                  onTap: () => _navigateToListing(context, "Mobile Shop"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Electronics",
                  subtitle: "Home appliances &\ngadgets",
                  iconData: Icons.electrical_services_outlined,
                  onTap: () => _navigateToListing(context, "Electronics"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Fashion",
                  subtitle: "Clothing &\napparel",
                  iconData: Icons.checkroom_outlined,
                  onTap: () => _navigateToListing(context, "Fashion"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Footwear",
                  subtitle: "Shoes, sandals &\nmore",
                  iconData: Icons.dry_cleaning_outlined,
                  onTap: () => _navigateToListing(context, "Footwear"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Jewellery",
                  subtitle: "Gold, silver &\nornaments",
                  iconData: Icons.diamond_outlined,
                  onTap: () => _navigateToListing(context, "Jewellery"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
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

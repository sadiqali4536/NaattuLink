import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/vehicles_auto_taxi_bookings/auto_taxi_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/pickup_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/jcbs_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class TransportationCategoriesPage extends StatelessWidget {
  const TransportationCategoriesPage({Key? key}) : super(key: key);

  void _navigateToListing(BuildContext context, String title) {
    if (title == "Auto Taxi") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AutoTaxiPage()),
      );
    } else if (title == "Pickup") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PickupPage()),
      );
    } else if (title == "JCB") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JcbsPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GenericListingPage(title: title)),
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
          "Transportation",
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
                  title: "Auto Taxi",
                  subtitle: "Quick rides &\nlocal drops",
                  iconData: Icons.local_taxi_outlined,
                  onTap: () => _navigateToListing(context, "Auto Taxi"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Pickup",
                  subtitle: "Goods transport &\nlogistics",
                  iconData: Icons.local_shipping_outlined,
                  onTap: () => _navigateToListing(context, "Pickup"),
                ),
                _buildCategoryCard(
                  context,
                  title: "JCB",
                  subtitle: "Earthmoving &\nheavy machinery",
                  imageAsset: "assets/icons/jcb.png",
                  onTap: () => _navigateToListing(context, "JCB"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Car Rental",
                  subtitle: "Self-drive &\nchauffeur cars",
                  iconData: Icons.car_rental_outlined,
                  onTap: () => _navigateToListing(context, "Car Rental"),
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
    IconData? iconData,
    String? imageAsset,
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
              child: imageAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(imageAsset,
                          color: const Color(0xFF0F2E5A)),
                    )
                  : Icon(iconData, color: const Color(0xFF0F2E5A), size: 28),
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

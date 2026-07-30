import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/helpline_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/generic_listing_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class PublicServicesCategoriesPage extends StatelessWidget {
  const PublicServicesCategoriesPage({Key? key}) : super(key: key);

  void _navigateToListing(BuildContext context, String title) {
    if (title == "Helpline") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelplinePage()),
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
          "Public Services",
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
                  title: "Helpline",
                  subtitle: "Emergency contacts &\nassistance",
                  iconData: Icons.support_agent_outlined,
                  onTap: () => _navigateToListing(context, "Helpline"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Government Offices",
                  subtitle: "Municipal, taluk &\nstate services",
                  iconData: Icons.account_balance_outlined,
                  onTap: () =>
                      _navigateToListing(context, "Government Offices"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Police",
                  subtitle: "Law enforcement &\nreporting",
                  iconData: Icons.local_police_outlined,
                  onTap: () => _navigateToListing(context, "Police"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Fire Station",
                  subtitle: "Fire rescue &\nemergencies",
                  iconData: Icons.fire_truck_outlined,
                  onTap: () => _navigateToListing(context, "Fire Station"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Post Office",
                  subtitle: "Mails, parcels &\nsavings",
                  iconData: Icons.local_post_office_outlined,
                  onTap: () => _navigateToListing(context, "Post Office"),
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

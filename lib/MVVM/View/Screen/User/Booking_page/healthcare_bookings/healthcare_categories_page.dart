import 'package:flutter/material.dart';
import 'healthcare_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';

class HealthcareCategoriesPage extends StatelessWidget {
  const HealthcareCategoriesPage({Key? key}) : super(key: key);

  void _navigateToListing(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthcarePage(
          healthcareType: title,
          pageTitle: title,
        ),
      ),
    );
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
        title: const Text(
          "Healthcare",
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
            // Grid for Main Categories
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
                  title: "Hospital",
                  subtitle: "Find nearby hospitals &\ntrauma centers",
                  iconData: Icons.local_hospital_outlined,
                  iconColor: const Color(0xFF0F2E5A),
                  iconBgColor: const Color(0xFFEEF2FF),
                  imagePath: 'assets/image/hospital.png',
                  onTap: () => _navigateToListing(context, "Hospital"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Clinic",
                  subtitle: "Specialized doctors &\nfamily clinics",
                  iconData: Icons.medical_services_outlined,
                  iconColor: const Color(0xFF0F2E5A),
                  imagePath: 'assets/image/clinick.png',
                  iconBgColor: const Color(0xFFEEF2FF),
                  onTap: () => _navigateToListing(context, "Clinic"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Pharmacy",
                  subtitle: "24/7 medicines &\nhealthcare supplies",
                  iconData: Icons.local_pharmacy_outlined,
                  iconColor: const Color(0xFF0F2E5A),
                  iconBgColor: const Color(0xFFEEF2FF),
                  imagePath: 'assets/image/pharmacy.png',
                  onTap: () => _navigateToListing(context, "Pharmacy"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Laboratory",
                  subtitle: "Blood tests & quick lab\nreports",
                  iconData: Icons.science_outlined,
                  iconColor: const Color(0xFF0F2E5A),
                  iconBgColor: const Color(0xFFEEF2FF),
                  imagePath: 'assets/image/laboratory.png',
                  onTap: () => _navigateToListing(context, "Laboratory"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Emergency & Specialized",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E5A),
              ),
            ),
            const SizedBox(height: 16),
            _buildEmergencyCard(context),
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
    Color iconColor = const Color(0xFF0F2E5A),
    Color iconBgColor = const Color(0xFFEEF2FF),
    String? imagePath,
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
                gradient: LinearGradient(
                  colors: [iconBgColor, const Color(0xFFE2E8F0)],
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
              child: imagePath != null
                  ? ClipOval(
                      child: Image.asset(
                        imagePath,
                        width: 54,
                        height: 54,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(iconData, color: iconColor, size: 28),
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

  Widget _buildEmergencyCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HealthcarePage(
              healthcareType: "Emergency Services",
              pageTitle: "Emergency Services",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFF0F0), const Color(0xFFFFEAEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.red.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/image/ambulance-emergency.jpg',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Emergency Services",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "24/7 immediate assistance",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
          ],
        ),
      ),
    );
  }
}

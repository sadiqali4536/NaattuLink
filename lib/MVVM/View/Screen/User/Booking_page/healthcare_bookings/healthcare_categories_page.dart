import 'package:flutter/material.dart';
import 'clinics_page.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class HealthcareCategoriesPage extends StatelessWidget {
  const HealthcareCategoriesPage({Key? key}) : super(key: key);

  void _navigateToListing(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicsPage(
          healthcareType: title,
          pageTitle: title,
        ),
      ),
    );
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
                  onTap: () => _navigateToListing(context, "Hospital"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Clinic",
                  subtitle: "Specialized doctors &\nfamily clinics",
                  iconData: Icons.medical_services_outlined,
                  iconColor: const Color(0xFF0F2E5A),
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
                  onTap: () => _navigateToListing(context, "Pharmacy"),
                ),
                _buildCategoryCard(
                  context,
                  title: "Laboratory",
                  subtitle: "Blood tests & quick lab\nreports",
                  iconData: Icons.science_outlined,
                  iconColor: const Color(0xFF0F2E5A),
                  iconBgColor: const Color(0xFFEEF2FF),
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
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
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
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 28),
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
      onTap: () => _navigateToListing(context, "Ambulance"),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.emergency, color: Colors.red.shade700, size: 28),
            const SizedBox(height: 20),
            const Text(
              "Ambulance",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E5A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "24/7 READY",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

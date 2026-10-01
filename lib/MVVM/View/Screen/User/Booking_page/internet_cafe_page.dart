import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:naattulink/MVVM/View/Screen/User/Booking_page/online_services/online_services_page.dart';
import 'package:get/get.dart';

class InternetCafePage extends StatefulWidget {
  const InternetCafePage({Key? key}) : super(key: key);

  @override
  State<InternetCafePage> createState() => _InternetCafePageState();
}

class _InternetCafePageState extends State<InternetCafePage> {
  void _navigateToListing(BuildContext context, String dbKey, String uiKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnlineServicesPage(serviceType: dbKey, pageTitle: uiKey.tr),
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
          title: Text(
            "online_services".tr,
            style: const TextStyle(
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
                    title: 'online_cafe_title'.tr,
                    subtitle: 'online_cafe_subtitle'.tr,
                    iconData: Icons.computer_outlined,
                    onTap: () => _navigateToListing(context, "Online Cafe", "online_cafe_title"),
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'akshaya_center_title'.tr,
                    subtitle: 'akshaya_center_subtitle'.tr,
                    iconData: Icons.account_balance_outlined,
                    onTap: () => _navigateToListing(context, "Akshaya Center", "akshaya_center_title"),
                  ),
                  _buildCategoryCard(
                    context,
                    title: 'dtp_title'.tr,
                    subtitle: 'dtp_subtitle'.tr,
                    iconData: Icons.print_outlined,
                    onTap: () => _navigateToListing(context, "DTP Center", "dtp_title"),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
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

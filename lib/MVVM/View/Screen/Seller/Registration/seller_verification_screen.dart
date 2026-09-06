import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';

class SellerVerificationScreen extends StatelessWidget {
  const SellerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Verify Account",
          style: TextStyle(
            color: Color(0xFF0A235C),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Center Graphic
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 10,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.find_in_page_outlined,
                          size: 50,
                          color: Color(0xFF0A235C),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(Colors.yellow[700]!),
                            const SizedBox(width: 4),
                            _buildDot(Colors.yellow[700]!),
                            const SizedBox(width: 4),
                            _buildDot(Colors.yellow[700]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Color(0xFF0A235C),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Main Text
            const Text(
              "Under Verification",
              style: TextStyle(
                color: Color(0xFF0A235C),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your account will be active within 24 hours. As\npart of our verification process, you will receive a\ncall from our team shortly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            // Progress Bar
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Progress",
                        style: TextStyle(
                          color: Color(0xFF0A235C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "50%",
                        style: TextStyle(
                          color: Color(0xFF0A235C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0A235C)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Partner Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      color: Colors.yellow[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Partner Welcome",
                          style: TextStyle(
                            color: Color(0xFF0A235C),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Thank you for partnering with NaattuLink. Welcome to a place to explore and increase your earnings.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Vertical Stepper
            _buildStepperItem(
              title: "Store Created",
              subtitle: "Completed",
              icon: Icons.store,
              iconBgColor: const Color(0xFF0A235C),
              iconColor: Colors.white,
              lineColor: const Color(0xFF0A235C),
              isLast: false,
            ),

            _buildStepperItem(
              title: "Admin Verification",
              subtitle: "In Progress",
              subtitleColor: Colors.yellow[700],
              icon: Icons.admin_panel_settings,
              iconBgColor: Colors.yellow[700]!,
              iconColor: const Color(0xFF0A235C),
              isLast: false,
            ),
            _buildStepperItem(
              title: "Store Activation",
              subtitle: "Expected in 24h",
              icon: Icons.verified_user_outlined,
              iconBgColor: Colors.transparent,
              iconColor: Colors.grey[400]!,
              borderColor: Colors.grey[300],
              isLast: true,
            ),

            const SizedBox(height: 40),

            // Contact Support Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement Contact Support Action
                  Get.snackbar(
                    "Contact Support",
                    "Support functionality will be available soon.",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Contact Support",
                  style: TextStyle(
                    color: Color(0xFF0A235C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepperItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    Color? borderColor,
    Color? subtitleColor,
    Color? lineColor,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: 2)
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: lineColor ?? Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                )
              else
                const SizedBox(height: 32),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor ?? Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

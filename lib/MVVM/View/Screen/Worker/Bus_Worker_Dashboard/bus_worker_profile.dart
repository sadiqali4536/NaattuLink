import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/auth_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/edit_bus_worker_profile.dart';

class BusWorkerProfile extends StatelessWidget {
  const BusWorkerProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely inject controller if not already present
    final controller = Get.put(BusDashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFF0C1F41), // Dark blue background
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.userData.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (controller.hasError.value || controller.userData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      color: Colors.white, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'No internet connection or data lost',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.initialize(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0C1F41),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = controller.userData;
          final userName = data['username'] ?? 'User';
          final phone = data['phone'] ?? 'N/A';
          final email = data['email'] ?? 'N/A';
          final category = data['role_with_vehicle'] ?? 'Bus Operator';
          final experience = data['experience'] ?? 'N/A';
          final profileImg = data['profile_img']?.toString() ?? '';

          return Column(
            children: [
              // Top Section
              Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                width: double.infinity,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF9A825),
                            width: 3), // Gold border
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white24,
                        backgroundImage: profileImg.isNotEmpty
                            ? NetworkImage(profileImg)
                            : null,
                        onBackgroundImageError: profileImg.isNotEmpty
                            ? (exception, stackTrace) {
                                // Suppress the exception so it doesn't pollute the console
                                debugPrint(
                                    'Failed to load profile image: $exception');
                              }
                            : null,
                        child: profileImg.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(userName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Bottom White Section
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Personal Details Card
                          _buildInfoCard(
                            title: 'Personal Details',
                            icon: Icons.person_outline,
                            children: [
                              _buildDetailRow('FULL NAME', userName),
                              const Divider(),
                              _buildDetailRow('MOBILE NUMBER', phone,
                                  hasTick: true),
                              const Divider(),
                              _buildDetailRow('EMAIL ADDRESS', email),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Professional Status Card
                          _buildInfoCard(
                            title: 'Professional Status',
                            icon: Icons.work_outline,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildStatusBadge(
                                          'PROFESSION', category)),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Settings List
                          _buildSettingsTile(
                              'Edit Profile', Icons.edit_outlined, onTap: () {
                            Get.to(() => const EditBusWorkerProfile());
                          }),
                          // _buildSettingsTile(
                          //     'Change Password', Icons.lock_outline),
                          // _buildSettingsTile('Notification Settings',
                          //     Icons.notifications_none),
                          _buildSettingsTile(
                              'Help & Support', Icons.help_outline),

                          const SizedBox(height: 32),
                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement logout
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout from Account',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF9A825), size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool hasTick = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              if (hasTick)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon,
      {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

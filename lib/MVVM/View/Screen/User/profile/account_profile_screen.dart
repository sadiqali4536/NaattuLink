import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/my_bookings.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/edit_profile.dart';
import 'package:naattulink/MVVM/controller/seller/seller_access_controller.dart';
import 'package:flutter/services.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({Key? key}) : super(key: key);

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginAndSigning()),
      (route) => false,
    );
  }

  Future<Map<String, String>?> _resolveUserIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final collections = [
      'healthcare',
      'businesses',
      'transport',
      'workers',
      'transports',
      'shops_businesses',
      'users'
    ];

    for (String collection in collections) {
      final doc = await getUserDocument(user, collection);
      if (doc != null && doc.exists) {
        return {'id': doc.id, 'collection': collection};
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Light icons for dark background
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: FutureBuilder<Map<String, String>?>(
          future: _resolveUserIdentity(),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F2E5A)));
            }

            if (!futureSnapshot.hasData || futureSnapshot.data == null) {
              return const Center(child: Text('User not found'));
            }

            final identity = futureSnapshot.data!;
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(identity['collection']!)
                  .doc(identity['id'])
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF0F2E5A)));
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final data =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    return _buildProfileContent(context, data);
                  }
                }

                return const Center(child: Text('Something went wrong'));
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data) {
    String username = data['username'] ?? 'No Name';
    String email = data['email'] ?? '';
    String phone = data['phone'] ?? '';
    String image = data['profile_img'] ?? '';
    String profession = data['profession'] ?? '';
    String role = data['role'] ?? '';
    String category = data['category'] ?? '';
    String facilityName = data['facility_name'] ?? '';
    String contactNumber = data['contact_number'] ?? data['phone'] ?? '';
    String availableTime = data['available_time'] ?? '';
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2E5A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 48),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.5), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: image.isNotEmpty
                            ? (image.startsWith('assets/')
                                ? AssetImage(image) as ImageProvider
                                : NetworkImage(image))
                            : const AssetImage('assets/icons/male_avathar.png'),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfile(
                                username: username,
                                email: email,
                                phone: phone,
                                image: image,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFC107),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Color(0xFFFFC107), size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                if (profession == "Emergency Services") ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_hospital,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          profession.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (category == 'Online services') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade600.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.computer,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          profession.isNotEmpty
                              ? profession.toUpperCase()
                              : "ONLINE SERVICES",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (role == 'healthcare' && profession == 'Emergency Services') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade700.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emergency_outlined,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          "Emergency Services",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Registered as an Emergency Service Provider",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (category == 'Online services') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade700.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.computer,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              profession.isNotEmpty
                                  ? profession
                                  : "Online Services",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            _showEditOnlineServicesDialog(context, data);
                          },
                          icon: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPharmacyInfoRow(Icons.business, "Facility",
                        facilityName.isNotEmpty ? facilityName : 'N/A'),
                    const SizedBox(height: 12),
                    _buildPharmacyInfoRow(Icons.phone_in_talk, "Contact",
                        contactNumber.isNotEmpty ? contactNumber : 'N/A'),
                    const SizedBox(height: 12),
                    _buildPharmacyInfoRow(Icons.access_time, "Time",
                        availableTime.isNotEmpty ? availableTime : 'N/A'),
                  ],
                ),
              ),
            ),
          ],

          if (role == 'healthcare' && profession == 'Pharmacy') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A235C),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A235C).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_pharmacy_outlined,
                                color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              "Pharmacy Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            _showEditPharmacyDialog(context, data);
                          },
                          icon: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPharmacyInfoRow(Icons.business, "Facility",
                        data['facility_name'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildPharmacyInfoRow(Icons.phone_in_talk, "Contact",
                        data['contact_number'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildPharmacyInfoRow(Icons.access_time, "Time",
                        data['available_time'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('My Activity'),
                _buildSectionContainer([
                  _buildListItem(
                    icon: Icons.rate_review_outlined,
                    title: 'My Reviews',
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('Earn With NaattuLink'),
                _buildSectionContainer([
                  _buildListItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Sell on NaattuLink',
                    subtitle: 'Start earning by listing your products',
                    onTap: () {
                      if (!Get.isRegistered<SellerAccessController>()) {
                        Get.put(SellerAccessController());
                      }
                      SellerAccessController.to.handleSellerNavigation();
                    },
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('Preferences'),
                _buildSectionContainer([
                  _buildListTileWithSwitch(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    trailingText: 'English',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListTileWithSwitch(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    value: _darkModeEnabled,
                    onChanged: (val) => setState(() => _darkModeEnabled = val),
                  ),
                ]),

                const SizedBox(height: 20),
                _buildSectionTitle('Support'),
                _buildSectionContainer([
                  _buildListItem(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    showArrow: false,
                    onTap: () => _handleLogout(context),
                  ),
                  _buildDivider(),
                  _buildListItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    showArrow: false,
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'NaattuLink App v1.0.1',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 120), // Bottom padding for navigation bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56, // Align with text
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    Color titleColor = const Color(0xFF0F2E5A),
    Color iconColor = const Color(0xFF0F2E5A),
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          if (trailingText != null) const SizedBox(width: 4),
          if (showArrow)
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildListTileWithSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0F2E5A), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F2E5A),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF0F2E5A),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildPharmacyInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showEditPharmacyDialog(
      BuildContext context, Map<String, dynamic> data) {
    final TextEditingController facilityCtrl =
        TextEditingController(text: data['facility_name'] ?? '');

    String currentContact = data['contact_number'] ?? '';
    if (currentContact.startsWith('+91')) {
      currentContact = currentContact.substring(3).trim();
    }
    final TextEditingController contactCtrl =
        TextEditingController(text: currentContact);

    String openTime = "10:00 AM";
    String closeTime = "05:00 PM";
    if (data['available_time'] != null) {
      final parts = data['available_time'].split('-');
      if (parts.length == 2) {
        openTime = parts[0].trim();
        closeTime = parts[1].trim();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Edit Pharmacy Details",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCustomTextField(
                        controller: facilityCtrl,
                        label: "Facility Name",
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 15),
                      _buildCustomTextField(
                        controller: contactCtrl,
                        label: "Contact Number",
                        icon: Icons.phone_in_talk,
                        keyboardType: TextInputType.phone,
                        prefixText: "+91 ",
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Available Time",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerCard(
                              context: context,
                              label: "Open",
                              time: openTime,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0F2E5A),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF0F2E5A),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    openTime = picked.format(context);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTimePickerCard(
                              context: context,
                              label: "Close",
                              time: closeTime,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0F2E5A),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF0F2E5A),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    closeTime = picked.format(context);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2E5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance
                                    .collection('healthcare')
                                    .doc(uid)
                                    .update({
                                  'facility_name': facilityCtrl.text.trim(),
                                  'contact_number':
                                      "+91${contactCtrl.text.trim()}",
                                  'available_time': "$openTime - $closeTime",
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditOnlineServicesDialog(
      BuildContext context, Map<String, dynamic> data) {
    final TextEditingController facilityCtrl =
        TextEditingController(text: data['facility_name'] ?? '');

    String currentContact = data['contact_number'] ?? '';
    if (currentContact.startsWith('+91')) {
      currentContact = currentContact.substring(3).trim();
    }
    final TextEditingController contactCtrl =
        TextEditingController(text: currentContact);

    String openTime = "10:00 AM";
    String closeTime = "05:00 PM";
    if (data['available_time'] != null) {
      final parts = data['available_time'].split('-');
      if (parts.length == 2) {
        openTime = parts[0].trim();
        closeTime = parts[1].trim();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: bottomInset + 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Update Online Services",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F2E5A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Modify your business details below.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildModernTextField(
                        controller: facilityCtrl,
                        label: "Facility Name",
                        icon: Icons.storefront_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: contactCtrl,
                        label: "Contact Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        prefixText: "+91 ",
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Working Hours",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTimePicker(
                              context: context,
                              label: "Opening Time",
                              time: openTime,
                              onTap: () async {
                                final TimeOfDay? picked =
                                    await _pickTime(context);
                                if (picked != null) {
                                  setState(
                                      () => openTime = picked.format(context));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernTimePicker(
                              context: context,
                              label: "Closing Time",
                              time: closeTime,
                              onTap: () async {
                                final TimeOfDay? picked =
                                    await _pickTime(context);
                                if (picked != null) {
                                  setState(
                                      () => closeTime = picked.format(context));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2E5A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance
                                  .collection('businesses')
                                  .doc(uid)
                                  .update({
                                'facility_name': facilityCtrl.text.trim(),
                                'contact_number':
                                    "+91${contactCtrl.text.trim()}",
                                'available_time': "$openTime - $closeTime",
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context) {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F2E5A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF0F2E5A), size: 22),
          prefixText: prefixText,
          prefixStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
          counterText: "",
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildModernTimePicker({
    required BuildContext context,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard({
    required BuildContext context,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A),
                  ),
                ),
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF0F2E5A)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF0F2E5A)),
        prefixText: prefixText,
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F2E5A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}

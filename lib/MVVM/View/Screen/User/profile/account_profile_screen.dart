import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/my_bookings.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/edit_profile.dart';
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

    var doc = await getUserDocument(user, 'users');
    if (doc != null && doc.exists) return {'id': doc.id, 'collection': 'users'};

    doc = await getUserDocument(user, 'healthcare');
    if (doc != null && doc.exists) {
      return {'id': doc.id, 'collection': 'healthcare'};
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
              ],
            ),
          ),

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
                    onTap: () {},
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
}

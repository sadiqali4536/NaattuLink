import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class EditProfile extends StatefulWidget {
  String username;
  String email;
  String phone;
  String image;
  EditProfile(
      {super.key,
      required this.email,
      required this.phone,
      required this.username,
      required this.image});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();

  String? _selectedAvatar;

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String imageUrl = widget.image;

    var doc = await getUserDocument(user, 'users');
    if (doc != null && doc.exists) {
      await FirebaseFirestore.instance.collection("users").doc(doc.id).update({
        "username": username.text.trim(),
        "phone": "+91${phone.text.trim()}",
        "email": email.text.trim(),
        "profile_img": imageUrl,
        "updated_at": FieldValue.serverTimestamp(),
      });
    } else {
      doc = await getUserDocument(user, 'healthcare');
      if (doc != null && doc.exists) {
        await FirebaseFirestore.instance
            .collection("healthcare")
            .doc(doc.id)
            .update({
          "username": username.text.trim(),
          "phone": "+91${phone.text.trim()}",
          "email": email.text.trim(),
          "profile_img": imageUrl,
          "updated_at": FieldValue.serverTimestamp(),
        });
      }
    }

    Navigator.pop(context);

    toastSuccess("Profile updated successfully");
  }

  @override
  void initState() {
    email.text = widget.email;
    phone.text = widget.phone.replaceAll('+91', '').trim();
    username.text = widget.username;

    if (widget.image == 'assets/icons/male_avathar.png' ||
        widget.image == 'assets/icons/female_avathar.png') {
      _selectedAvatar = widget.image;
    } else {
      _selectedAvatar = 'assets/icons/male_avathar.png';
      widget.image = _selectedAvatar!;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F2E5A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.8), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(_selectedAvatar!),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Choose Avatar Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Avatar',
                          style: TextStyle(
                            color: Color(0xFF0F2E5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildAvatarOption(
                              label: 'Male',
                              assetPath: 'assets/icons/male_avathar.png',
                              isSelected: _selectedAvatar ==
                                  'assets/icons/male_avathar.png',
                            ),
                            const SizedBox(width: 20),
                            _buildAvatarOption(
                              label: 'Female',
                              assetPath: 'assets/icons/female_avathar.png',
                              isSelected: _selectedAvatar ==
                                  'assets/icons/female_avathar.png',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Text Fields
                  _buildInputLabel('FULL NAME'),
                  _buildTextField(
                    controller: username,
                    icon: Icons.person_outline,
                    hintText: 'Full Name',
                  ),

                  const SizedBox(height: 16),

                  _buildInputLabel('MOBILE NUMBER'),
                  _buildTextField(
                    controller: phone,
                    icon: Icons.phone_outlined,
                    hintText: 'Mobile Number',
                    prefixText: '+91 ',
                  ),

                  const SizedBox(height: 16),

                  _buildInputLabel('EMAIL ADDRESS'),
                  _buildTextField(
                    controller: email,
                    icon: Icons.mail_outline,
                    hintText: 'Email Address',
                  ),

                  const SizedBox(height: 32),

                  // Action Cards
                  _buildActionCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {},
                  ),

                  const SizedBox(height: 12),

                  _buildActionCard(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2E5A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({
    required String label,
    required String assetPath,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAvatar = assetPath;
          widget.image = assetPath;
        });
      },
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F2E5A)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor:
                      const Color(0xFFEEF2FF), // light blueish grey
                  backgroundImage: AssetImage(assetPath),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC107),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child:
                        const Icon(Icons.check, size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0F2E5A) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF0F2E5A)),
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.black, fontSize: 16),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    Color titleColor = const Color(0xFF0F2E5A),
    Color iconColor = const Color(0xFF0F2E5A),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: titleColor == Colors.red ? Colors.red : Colors.grey,
                size: 14),
          ],
        ),
      ),
    );
  }
}

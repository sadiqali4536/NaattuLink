import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naattulink/MVVM/controller/seller/seller_access_controller.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class EditStoreProfileScreen extends StatefulWidget {
  const EditStoreProfileScreen({super.key});

  @override
  State<EditStoreProfileScreen> createState() => _EditStoreProfileScreenState();
}

class _EditStoreProfileScreenState extends State<EditStoreProfileScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final seller = SellerAccessController.to.currentSeller.value;
    if (seller != null) {
      _storeNameController.text = seller.storeName ?? "";
      _aboutController.text = seller.aboutBusiness ?? "";
      _phoneController.text = seller.phoneNumber.isNotEmpty
          ? seller.phoneNumber
          : (seller.phone ?? "");
      _locationController.text = seller.location ?? "";
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        toastError("User not logged in");
        return;
      }

      await FirebaseFirestore.instance.collection('sellers').doc(uid).update({
        'storeName': _storeNameController.text.trim(),
        'aboutBusiness': _aboutController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
      });

      await SellerAccessController.to.loadSeller(uid);
      Get.back();
      toastSuccess("Profile updated successfully");
    } catch (e) {
      toastError("Failed to update profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Edit Store Profile'),
        backgroundColor: const Color(0xFF0F2E5A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _storeNameController,
              label: 'Store Name',
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _aboutController,
              label: 'About Business',
              icon: Icons.info_outline,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2E5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
              bottom: maxLines > 1 ? (maxLines * 10).toDouble() : 0),
          child: Icon(icon, color: const Color(0xFF0F2E5A)),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F2E5A)),
        ),
      ),
    );
  }
}

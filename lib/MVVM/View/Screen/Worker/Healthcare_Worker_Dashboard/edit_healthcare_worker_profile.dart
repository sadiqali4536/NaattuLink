import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'controller/healthcare_dashboard_controller.dart';
import '../../../../utils/widget/backbutton/app_back_button.dart';

class EditHealthcareWorkerProfile extends StatefulWidget {
  const EditHealthcareWorkerProfile({super.key});

  @override
  State<EditHealthcareWorkerProfile> createState() =>
      _EditHealthcareWorkerProfileState();
}

class _EditHealthcareWorkerProfileState
    extends State<EditHealthcareWorkerProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();

  final HealthcareDashboardController _controller =
      HealthcareDashboardController.to;

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final userData = _controller.userData;
    _nameController.text = userData['facility_name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _areaController.text = userData['address'] ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updatedData = {
      'facility_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _areaController.text.trim(),
    };

    try {
      await _controller.updateUserProfile(updatedData, _selectedImage);

      if (mounted) {
        Get.back(); // Pop the page first
        if (Get.context != null) {
          CherryToast.success(
            title: const Text("Success",
                style: TextStyle(fontWeight: FontWeight.bold)),
            description: const Text("Profile updated successfully."),
            animationDuration: const Duration(milliseconds: 500),
            toastDuration: const Duration(seconds: 3),
          ).show(Get.context!);
        }
      }
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text("Error",
              style: TextStyle(fontWeight: FontWeight.bold)),
          description: Text(e.toString().replaceAll("Exception: ", "")),
          animationDuration: const Duration(milliseconds: 500),
          toastDuration: const Duration(seconds: 3),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentProfileImage =
        _controller.userData['profile_image'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A235C),
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              const Color(0xFF0A235C).withOpacity(0.1),
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (currentProfileImage.isNotEmpty
                                  ? NetworkImage(currentProfileImage)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null &&
                                  currentProfileImage.isEmpty
                              ? const Icon(Icons.person,
                                  size: 60, color: Color(0xFF0A235C))
                              : null,
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAB308),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _nameController,
                    label: "Name / Facility Name",
                    icon: Icons.business,
                    validator: (value) =>
                        value!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value!.isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _areaController,
                    label: "Area",
                    icon: Icons.location_on_outlined,
                    validator: (value) =>
                        value!.isEmpty ? 'Area is required' : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A235C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A235C)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: "Enter $label",
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF0A235C)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFF0A235C), width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

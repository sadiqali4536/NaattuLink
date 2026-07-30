import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';

class BusinessWorkerRegistrationPage extends StatefulWidget {
  const BusinessWorkerRegistrationPage({super.key});

  @override
  State<BusinessWorkerRegistrationPage> createState() =>
      _BusinessWorkerRegistrationPageState();
}

class _BusinessWorkerRegistrationPageState
    extends State<BusinessWorkerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _businessNameCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  String _category =
      "Restaurant"; // Restaurant, Bakery, Grocery, Retail, Supermarket, Online Store
  String _availableTime = "9 AM - 8 PM";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _businessNameCtrl.dispose();
    _contactNumberCtrl.dispose();
    super.dispose();
  }

  void _toastSuccess(String msg) {
    Get.snackbar("Success", msg,
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void _toastError(String msg) {
    Get.snackbar("Error", msg,
        backgroundColor: Colors.red, colorText: Colors.white);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = "${_mobileCtrl.text.trim()}@naattulink.com";
      final password = "NL${_mobileCtrl.text.trim()}";

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection("businesses").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": _mobileCtrl.text.trim(),
        "email": email,
        "role": "business",
        "category": "Shops & Businesses",
        "business_category": _category,
        "address": _addressCtrl.text.trim(),
        "business_name": _businessNameCtrl.text.trim(),
        "contact_number": _contactNumberCtrl.text.trim(),
        "available_time": _availableTime,
        "profile_img": "",
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": "pending",
        "services": [],
        "ratings": 0,
        "total_reviews": 0,
        "isVerified": 0,
        "password": password,
      });

      _toastSuccess("Account created successfully. Awaiting admin approval.");
      Get.back();
    } on FirebaseAuthException catch (e) {
      _toastError(FirebaseErrorHandler.getReadableErrorMessage(e));
    } catch (e) {
      _toastError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                _buildPhotoUpload(),
                const SizedBox(height: 32),
                _buildTextField("Full Name", "Enter your full name",
                    Icons.person_outline, _nameCtrl),
                _buildTextField("Mobile Number", "+91 00000 00000",
                    Icons.phone_outlined, _mobileCtrl,
                    type: TextInputType.phone),
                _buildTextField("Address", "Street name, Area, City",
                    Icons.location_on_outlined, _addressCtrl),
                const SizedBox(height: 20),
                const Text(
                  "Business Category",
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                const SizedBox(height: 24),
                _buildDivider("BUSINESS DETAILS"),
                const SizedBox(height: 16),
                _buildTextField("Business Name", "Enter business name",
                    Icons.domain_add_outlined, _businessNameCtrl),
                _buildTextField(
                    "Contact Number (Landline / Secondary)",
                    "Facility contact number",
                    Icons.phone_in_talk_outlined,
                    _contactNumberCtrl,
                    type: TextInputType.phone),
                const SizedBox(height: 8),
                _buildDropdownField(
                    "Available Time",
                    _availableTime,
                    Icons.access_time_outlined,
                    ["9 AM - 8 PM", "24 Hours", "Other"], (val) {
                  setState(() {
                    if (val != null) _availableTime = val;
                  });
                }),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A235C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Business Account',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        children: const [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                                color: Color(0xFF0A235C),
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBackButton(
              margin: EdgeInsets.zero,
              onPressed: () => Get.back(),
            ),
            const SizedBox(width: 16),
            const Text(
              "Create Account",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A235C)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Join us and enjoy the best business connectivity experience",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(1, "Basic", true),
        _stepLine(true),
        _stepCircle(2, "Details", true),
        _stepLine(false),
        _stepCircle(3, "Verify", false),
      ],
    );
  }

  Widget _stepCircle(int num, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF0A235C) : Colors.white,
            border: Border.all(
                color: isActive ? const Color(0xFF0A235C) : Colors.grey[300]!,
                width: 1.5),
          ),
          child: Center(
            child: Text(
              num.toString(),
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
              color: isActive ? const Color(0xFF0A235C) : Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _stepLine(bool isActive) {
    return Container(
      width: 40,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: isActive ? const Color(0xFF0A235C) : Colors.grey[300],
    );
  }

  Widget _buildPhotoUpload() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(
                      color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: Colors.grey[400], size: 24),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A235C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Upload Business Logo / Photo",
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, IconData? icon, TextEditingController ctrl,
      {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF0A235C),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            obscureText: isPassword,
            keyboardType: type,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required field' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.grey[400], size: 20)
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF0A235C))),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildRadioOption("Restaurant")),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Bakery")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRadioOption("Grocery")),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Retail")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRadioOption("Supermarket")),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Online Store")),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption(String value) {
    bool isSelected = _category == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _category = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? const Color(0xFF0A235C) : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0A235C)
                        : Colors.grey[300]!,
                    width: 4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                  color: isSelected ? const Color(0xFF0A235C) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.grey, fontSize: 10, letterSpacing: 0.5),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, IconData icon,
      List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Color(0xFF0A235C),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey, size: 20),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.grey[400], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

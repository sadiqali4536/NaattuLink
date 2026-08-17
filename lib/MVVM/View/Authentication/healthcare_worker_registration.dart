import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/healthcare_worker_dashboard.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
class HealthcareWorkerRegistrationPage extends StatefulWidget {
  const HealthcareWorkerRegistrationPage({super.key});

  @override
  State<HealthcareWorkerRegistrationPage> createState() =>
      _HealthcareWorkerRegistrationPageState();
}

class _HealthcareWorkerRegistrationPageState
    extends State<HealthcareWorkerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _facilityNameCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();

  String _category = "Hospital"; // Hospital, Clinic, Pharmacy, Laboratory
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    _facilityNameCtrl.dispose();
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

  Future<void> _selectTime(BuildContext context, bool isOpen) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A235C),
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (email.isEmpty || password.isEmpty) {
        _toastError("Email and Password are required.");
        setState(() => _isLoading = false);
        return;
      }

      if (_openTime == null || _closeTime == null) {
        _toastError("Open Time and Close Time are required.");
        setState(() => _isLoading = false);
        return;
      }

      print('[HEALTHCARE AUTH] Email entered: ${_emailCtrl.text.trim()}');
      print('[HEALTHCARE AUTH] Phone: ${_mobileCtrl.text.trim()}');
      print('[HEALTHCARE AUTH] Firebase email: $email');

      UserCredential userCredential;
      try {
        userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Attempt to sign in if the email already exists
          try {
            userCredential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (signInError) {
            _toastError(
                "This email is already registered. Please use the correct password, or try a different email.");
            setState(() => _isLoading = false);
            return;
          }
        } else {
          rethrow;
        }
      }
      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection("healthcare").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": "+91${_mobileCtrl.text.trim()}",
        "email": email,
        "role": "healthcare",
        "category": "Healthcare",
        "profession": _category,
        "facility_name": _facilityNameCtrl.text.trim(),
        "contact_number": "+91${_contactNumberCtrl.text.trim()}",
        "available_time":
            "${_formatTime(_openTime)} - ${_formatTime(_closeTime)}",
        "profile_img": "",
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "address": _addressCtrl.text.trim(),
        "status": "pending",
        "services": [],
        "ratings": 0,
        "total_reviews": 0,
        "isVerified": 0,
        "password": password,
      });

      _toastSuccess("Account created successfully. Awaiting admin approval.");
      if (_category == 'Pharmacy') {
        Get.offAll(() => const user_Dashboard());
      } else {
        Get.offAll(() => const HealthcareWorkerDashboard());
      }
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
                _buildTextField("Mobile Number", "00000 00000",
                    Icons.phone_outlined, _mobileCtrl,
                    type: TextInputType.phone,
                    prefixText: '+91 ',
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                  if (v == null || v.isEmpty) return 'Required field';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                    return 'Invalid 10-digit Indian mobile number';
                  }
                  return null;
                }),
                _buildTextField("Address", "Street name, Area, City",
                    Icons.location_on_outlined, _addressCtrl),
                const SizedBox(height: 20),
                const Text(
                  "Category",
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                _buildCategorySelector(),
                const SizedBox(height: 24),
                _buildDivider("${_category.toUpperCase()} DETAILS"),
                const SizedBox(height: 16),
                _buildTextField("Hospital / Clinic Name", "Enter facility name",
                    Icons.domain_add_outlined, _facilityNameCtrl),
                _buildTextField(
                    "Contact Number (Landline / Secondary)",
                    "00000 00000",
                    Icons.phone_in_talk_outlined,
                    _contactNumberCtrl,
                    type: TextInputType.phone,
                    prefixText: '+91 ',
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                  if (v == null || v.isEmpty) return 'Required field';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                    return 'Invalid 10-digit Indian mobile number';
                  }
                  return null;
                }),
                const SizedBox(height: 8),
                const Text(
                  "Available Time",
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTimePickerBox(true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimePickerBox(false)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDivider("ACCOUNT DETAILS"),
                const SizedBox(height: 16),
                _buildTextField("Email Address", "Enter your email",
                    Icons.email_outlined, _emailCtrl,
                    type: TextInputType.emailAddress),
                _buildTextField("Password", "Create a secure password",
                    Icons.lock_outline, _passwordCtrl,
                    isPassword: true),
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
                        : const Text('Create Healthcare Account',
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
          "Join us and enjoy the best healthcare connectivity experience",
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
      child: Stack(
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
                const SizedBox(height: 4),
                Text(
                  "Upload Photo",
                  style: TextStyle(color: Colors.grey[400], fontSize: 8),
                ),
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
    );
  }

  Widget _buildTextField(
      String label, String hint, IconData? icon, TextEditingController ctrl,
      {bool isPassword = false,
      TextInputType type = TextInputType.text,
      String? prefixText,
      int? maxLength,
      List<TextInputFormatter>? inputFormatters,
      String? Function(String?)? validator}) {
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
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            validator: validator ??
                (v) => v == null || v.trim().isEmpty ? 'Required field' : null,
            decoration: InputDecoration(
              counterText: "",
              hintText: hint,
              prefixText: prefixText,
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
            Expanded(child: _buildRadioOption("Hospital")),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Clinic")),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRadioOption("Pharmacy")),
            const SizedBox(width: 12),
            Expanded(child: _buildRadioOption("Laboratory")),
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

  Widget _buildTimePickerBox(bool isOpen) {
    return GestureDetector(
      onTap: () => _selectTime(context, isOpen),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOpen ? "Open" : "Close",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              _formatTime(isOpen ? _openTime : _closeTime),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class EditBusWorkerProfile extends StatefulWidget {
  const EditBusWorkerProfile({Key? key}) : super(key: key);

  @override
  State<EditBusWorkerProfile> createState() => _EditBusWorkerProfileState();
}

class _EditBusWorkerProfileState extends State<EditBusWorkerProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _experienceController;
  late TextEditingController _roleController;
  String? _arrivalTime;
  String? _departureTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = BusDashboardController.to.userData;
    _nameController = TextEditingController(text: data['username'] ?? '');
    _phoneController = TextEditingController(text: data['phone'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _experienceController =
        TextEditingController(text: data['experience'] ?? '');
    _roleController =
        TextEditingController(text: data['role_with_vehicle'] ?? '');
    _arrivalTime = data['arrival_time'];
    _departureTime = data['departure_time'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated");

      await FirebaseFirestore.instance
          .collection('transports')
          .doc(uid)
          .update({
        'username': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'experience': _experienceController.text.trim(),
        'role_with_vehicle': _roleController.text.trim(),
        if (_arrivalTime != null) 'arrival_time': _arrivalTime,
        if (_departureTime != null) 'departure_time': _departureTime,
      });

      // Refresh controller data
      await BusDashboardController.to.refreshData();

      if (mounted) {
        CherryToast.success(
          title: const Text("Profile updated successfully"),
        ).show(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: Text("Failed to update profile: $e"),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Mobile Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                          return 'Invalid 10-digit Indian mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _roleController,
                      label: 'Role with the vehicle',
                      icon: Icons.work_outline,
                    ),
                    const SizedBox(height: 24),
                    const Text('Schedule',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0C1F41))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Arrival Time',
                            time: _arrivalTime,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Departure Time',
                            time: _departureTime,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C1F41),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        counterText: "",
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: const Color(0xFFF9A825)),
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
          borderSide: const BorderSide(color: Color(0xFF0C1F41)),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool isArrival) async {
    final p = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
              child: Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFF0A235C),
                          onSurface: Color(0xFF0A235C))),
                  child: child!),
            ));
    if (p != null) {
      final h = p.hour == 0 ? 12 : (p.hour > 12 ? p.hour - 12 : p.hour);
      final m = p.minute.toString().padLeft(2, '0');
      final period = p.hour >= 12 ? 'PM' : 'AM';
      final formatted = '${h.toString().padLeft(2, '0')}:$m $period';
      setState(() {
        if (isArrival) {
          _arrivalTime = formatted;
        } else {
          _departureTime = formatted;
        }
      });
    }
  }

  Widget _buildTimePicker(
      {required String label,
      required String? time,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFFF9A825)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(time ?? '--:--',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

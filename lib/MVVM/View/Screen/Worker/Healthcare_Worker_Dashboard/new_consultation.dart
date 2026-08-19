import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/controller/healthcare_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/add_new_doctor.dart';

class NewConsultationPage extends StatefulWidget {
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const NewConsultationPage({super.key, this.editDocId, this.editData});

  @override
  State<NewConsultationPage> createState() => _NewConsultationPageState();
}

class _NewConsultationPageState extends State<NewConsultationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();

  List<String> _points = [];
  String _currentDocId = '';

  bool get _isLaboratory {
    if (Get.isRegistered<HealthcareDashboardController>()) {
      final user = HealthcareDashboardController.to.userData;
      final profession = user['profession']?.toString().toLowerCase() ?? '';
      return profession == 'laboratory';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentDocId = widget.editDocId ?? '';
    if (widget.editData != null) {
      _titleCtrl.text =
          widget.editData!['title'] ?? widget.editData!['classification'] ?? '';
      String mobile = widget.editData!['mobile'] ?? '';
      if (mobile.startsWith('+91')) {
        _mobileCtrl.text = mobile.substring(3);
      } else {
        _mobileCtrl.text = mobile;
      }
      _descCtrl.text =
          widget.editData!['description'] ?? widget.editData!['notes'] ?? '';
      _priceCtrl.text = widget.editData!['price']?.toString() ?? '';
      _categoryCtrl.text = widget.editData!['category'] ?? '';

      if (widget.editData!['points'] is List) {
        _points = List<String>.from(widget.editData!['points']);
      } else if (widget.editData!['points'] != null) {
        _pointsCtrl.text = widget.editData!['points'].toString();
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _mobileCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<String?> _saveConsultationData() async {
    if (!_formKey.currentState!.validate()) return null;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated.");

      final data = {
        "title": _titleCtrl.text.trim(),
        "status": "scheduled",
        "updated_at": FieldValue.serverTimestamp(),
      };

      if (_isLaboratory) {
        data["category"] = _categoryCtrl.text.trim();
        data["price"] = _priceCtrl.text.trim();
        data["points"] = _points;
      } else {
        data["description"] = _descCtrl.text.trim();
        data["mobile"] = "+91${_mobileCtrl.text.trim()}";
      }

      if (_currentDocId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('healthcare')
            .doc(uid)
            .collection('consultations')
            .doc(_currentDocId)
            .update(data);
        return _currentDocId;
      } else {
        data["created_at"] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance
            .collection('healthcare')
            .doc(uid)
            .collection('consultations')
            .add(data);
        return docRef.id;
      }
    } on FirebaseException catch (e) {
      _toastError(e.message ?? "Firebase error occurred.");
    } catch (e) {
      _toastError("Failed to save consultation: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    return null;
  }

  Future<void> _createConsultation() async {
    String? savedId = await _saveConsultationData();
    if (savedId != null) {
      try {
        if (Get.isRegistered<HealthcareDashboardController>()) {
          HealthcareDashboardController.to.refreshData();
        }
      } catch (_) {}

      Get.back(); // Pop the page first

      _toastSuccess(widget.editDocId != null
          ? "Consultation updated successfully."
          : "Consultation created successfully.");
    }
  }

  Future<void> _onAddDoctorPressed() async {
    String? savedId = await _saveConsultationData();
    if (savedId != null) {
      setState(() {
        _currentDocId = savedId;
      });
      Get.to(() => AddNewDoctorPage(consultationId: savedId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A235C),
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.editDocId != null
              ? (_isLaboratory ? "Edit Test" : "Edit Consultation")
              : (_isLaboratory ? "Add New Test" : "New Consultation"),
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLaboratory) ...[
                  _buildTextField(
                    "TEST NAME",
                    "e.g. Complete Blood Count (CBC)",
                    Icons.biotech,
                    _titleCtrl,
                  ),
                  _buildTextField(
                    "TEST CATEGORY",
                    "e.g. Hematology",
                    Icons.category,
                    _categoryCtrl,
                  ),
                  _buildTextField(
                    "PRICE (₹)",
                    "e.g. 500",
                    Icons.currency_rupee,
                    _priceCtrl,
                    type: TextInputType.number,
                  ),
                  _buildPointsInput(),
                ] else ...[
                  _buildTextField(
                    "CONSULTATION NAME / TITLE",
                    "e.g. General Consultation",
                    Icons.title,
                    _titleCtrl,
                  ),
                  _buildTextField(
                    "MOBILE NUMBER",
                    "00000 00000",
                    Icons.phone_outlined,
                    _mobileCtrl,
                    type: TextInputType.phone,
                    prefixText: "+91 ",
                    maxLength: 10,
                  ),
                  _buildTextField(
                    "DESCRIPTION",
                    "Enter symptoms, preliminary diagnosis, or special instructions...",
                    null,
                    _descCtrl,
                    maxLines: 4,
                    isRequired: false,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFEAB308), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLaboratory
                            ? "By creating this test, you verify that patient information is handled according to NaattuLink Laboratory's privacy protocols."
                            : "By creating this consultation, you verify that patient information is handled according to NaattuLink Clinic's healthcare privacy protocols.",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createConsultation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.editDocId != null
                                    ? (_isLaboratory
                                        ? 'Update Test'
                                        : 'Update Consultation')
                                    : (_isLaboratory
                                        ? 'Add New Test'
                                        : 'Create Consultation'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              text: "INCLUDES",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _pointsCtrl,
                  decoration: InputDecoration(
                    hintText: "Enter include...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(Icons.star_outline_rounded,
                        color: Colors.grey[400], size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF0A235C))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final point = _pointsCtrl.text.trim();
                  if (point.isNotEmpty) {
                    setState(() {
                      _points.add(point);
                      _pointsCtrl.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A235C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (_points.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Added Includes:",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _points.asMap().entries.map((entry) {
                int idx = entry.key;
                String point = entry.value;
                return Chip(
                  label: Text(point, style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _points.removeAt(idx);
                    });
                  },
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide(color: Colors.grey[300]!),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, IconData? icon, TextEditingController ctrl,
      {TextInputType type = TextInputType.text,
      String? prefixText,
      int? maxLength,
      int maxLines = 1,
      bool isRequired = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: type,
            maxLength: maxLength,
            maxLines: maxLines,
            validator: (v) {
              if (isRequired && (v == null || v.trim().isEmpty))
                return 'Required field';
              return null;
            },
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF0A235C))),
            ),
          ),
        ],
      ),
    );
  }

  void _toastSuccess(String msg) {
    if (Get.context != null) {
      CherryToast.success(
        title: const Text("Success",
            style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(msg),
        animationDuration: const Duration(milliseconds: 500),
        toastDuration: const Duration(seconds: 3),
      ).show(Get.context!);
    }
  }

  void _toastError(String msg) {
    if (Get.context != null) {
      CherryToast.error(
        title:
            const Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
        description: Text(msg),
        animationDuration: const Duration(milliseconds: 500),
        toastDuration: const Duration(seconds: 3),
      ).show(Get.context!);
    }
  }
}

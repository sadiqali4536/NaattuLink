import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/available_doctors_list.dart';

class AddNewDoctorPage extends StatefulWidget {
  final String? consultationId;
  final String? editDocId;
  final Map<String, dynamic>? editData;

  const AddNewDoctorPage({
    super.key,
    this.consultationId,
    this.editDocId,
    this.editData,
  });

  @override
  State<AddNewDoctorPage> createState() => _AddNewDoctorPageState();
}

class _AddNewDoctorPageState extends State<AddNewDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _qualificationCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullDaysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<bool> _selectedDays = List.generate(7, (index) => false);

  bool _isSpecificDateEnabled = false;
  DateTime? _specificDate;
  TimeOfDay? _specificDateStart;
  TimeOfDay? _specificDateEnd;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      _qualificationCtrl.text = widget.editData!['SPECIALIZATION'] ?? '';
      _nameCtrl.text = widget.editData!['name'] ?? '';
      String mobile = widget.editData!['mobile'] ?? '';
      if (mobile.startsWith('+91')) {
        mobile = mobile.substring(3).trim();
      }
      _mobileCtrl.text = mobile;
      _feesCtrl.text = widget.editData!['fees']?.toString() ?? '';

      if (widget.editData!['start_time'] != null) {
        _startTime = _parseTimeOfDay(widget.editData!['start_time']);
      }
      if (widget.editData!['end_time'] != null) {
        _endTime = _parseTimeOfDay(widget.editData!['end_time']);
      }

      if (widget.editData!['days'] != null) {
        List<dynamic> days = widget.editData!['days'];
        for (int i = 0; i < _fullDaysOfWeek.length; i++) {
          if (days.contains(_fullDaysOfWeek[i])) {
            _selectedDays[i] = true;
          }
        }
      }

      if (widget.editData!['specific_date'] != null) {
        _isSpecificDateEnabled = true;
        _specificDate =
            DateTime.tryParse(widget.editData!['specific_date']['date']);
        _specificDateStart =
            _parseTimeOfDay(widget.editData!['specific_date']['start']);
        _specificDateEnd =
            _parseTimeOfDay(widget.editData!['specific_date']['end']);
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts.length > 1) {
        if (parts[1].toUpperCase() == 'PM' && hour != 12) {
          hour += 12;
        } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
          hour = 0;
        }
      }
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _qualificationCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _feesCtrl.dispose();
    super.dispose();
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

  Future<void> _selectTime(BuildContext context, bool isStart) async {
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
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
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

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      _toastError("Please select consultation hours.");
      return;
    }

    final selectedDaysList = <String>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedDaysList.add(_fullDaysOfWeek[i]);
      }
    }

    if (selectedDaysList.isEmpty && !_isSpecificDateEnabled) {
      _toastError("Please select practice days or a specific date.");
      return;
    }

    if (_isSpecificDateEnabled) {
      if (_specificDate == null ||
          _specificDateStart == null ||
          _specificDateEnd == null) {
        _toastError("Please complete the specific date selection.");
        return;
      }
      final sMin = _specificDateStart!.hour * 60 + _specificDateStart!.minute;
      final eMin = _specificDateEnd!.hour * 60 + _specificDateEnd!.minute;
      if (eMin <= sMin) {
        _toastError("Specific date end time must be after start time.");
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not authenticated.");

      CollectionReference docRef = FirebaseFirestore.instance
          .collection('healthcare')
          .doc(uid)
          .collection('doctors');

      Map<String, dynamic> data = {
        "SPECIALIZATION": _qualificationCtrl.text.trim(),
        "name": _nameCtrl.text.trim(),
        "mobile": "+91${_mobileCtrl.text.trim()}",
        "fees": _feesCtrl.text.trim(),
        "start_time": _formatTime(_startTime),
        "end_time": _formatTime(_endTime),
        "days": selectedDaysList,
        "status": "active",
        if (widget.consultationId != null)
          "consultationId": widget.consultationId,
      };

      if (_isSpecificDateEnabled) {
        data['specific_date'] = {
          'date': _specificDate!.toIso8601String(),
          'start': _formatTime(_specificDateStart),
          'end': _formatTime(_specificDateEnd),
        };
      } else if (widget.editDocId != null) {
        data['specific_date'] = FieldValue.delete();
      }

      if (widget.editDocId != null) {
        data["updated_at"] = FieldValue.serverTimestamp();
        await docRef.doc(widget.editDocId).update(data);
      } else {
        data["created_at"] = FieldValue.serverTimestamp();
        await docRef.add(data);
      }

      Get.back(); // Pop the page first

      // Show toast after popping so Get.back() doesn't just close the snackbar
      if (widget.editDocId != null) {
        _toastSuccess("Doctor updated successfully.");
      } else {
        _toastSuccess("Doctor registered successfully.");
      }
    } catch (e) {
      _toastError("Failed to register doctor: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text(
          "Add New Doctor",
          style: TextStyle(
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
                _buildTextField(
                  "DOCTOR/FACILITY NAME",
                  "Enter doctor's full name",
                  Icons.person_outline,
                  _nameCtrl,
                ),
                _buildTextField(
                  "DOCTOR SPECIALIZATION",
                  "e.g. Cardiologist, Dentist",
                  Icons.medical_services_outlined,
                  _qualificationCtrl,
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
                RichText(
                  text: const TextSpan(
                    text: "CONSULTATION HOURS",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTimePicker(true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimePicker(false)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  "CONSULTATION FEES",
                  "0.00",
                  Icons.currency_rupee,
                  _feesCtrl,
                  type: TextInputType.number,
                ),
                RichText(
                  text: const TextSpan(
                    text: "PRACTICE DAYS",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDaysSelector(),
                const SizedBox(height: 24),
                _buildSpecificDateSection(),
                const SizedBox(height: 24),
                const Text(
                  "MEDICAL LICENSE / CERTIFICATION",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Colors.grey[300]!, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.document_scanner_outlined,
                          color: Color(0xFF0A235C), size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        "Upload License or Cert",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0A235C)),
                      ),
                      Text(
                        "Max size 5MB (JPG, PNG, PDF)",
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFEAB308), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "By registering this doctor, you verify that all medical credentials provided are authentic and compliant with healthcare regulatory standards.",
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
                    onPressed: _isLoading ? null : _registerDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Register Doctor',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.person_add_alt_1,
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

  Widget _buildTimePicker(bool isStart) {
    return GestureDetector(
      onTap: () => _selectTime(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isStart ? "Start" : "End",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              _formatTime(isStart ? _startTime : _endTime),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF0A235C) : Colors.white,
              border: Border.all(
                  color:
                      isSelected ? const Color(0xFF0A235C) : Colors.grey[300]!),
            ),
            child: Text(
              _daysOfWeek[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(
      String label, String hint, IconData? icon, TextEditingController ctrl,
      {TextInputType type = TextInputType.text,
      String? prefixText,
      int? maxLength}) {
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
              children: const [
                TextSpan(
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
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required field' : null,
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

  Widget _buildSpecificDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isSpecificDateEnabled,
              onChanged: (v) {
                setState(() {
                  _isSpecificDateEnabled = v ?? false;
                });
              },
              activeColor: const Color(0xFF0A235C),
            ),
            const Text(
              "Specific Date",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF0A235C)),
            ),
          ],
        ),
        if (_isSpecificDateEnabled)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _pickSpecificDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _specificDate != null
                              ? "${_specificDate!.day}/${_specificDate!.month}/${_specificDate!.year}"
                              : "Select Date",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _specificDate != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            size: 16, color: Color(0xFF0A235C)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePickerField(
                        label: "Start Time",
                        time: _specificDateStart,
                        onTap: () => _pickSpecificTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePickerField(
                        label: "End Time",
                        time: _specificDateEnd,
                        onTap: () => _pickSpecificTime(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimePickerField(
      {required String label,
      required TimeOfDay? time,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              time != null ? time.format(context) : "Select",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: time != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSpecificDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A235C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _specificDate = picked;
      });
    }
  }

  Future<void> _pickSpecificTime(bool isStart) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (isStart && _specificDateStart != null)
      initialTime = _specificDateStart!;
    if (!isStart && _specificDateEnd != null) initialTime = _specificDateEnd!;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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
        if (isStart) {
          _specificDateStart = picked;
          if (_specificDateEnd == null) {
            _specificDateEnd = const TimeOfDay(hour: 17, minute: 0);
          }
        } else {
          _specificDateEnd = picked;
          if (_specificDateStart == null) {
            _specificDateStart = const TimeOfDay(hour: 9, minute: 0);
          }
        }

        if (_specificDateStart != null && _specificDateEnd != null) {
          final startMin =
              _specificDateStart!.hour * 60 + _specificDateStart!.minute;
          final endMin = _specificDateEnd!.hour * 60 + _specificDateEnd!.minute;

          if (endMin <= startMin) {
            _toastError("End time must be after start time");
            if (isStart) {
              _specificDateStart =
                  initialTime == TimeOfDay.now() ? null : initialTime;
            } else {
              _specificDateEnd =
                  initialTime == TimeOfDay.now() ? null : initialTime;
            }
          }
        }
      });
    }
  }
}

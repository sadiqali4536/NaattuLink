import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_toast/cherry_toast.dart';

class AddNewBusScreen extends StatefulWidget {
  final bool isEdit;
  final String? busId;
  final bool isMainBus;
  final Map<String, dynamic>? initialData;

  const AddNewBusScreen({
    Key? key,
    this.isEdit = false,
    this.busId,
    this.isMainBus = false,
    this.initialData,
  }) : super(key: key);

  @override
  State<AddNewBusScreen> createState() => _AddNewBusScreenState();
}

class _AddNewBusScreenState extends State<AddNewBusScreen> {
  String? _selectedBusType;
  String? _selectedServiceType;
  bool _isLoading = true;
  List<String> _busTypes = ['Private Bus', 'KSRTC'];
  bool _isBusTypeLocked = false;

  bool _isSaving = false;
  bool _isActive = true;

  final TextEditingController _departureTimeController =
      TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _busNameController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _startPlaceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    _busNameController.dispose();
    _regNumberController.dispose();
    _startPlaceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.initialData != null) {
      final data = widget.initialData!;
      _selectedBusType = data['bus_type'];
      _selectedServiceType = data['service_type'];
      _busNameController.text = data['bus_name'] ?? '';

      if (widget.isMainBus) {
        _regNumberController.text = data['reg_number'] ?? '';
        _startPlaceController.text = data['first_stop'] ?? '';
      } else {
        _regNumberController.text = data['registration_number'] ?? '';
        _startPlaceController.text = data['start_place'] ?? '';
      }

      _destinationController.text = data['destination'] ?? '';
      _departureTimeController.text = data['departure_time'] ?? '';
      _arrivalTimeController.text = data['arrival_time'] ?? '';
      _isActive = data['status'] == null || data['status'] == 'ACTIVE';
    }
    _fetchWorkerData();
  }

  Future<void> _fetchWorkerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('transports')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null &&
              data['bus_type'] != null &&
              data['bus_type'].toString().isNotEmpty) {
            setState(() {
              _busTypes = [data['bus_type']];
              _selectedBusType = data['bus_type'];
              _isBusTypeLocked = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching worker data: $e');
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
      backgroundColor:
          const Color(0xFF0C1F41), // Dark blue background for header
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEdit ? 'Edit Bus' : 'Add New Bus',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('BUS INFORMATION'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Bus Name',
                        hint: 'Enter bus name',
                        icon: Icons.directions_bus_outlined,
                        controller: _busNameController),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Bus Registration Number',
                        hint: 'Enter bus registration number',
                        icon: Icons.numbers,
                        controller: _regNumberController,
                        textCapitalization: TextCapitalization.characters),
                    const SizedBox(height: 16),
                    _buildBusTypeDropdown(),
                    if (_selectedBusType != null) ...[
                      const SizedBox(height: 16),
                      _buildServiceTypeDropdown(),
                    ],
                    const SizedBox(height: 32),

                    _buildSectionTitle('ROUTE INFORMATION'),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Start Place',
                        hint: 'Enter start place',
                        icon: Icons.location_on_outlined,
                        controller: _startPlaceController),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Destination',
                        hint: 'Enter destination',
                        icon: Icons.location_on_outlined,
                        controller: _destinationController),

                    const SizedBox(height: 32),
                    _buildSectionTitle('SCHEDULE'),
                    const SizedBox(height: 16),

                    _buildTextField(
                        label: 'Departure Time',
                        hint: 'Select time',
                        icon: Icons.access_time,
                        controller: _departureTimeController,
                        onTap: () =>
                            _selectTime(context, _departureTimeController),
                        isReadOnly: true),
                    const SizedBox(height: 16),
                    _buildTextField(
                        label: 'Arrival Time',
                        hint: 'Select time',
                        icon: Icons.access_time,
                        controller: _arrivalTimeController,
                        onTap: () =>
                            _selectTime(context, _arrivalTimeController),
                        isReadOnly: true),

                    const SizedBox(height: 32),
                    _buildSectionTitle('STATUS'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isActive = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? const Color(0xFF0C1F41)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isActive
                                      ? const Color(0xFF0C1F41)
                                      : Colors.grey[400]!,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  color:
                                      _isActive ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isActive = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    !_isActive ? Colors.red : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isActive
                                      ? Colors.red
                                      : Colors.grey[400]!,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Inactive',
                                style: TextStyle(
                                  color: !_isActive
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C1F41), // Dark blue
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(widget.isEdit ? 'Update Bus' : 'Add Bus',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _saveBus() async {
    if (_busNameController.text.trim().isEmpty ||
        _regNumberController.text.trim().isEmpty ||
        _startPlaceController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty ||
        _departureTimeController.text.trim().isEmpty ||
        _arrivalTimeController.text.trim().isEmpty ||
        _selectedBusType == null ||
        _selectedServiceType == null) {
      CherryToast.error(
        title: const Text('Please fill all required fields'),
      ).show(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await FirebaseFirestore.instance
          .collection('transports')
          .doc(user.uid)
          .get();
      String ownerName = '';
      String ownerPhone = '';
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        ownerName = data['username'] ?? '';
        ownerPhone = data['phone'] ?? '';
      }

      final Map<String, dynamic> busData = {
        "transport_category": "Bus",
        "bus_type": _selectedBusType,
        "service_type": _selectedServiceType,
        "bus_name": _busNameController.text.trim(),
        "destination": _destinationController.text.trim(),
        "departure_time": _departureTimeController.text.trim(),
        "arrival_time": _arrivalTimeController.text.trim(),
        "status": _isActive ? "ACTIVE" : "INACTIVE",
      };

      if (widget.isEdit && widget.isMainBus) {
        // Main bus uses different keys
        busData["reg_number"] = _regNumberController.text.trim();
        busData["first_stop"] = _startPlaceController.text.trim();
        await FirebaseFirestore.instance
            .collection('transports')
            .doc(user.uid)
            .update(busData);
      } else {
        busData["registration_number"] = _regNumberController.text.trim();
        busData["start_place"] = _startPlaceController.text.trim();

        if (widget.isEdit && widget.busId != null) {
          await FirebaseFirestore.instance
              .collection('transports')
              .doc(user.uid)
              .collection('buses')
              .doc(widget.busId)
              .update(busData);
        } else {
          busData["owner_name"] = ownerName;
          busData["owner_phone"] = ownerPhone;
          busData["created_at"] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('transports')
              .doc(user.uid)
              .collection('buses')
              .add(busData);
        }
      }

      if (mounted) {
        CherryToast.success(
          title: Text(widget.isEdit
              ? 'Bus updated successfully'
              : 'Bus added successfully'),
        ).show(context);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error saving bus'),
          description: Text(e.toString()),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF0C1F41),
            colorScheme: const ColorScheme.light(primary: Color(0xFF0C1F41)),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required IconData icon,
      bool isReadOnly = false,
      TextEditingController? controller,
      VoidCallback? onTap,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            onTap: onTap,
            readOnly: isReadOnly,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bus Type',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedBusType,
            hint: Text('Select bus type',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            icon: const SizedBox.shrink(),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.directions_bus,
                  color: Colors.grey.shade500, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _busTypes.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: _isBusTypeLocked
                ? null
                : (newValue) {
                    setState(() {
                      if (_selectedBusType != newValue) {
                        _selectedBusType = newValue;
                        _selectedServiceType = null;
                      }
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeDropdown() {
    List<String> serviceOptions = [];
    if (_selectedBusType == 'Private Bus') {
      serviceOptions = ['Ordinary', 'Limited Stop'];
    } else if (_selectedBusType == 'KSRTC') {
      serviceOptions = ['Ordinary', 'Fast Passenger', 'Super Fast'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Type',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedServiceType,
            hint: Text('Select service type',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(Icons.settings, color: Colors.grey.shade500, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: serviceOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedServiceType = newValue;
              });
            },
          ),
        ),
      ],
    );
  }
}

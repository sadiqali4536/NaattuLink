import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/controller/bus_dashboard_controller.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/worker_verification_waiting_screen.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_worker_dashboard.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/model/services/app_location_service.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry: choose Bus or Taxi
// ─────────────────────────────────────────────────────────────────────────────
class TransportWorkerRegistrationPage extends StatelessWidget {
  const TransportWorkerRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Transport Registration',
                            style: TextStyle(
                                color: Color(0xFF0A235C),
                                fontWeight: FontWeight.bold,
                                fontSize: 24)),
                      ),
                      const SizedBox(height: 8),
                      Center(
                          child: Text('Select your transport category',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13))),
                      const SizedBox(height: 32),
                      _stepRow(),
                      const SizedBox(height: 36),
                      _card(
                          'Bus',
                          'City bus, school bus, private travels',
                          Icons.directions_bus_rounded,
                          () => Get.to(() => const BusRegistrationPage())),
                      const SizedBox(height: 16),
                      _card(
                          'Taxi',
                          'Auto, Van, Car and shared rides',
                          Icons.local_taxi_rounded,
                          () => Get.to(() => const TaxiRegistrationPage())),
                      const SizedBox(height: 16),
                      _card(
                          'Truck / JCB',
                          'Goods vehicles, earth movers',
                          Icons.local_shipping_rounded,
                          () => Get.to(() => const TruckRegistrationPage())),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 12),
              child: AppBackButton(
                margin: EdgeInsets.zero,
                onPressed: () => Get.back(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF0A235C), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFF0A235C), size: 16),
        ]),
      ),
    );
  }

  Widget _stepRow() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _si(1, 'Category', true),
        _sl(true),
        _si(2, 'Details', true),
        _sl(false),
        _si(3, 'Verify', false),
      ]);

  Widget _si(int n, String l, bool a) => Column(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a ? const Color(0xFF0A235C) : Colors.white,
                border: Border.all(
                    color: a ? const Color(0xFF0A235C) : Colors.grey[300]!,
                    width: 1.5)),
            child: Center(
                child: Text('$n',
                    style: TextStyle(
                        color: a ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 13)))),
        const SizedBox(height: 4),
        Text(l,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: a ? const Color(0xFF0A235C) : Colors.grey[400])),
      ]);

  Widget _sl(bool a) => Container(
      width: 40,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
      color: a ? const Color(0xFF0A235C) : Colors.grey[300]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus Registration
// ─────────────────────────────────────────────────────────────────────────────
class BusRegistrationPage extends StatefulWidget {
  const BusRegistrationPage({super.key});
  @override
  State<BusRegistrationPage> createState() => _BusRegistrationPageState();
}

class _BusRegistrationPageState extends State<BusRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _mainStandCtrl = TextEditingController();
  final _busNameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _firstStopCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  String? _busType;
  String? _serviceType;
  TimeOfDay? _arrivalTime, _departureTime;

  final _busTypes = ['Private Bus', 'KSRTC'];

  String? _selectedDistrict;
  double? _selectedLat;
  double? _selectedLng;

  Future<void> _pickLocationOnMap() async {
    double initialLat = _selectedLat ?? 11.2588;
    double initialLng = _selectedLng ?? 75.7804;
    final result = await Get.to(() =>
        SelectLocationMapPage(initialLat: initialLat, initialLng: initialLng, flow: LocationPickerFlow.registration));
    if (result != null) {
      setState(() {
        _mainStandCtrl.text = result.formattedAddress ?? "";
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
      });
    }
  }

  Widget _buildDistrictDropdown() {
    final List<String> districts = [
      "Kozhikode",
      "Kannur",
      "Malappuram",
      "Wayanad",
      "Palakkad",
      "Thrissur",
      "Ernakulam",
      "Kottayam",
      "Alappuzha",
      "Pathanamthitta",
      "Kollam",
      "Thiruvananthapuram",
      "Idukki",
      "Kasaragod"
    ];

    if (_selectedDistrict != null && !districts.contains(_selectedDistrict)) {
      districts.add(_selectedDistrict!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('District',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A235C))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            value: _selectedDistrict,
            hint: const Text('Select district',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: districts.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedDistrict = newValue;
              });
            },
            validator: (v) => v == null ? 'Please select a district' : null,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _mobileCtrl,
      _emailCtrl,
      _passwordCtrl,
      _roleCtrl,
      _mainStandCtrl,
      _busNameCtrl,
      _regCtrl,
      _firstStopCtrl,
      _destCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $p';
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
      setState(() => isArrival ? _arrivalTime = p : _departureTime = p);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_busType == null) {
      toastError('Please select a bus type');
      return;
    }
    if ((_busType == 'Private Bus' || _busType == 'KSRTC') &&
        _serviceType == null) {
      toastError('Please select a service type');
      return;
    }
    if (_selectedDistrict == null) {
      toastError('Please select a district');
      return;
    }
    if (!_agreeToTerms) {
      toastError('Please agree to Terms & Conditions');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // GPS location fallback if not picked via map
      double? finalLat = _selectedLat;
      double? finalLng = _selectedLng;

      if (finalLat == null || finalLng == null) {
        final locationModel = await AppLocationService().getCurrentLocation();
        if (locationModel != null) {
          finalLat = locationModel.latitude;
          finalLng = locationModel.longitude;
        }
      }

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": "+91${_mobileCtrl.text.trim()}",
        "email": _emailCtrl.text.trim(),
        "role": "worker",
        "category": "Transport (Travels)",
        "transport_category": "Bus",
        "profile_img": "",
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": "active",
        "services": [],
        "ratings": 0,
        "total_reviews": 0,
        "isVerified": 0,
        "password": _passwordCtrl.text.trim(),
        "role_with_vehicle": _roleCtrl.text.trim(),
        "main_stand": _mainStandCtrl.text.trim(),
        "bus_name": _busNameCtrl.text.trim(),
        "reg_number": _regCtrl.text.trim(),
        "bus_type": _busType,
        if (_serviceType != null) "service_type": _serviceType,
        "first_stop": _firstStopCtrl.text.trim(),
        "destination": _destCtrl.text.trim(),
        "arrival_time": _fmt(_arrivalTime),
        "departure_time": _fmt(_departureTime),
        "district": _selectedDistrict,
        "lat": finalLat,
        "lng": finalLng,
      });

      toastSuccess('Bus registration successful.');
      if (Get.isRegistered<BusDashboardController>()) {
        Get.delete<BusDashboardController>(force: true);
      }
      Get.offAll(() => const BusWorkerDashboard());
    } on FirebaseAuthException catch (e) {
      toastError(FirebaseErrorHandler.getReadableErrorMessage(e));
    } catch (e) {
      toastError("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Bus Registration',
      isLoading: _isLoading,
      formKey: _formKey,
      onRegister: _register,
      agreeToTerms: _agreeToTerms,
      onTermsChanged: (v) => setState(() => _agreeToTerms = v ?? false),
      children: [
        _F('Full Name', 'Enter your full name', Icons.person_outline, _nameCtrl,
            isRequired: true),
        _F('Mobile Number', '00000 00000', Icons.phone_outlined, _mobileCtrl,
            isRequired: true,
            type: TextInputType.phone,
            prefixText: '+91 ',
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
            return 'Invalid 10-digit Indian mobile number';
          }
          return null;
        }),
        _F('Email Address', 'Enter email', Icons.email_outlined, _emailCtrl,
            isRequired: true,
            type: TextInputType.emailAddress,
            suffixIcon: IconButton(
              icon: Image.asset('assets/icons/google_logo.png',
                  width: 24, height: 24),
              onPressed: () async {
                try {
                  final googleSignIn = GoogleSignIn();
                  try {
                    await googleSignIn.disconnect();
                  } catch (_) {}
                  final googleUser = await googleSignIn.signIn();
                  if (googleUser != null) {
                    setState(() {
                      _emailCtrl.text = googleUser.email;
                    });
                  }
                } catch (e) {
                  debugPrint("Google Sign In Error: $e");
                }
              },
            )),
        _F('Password', 'Enter password', Icons.lock_outline, _passwordCtrl,
            isRequired: true, isPassword: true),
        _F('Role with the vehicle', 'Enter your role with the vehicle',
            Icons.location_on_outlined, _roleCtrl,
            isRequired: false),
        _readonlyDropdown('Profession', 'Bus', Icons.sync_alt_outlined),
        _secHeader('VEHICLE DETAILS'),
        _buildDistrictDropdown(),
        const SizedBox(height: 14),
        _F('Main Stand', 'e.g. City Bus Terminal', Icons.map_outlined,
            _mainStandCtrl,
            textCapitalization: TextCapitalization.characters,
            suffixIcon: IconButton(
              icon: const Icon(Icons.location_on, color: Colors.red),
              onPressed: _pickLocationOnMap,
            )),
        Row(children: [
          Expanded(
              child: _F('Bus Name', 'e.g. Star Travels',
                  Icons.directions_bus_outlined, _busNameCtrl,
                  textCapitalization: TextCapitalization.characters)),
          const SizedBox(width: 10),
          Expanded(
              child: _F(
                  'Reg. Number', 'KL-XX-0000', Icons.numbers_outlined, _regCtrl,
                  textCapitalization: TextCapitalization.characters)),
        ]),
        _DD('Bus Type', 'Select Bus Type', Icons.category_outlined, _busType,
            _busTypes,
            onChanged: (v) => setState(() {
                  _busType = v;
                  _serviceType = null;
                })),
        if (_busType == 'Private Bus' || _busType == 'KSRTC') ...[
          const SizedBox(height: 14),
          _DD(
            'Service Type',
            'Select Service Type',
            Icons.miscellaneous_services_outlined,
            _serviceType,
            _busType == 'Private Bus'
                ? ['Ordinary', 'Limited Stop']
                : ['Ordinary', 'Fast Passenger', 'Super Fast'],
            onChanged: (v) => setState(() => _serviceType = v),
          ),
        ],
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: _F(
                  'First Stop', 'Origin', Icons.trip_origin, _firstStopCtrl,
                  textCapitalization: TextCapitalization.characters)),
          const SizedBox(width: 10),
          Expanded(
              child: _F('Destination', 'End Point', Icons.location_on_outlined,
                  _destCtrl,
                  textCapitalization: TextCapitalization.characters)),
        ]),
        Row(children: [
          Expanded(
              child: _TT('Arrival Time', _arrivalTime, () => _pickTime(true))),
          const SizedBox(width: 10),
          Expanded(
              child: _TT(
                  'Departure Time', _departureTime, () => _pickTime(false))),
        ]),
      ],
    );
  }

  Widget _readonlyDropdown(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF0A235C), size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text('Profession',
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ])),
        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A235C)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Taxi Registration
// ─────────────────────────────────────────────────────────────────────────────
class TaxiRegistrationPage extends StatefulWidget {
  const TaxiRegistrationPage({super.key});
  @override
  State<TaxiRegistrationPage> createState() => _TaxiRegistrationPageState();
}

class _TaxiRegistrationPageState extends State<TaxiRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _airConditioning = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _seatingCtrl = TextEditingController();
  final _minChargeCtrl = TextEditingController();
  final _luggageCtrl = TextEditingController();
  final _mainStandCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();

  String _vehicleCategory = 'Auto'; // Auto | Car | Van

  double? _selectedLat;
  double? _selectedLng;

  Future<void> _pickLocationOnMap() async {
    double initialLat = _selectedLat ?? 11.2588;
    double initialLng = _selectedLng ?? 75.7804;
    final result = await Get.to(() =>
        SelectLocationMapPage(initialLat: initialLat, initialLng: initialLng, flow: LocationPickerFlow.registration));
    if (result != null) {
      setState(() {
        _mainStandCtrl.text = result.formattedAddress ?? "";
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _mobileCtrl,
      _emailCtrl,
      _passwordCtrl,
      _roleCtrl,
      _seatingCtrl,
      _minChargeCtrl,
      _luggageCtrl,
      _mainStandCtrl,
      _vehicleModelCtrl,
      _regCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      toastError('Please agree to Terms & Conditions');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // GPS location fallback if not picked via map
      double? finalLat = _selectedLat;
      double? finalLng = _selectedLng;

      if (finalLat == null || finalLng == null) {
        final locationModel = await AppLocationService().getCurrentLocation();
        if (locationModel != null) {
          finalLat = locationModel.latitude;
          finalLng = locationModel.longitude;
        }
      }

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": "+91${_mobileCtrl.text.trim()}",
        "email": _emailCtrl.text.trim(),
        "role": "worker",
        "category": "Transport (Travels)",
        "transport_category": "Taxi",
        "profile_img": "",
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": "pending",
        "services": [],
        "ratings": 0,
        "total_reviews": 0,
        "isVerified": 0,
        "password": _passwordCtrl.text.trim(),
        "role_with_vehicle": _roleCtrl.text.trim(),
        "vehicle_category": _vehicleCategory,
        "seating_capacity": _seatingCtrl.text.trim(),
        "min_charge": _minChargeCtrl.text.trim(),
        "luggage_capacity": _luggageCtrl.text.trim(),
        "air_conditioning": _airConditioning,
        "main_stand": _mainStandCtrl.text.trim(),
        "vehicle_model": _vehicleModelCtrl.text.trim(),
        "reg_number": _regCtrl.text.trim(),
        "lat": finalLat,
        "lng": finalLng,
      });

      toastSuccess('Taxi registration successful. Awaiting admin approval.');
      Get.back();
    } on FirebaseAuthException catch (e) {
      toastError(FirebaseErrorHandler.getReadableErrorMessage(e));
    } catch (e) {
      toastError("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: 'Create Account',
      isLoading: _isLoading,
      formKey: _formKey,
      onRegister: _register,
      agreeToTerms: _agreeToTerms,
      onTermsChanged: (v) => setState(() => _agreeToTerms = v ?? false),
      children: [
        _F('Full Name', 'Enter your full name', Icons.person_outline, _nameCtrl,
            isRequired: true),
        _F('Mobile Number', '00000 00000', Icons.phone_outlined, _mobileCtrl,
            isRequired: true,
            type: TextInputType.phone,
            prefixText: '+91 ',
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
            return 'Invalid 10-digit Indian mobile number';
          }
          return null;
        }),
        _F('Email Address', 'Enter email', Icons.email_outlined, _emailCtrl,
            isRequired: true,
            type: TextInputType.emailAddress,
            suffixIcon: IconButton(
              icon: Image.asset('assets/icons/google_logo.png',
                  width: 24, height: 24),
              onPressed: () async {
                try {
                  final googleSignIn = GoogleSignIn();
                  try {
                    await googleSignIn.disconnect();
                  } catch (_) {}
                  final googleUser = await googleSignIn.signIn();
                  if (googleUser != null) {
                    setState(() {
                      _emailCtrl.text = googleUser.email;
                    });
                  }
                } catch (e) {
                  debugPrint("Google Sign In Error: $e");
                }
              },
            )),
        _F('Password', 'Enter password', Icons.lock_outline, _passwordCtrl,
            isRequired: true, isPassword: true),
        _F('Role with the vehicle', 'Enter your role with the vehicle',
            Icons.location_on_outlined, _roleCtrl,
            isRequired: false),
        _readonlyDropdown('Profession', 'Taxi', Icons.sync_alt_outlined),
        _secHeader('VEHICLE DETAILS'),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Vehicle Category',
              style: TextStyle(
                  color: Color(0xFF0A235C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
        Row(
            children: ['Auto', 'Car', 'Van'].map((type) {
          final sel = _vehicleCategory == type;
          return Expanded(
              child: GestureDetector(
            onTap: () => setState(() => _vehicleCategory = type),
            child: Container(
              margin: EdgeInsets.only(right: type != 'Van' ? 8 : 0, bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF0A235C) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? const Color(0xFF0A235C) : Colors.transparent,
                    width: 1.5),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    type == 'Auto'
                        ? Icons.directions_railway_filled_outlined
                        : type == 'Car'
                            ? Icons.directions_car_outlined
                            : Icons.airport_shuttle_outlined,
                    color: sel ? Colors.white : const Color(0xFF0A235C),
                    size: 16),
                const SizedBox(width: 4),
                Text(type,
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF0A235C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
          ));
        }).toList()),
        Row(children: [
          Expanded(
              child: _F(
                  'Seating', 'e.g. 40', Icons.event_seat_outlined, _seatingCtrl,
                  type: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
              child: _F('Min Charge', 'e.g. 500', Icons.currency_rupee_outlined,
                  _minChargeCtrl,
                  type: TextInputType.number)),
        ]),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            const Icon(Icons.wb_sunny_outlined,
                color: Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Air Conditioning',
                    style: TextStyle(
                        color: Color(0xFF0A235C),
                        fontSize: 13,
                        fontWeight: FontWeight.bold))),
            Switch(
              value: _airConditioning,
              onChanged: (v) => setState(() => _airConditioning = v),
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF0A235C),
            ),
          ]),
        ),
        _F('Luggage Capacity', 'e.g. 10 Large Bags', Icons.luggage_outlined,
            _luggageCtrl),
        _F('Main Stand', 'e.g. City Bus Terminal', Icons.map_outlined,
            _mainStandCtrl,
            textCapitalization: TextCapitalization.characters,
            suffixIcon: IconButton(
              icon: const Icon(Icons.location_on, color: Colors.red),
              onPressed: _pickLocationOnMap,
            )),
        Row(children: [
          Expanded(
              child: _F('Vehicle Model', 'e.g. Maruti Dzire', null,
                  _vehicleModelCtrl)),
          const SizedBox(width: 10),
          Expanded(
              child: _F('Reg. Number', 'KL-XX-0000', null, _regCtrl,
                  textCapitalization: TextCapitalization.characters)),
        ]),
      ],
    );
  }

  Widget _readonlyDropdown(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF0A235C), size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text('Profession',
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ])),
        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A235C)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared scaffold shell
// ─────────────────────────────────────────────────────────────────────────────
class _Shell extends StatelessWidget {
  final String title;
  final bool isLoading, agreeToTerms;
  final GlobalKey<FormState> formKey;
  final VoidCallback onRegister;
  final ValueChanged<bool?> onTermsChanged;
  final List<Widget> children;

  const _Shell(
      {required this.title,
      required this.isLoading,
      required this.formKey,
      required this.onRegister,
      required this.agreeToTerms,
      required this.onTermsChanged,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF0A235C),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _stepRow(),
              const SizedBox(height: 32),
              ...children,
              const SizedBox(height: 18),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                      value: agreeToTerms,
                      activeColor: const Color(0xFF0A235C),
                      onChanged: onTermsChanged,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: RichText(
                        text: TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  children: const [
                    TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                            color: Color(0xFF0A235C),
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                            color: Color(0xFF0A235C),
                            fontWeight: FontWeight.bold)),
                    TextSpan(text: ' regarding worker conduct.'),
                  ],
                ))),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onRegister,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A235C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Worker Account',
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
                            fontWeight: FontWeight.bold))
                  ],
                )),
              )),
              const SizedBox(height: 16),
              Center(
                  child: Text('Powered by NaattuLink Connectivity',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10))),
              const SizedBox(height: 30),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _stepRow() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _si(1, 'Category', true),
        _sl(true),
        _si(2, 'Details', true),
        _sl(false),
        _si(3, 'Verify', false),
      ]);

  Widget _si(int n, String l, bool a) => Column(children: [
        Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a ? const Color(0xFF0A235C) : const Color(0xFFF1F5F9),
                border: Border.all(color: Colors.transparent, width: 0)),
            child: Center(
                child: Text('$n',
                    style: TextStyle(
                        color: a ? Colors.white : const Color(0xFF0A235C),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)))),
        const SizedBox(height: 8),
        Text(l,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0A235C))),
      ]);

  Widget _sl(bool a) => Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: const Color(0xFFE2E8F0));
}

Widget _secHeader(String t) => Center(
    child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(t,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5))));

// ─────────────────────────────────────────────────────────────────────────────
// Reusable input field
// ─────────────────────────────────────────────────────────────────────────────
class _F extends StatefulWidget {
  final String label, hint;
  final IconData? icon;
  final TextEditingController controller;
  final bool isRequired, isPassword;
  final TextInputType? type;
  final FormFieldValidator<String>? validator;

  const _F(this.label, this.hint, this.icon, this.controller,
      {this.isRequired = false,
      this.isPassword = false,
      this.type,
      this.validator,
      this.prefixText,
      this.maxLength,
      this.inputFormatters,
      this.suffixIcon,
      this.readOnly = false,
      this.onTap,
      this.textCapitalization = TextCapitalization.none});

  final Widget? suffixIcon;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<_F> createState() => _FState();
}

class _FState extends State<_F> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent)),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: const Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 12),
        ],
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    text: widget.label,
                    style: const TextStyle(
                        color: Color(0xFF0A235C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
                if (widget.isRequired)
                  const TextSpan(
                      text: ' *',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
              ])),
              TextFormField(
                controller: widget.controller,
                obscureText: widget.isPassword ? _obscure : false,
                keyboardType: widget.type,
                validator: widget.validator,
                maxLength: widget.maxLength,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                inputFormatters: widget.inputFormatters,
                textCapitalization: widget.textCapitalization,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: "",
                  prefixText: widget.prefixText,
                  contentPadding: const EdgeInsets.only(top: 4, bottom: 4),
                  hintText: widget.hint,
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
              ),
            ])),
        if (widget.isPassword)
          GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 18))
        else if (widget.suffixIcon != null)
          widget.onTap != null
              ? GestureDetector(
                  onTap: widget.onTap,
                  child: widget.suffixIcon!,
                )
              : widget.suffixIcon!,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown tile
// ─────────────────────────────────────────────────────────────────────────────
class _DD extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DD(this.label, this.hint, this.icon, this.value, this.items,
      {required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.transparent)),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3)),
              DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                hint: Text(hint,
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 13)),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF0A235C)),
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              )),
            ])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time tile
// ─────────────────────────────────────────────────────────────────────────────
class _TT extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  const _TT(this.label, this.time, this.onTap);
  String get _d {
    if (time == null) return '--:--';
    final h =
        time!.hour == 0 ? 12 : (time!.hour > 12 ? time!.hour - 12 : time!.hour);
    final m = time!.minute.toString().padLeft(2, '0');
    final p = time!.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent)),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          const Icon(Icons.access_time_outlined,
              color: Color(0xFF94A3B8), size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF0A235C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(_d,
                    style: TextStyle(
                        color: time == null
                            ? const Color(0xFF94A3B8)
                            : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ])),
        ]),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Truck / JCB Registration
// -----------------------------------------------------------------------------
class TruckRegistrationPage extends StatefulWidget {
  const TruckRegistrationPage({super.key});
  @override
  State<TruckRegistrationPage> createState() => _TruckRegistrationPageState();
}

class _TruckRegistrationPageState extends State<TruckRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _minChargeCtrl = TextEditingController();
  final _loadCapacityCtrl = TextEditingController();
  final _mainStandCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();

  String _vehicleType = "Truck"; // Truck | JCB

  double? _selectedLat;
  double? _selectedLng;

  Future<void> _pickLocationOnMap() async {
    double initialLat = _selectedLat ?? 11.2588;
    double initialLng = _selectedLng ?? 75.7804;
    final result = await Get.to(() =>
        SelectLocationMapPage(initialLat: initialLat, initialLng: initialLng, flow: LocationPickerFlow.registration));
    if (result != null) {
      setState(() {
        _mainStandCtrl.text = result.formattedAddress ?? "";
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _mobileCtrl,
      _emailCtrl,
      _passwordCtrl,
      _roleCtrl,
      _minChargeCtrl,
      _loadCapacityCtrl,
      _mainStandCtrl,
      _vehicleModelCtrl,
      _regCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      toastError("Please agree to Terms & Conditions");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final uid = userCredential.user!.uid;

      // GPS location fallback if not picked via map
      double? finalLat = _selectedLat;
      double? finalLng = _selectedLng;

      if (finalLat == null || finalLng == null) {
        final locationModel = await AppLocationService().getCurrentLocation();
        if (locationModel != null) {
          finalLat = locationModel.latitude;
          finalLng = locationModel.longitude;
        }
      }

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": "+91${_mobileCtrl.text.trim()}",
        "email": _emailCtrl.text.trim(),
        "role": "worker",
        "category": "Transport (Travels)",
        "transport_category": "Truck / JCB",
        "profile_img": "",
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
        "status": "pending",
        "services": [],
        "ratings": 0,
        "total_reviews": 0,
        "isVerified": 0,
        "password": _passwordCtrl.text.trim(),
        "role_with_vehicle": _roleCtrl.text.trim(),
        "vehicle_type": _vehicleType,
        "min_charge": _minChargeCtrl.text.trim(),
        "load_capacity": _loadCapacityCtrl.text.trim(),
        "main_stand": _mainStandCtrl.text.trim(),
        "vehicle_model": _vehicleModelCtrl.text.trim(),
        "reg_number": _regCtrl.text.trim(),
        "lat": finalLat,
        "lng": finalLng,
      });

      toastSuccess(
          "Truck / JCB registration successful. Awaiting admin approval.");
      Get.back();
    } on FirebaseAuthException catch (e) {
      toastError(FirebaseErrorHandler.getReadableErrorMessage(e));
    } catch (e) {
      toastError("Something went wrong. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      title: "Create Account",
      isLoading: _isLoading,
      formKey: _formKey,
      onRegister: _register,
      agreeToTerms: _agreeToTerms,
      onTermsChanged: (v) => setState(() => _agreeToTerms = v ?? false),
      children: [
        _F("Full Name", "Enter your full name", Icons.person_outline, _nameCtrl,
            isRequired: true),
        _F("Mobile Number", "00000 00000", Icons.phone_outlined, _mobileCtrl,
            isRequired: true,
            type: TextInputType.phone,
            prefixText: '+91 ',
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
            return 'Invalid 10-digit Indian mobile number';
          }
          return null;
        }),
        _F("Email Address", "Enter email", Icons.email_outlined, _emailCtrl,
            isRequired: true,
            type: TextInputType.emailAddress,
            suffixIcon: IconButton(
              icon: Image.asset('assets/icons/google_logo.png',
                  width: 24, height: 24),
              onPressed: () async {
                try {
                  final googleSignIn = GoogleSignIn();
                  try {
                    await googleSignIn.disconnect();
                  } catch (_) {}
                  final googleUser = await googleSignIn.signIn();
                  if (googleUser != null) {
                    setState(() {
                      _emailCtrl.text = googleUser.email;
                    });
                  }
                } catch (e) {
                  debugPrint("Google Sign In Error: $e");
                }
              },
            )),
        _F("Password", "Enter password", Icons.lock_outline, _passwordCtrl,
            isRequired: true, isPassword: true),
        _F("Role with the vehicle", "Enter your role with the vehicle",
            Icons.location_on_outlined, _roleCtrl,
            isRequired: false),
        _readonlyDropdown("Profession", "Truck / JCB", Icons.sync_alt_outlined),
        _secHeader("VEHICLE DETAILS"),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text("Vehicle Type",
              style: TextStyle(
                  color: Color(0xFF0A235C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
        Row(
            children: ["Truck", "JCB"].map((type) {
          final sel = _vehicleType == type;
          return Expanded(
              child: GestureDetector(
            onTap: () => setState(() => _vehicleType = type),
            child: Container(
              margin:
                  EdgeInsets.only(right: type == "Truck" ? 8 : 0, bottom: 14),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF0A235C) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? const Color(0xFF0A235C) : Colors.transparent,
                    width: 1.5),
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    type == "Truck"
                        ? Icons.local_shipping_outlined
                        : Icons.construction_outlined,
                    color: sel ? Colors.white : const Color(0xFF0A235C),
                    size: 16),
                const SizedBox(width: 6),
                Text(type,
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF0A235C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
          ));
        }).toList()),
        _F("Min Charge", "e.g. 500", Icons.currency_rupee_outlined,
            _minChargeCtrl,
            type: TextInputType.number),
        if (_vehicleType == "Truck")
          _F("Load Capacity", "e.g. 10 Tons", Icons.work_outline,
              _loadCapacityCtrl),
        _F("Main Stand", "e.g. City Bus Terminal", Icons.map_outlined,
            _mainStandCtrl,
            textCapitalization: TextCapitalization.characters,
            suffixIcon: IconButton(
              icon: const Icon(Icons.location_on, color: Colors.red),
              onPressed: _pickLocationOnMap,
            )),
        Row(children: [
          Expanded(
              child: _F(
                  _vehicleType == "Truck" ? "Vehicle Model" : "JCB Type",
                  _vehicleType == "Truck" ? "e.g. Tata Prima" : "e.g. 3DX",
                  null,
                  _vehicleModelCtrl)),
          const SizedBox(width: 10),
          Expanded(
              child: _F("Reg. Number", "KL-XX-0000", null, _regCtrl,
                  textCapitalization: TextCapitalization.characters)),
        ]),
      ],
    );
  }

  Widget _readonlyDropdown(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF0A235C), size: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text("Profession",
                  style: TextStyle(
                      color: Color(0xFF0A235C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ])),
        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0A235C)),
      ]),
    );
  }
}

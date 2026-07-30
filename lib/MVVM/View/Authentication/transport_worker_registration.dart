import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Authentication/worker_verification_waiting_screen.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/utils/Founctions/firebase_error_handler.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';

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
  TimeOfDay? _arrivalTime, _departureTime;

  final _busTypes = [
    'AC Sleeper',
    'Non-AC Sleeper',
    'AC Seater',
    'Non-AC Seater',
    'Mini Bus',
    'School Bus',
    'Private Bus'
  ];

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

  String _fmt(TimeOfDay? t) => t == null
      ? '--:--'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isArrival) async {
    final p = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Color(0xFF0A235C), onSurface: Color(0xFF0A235C))),
            child: child!));
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

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": _mobileCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "role": "worker",
        "category": "Transport (Travels)",
        "transport_category": "Bus",
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
        "main_stand": _mainStandCtrl.text.trim(),
        "bus_name": _busNameCtrl.text.trim(),
        "reg_number": _regCtrl.text.trim(),
        "bus_type": _busType,
        "first_stop": _firstStopCtrl.text.trim(),
        "destination": _destCtrl.text.trim(),
        "arrival_time": _fmt(_arrivalTime),
        "departure_time": _fmt(_departureTime),
      });

      toastSuccess('Bus registration successful. Awaiting admin approval.');
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
      title: 'Bus Registration',
      isLoading: _isLoading,
      formKey: _formKey,
      onRegister: _register,
      agreeToTerms: _agreeToTerms,
      onTermsChanged: (v) => setState(() => _agreeToTerms = v ?? false),
      children: [
        _F('Full Name', 'Enter your full name', Icons.person_outline, _nameCtrl,
            isRequired: true),
        _F('Mobile Number', 'Enter mobile number', Icons.phone_outlined,
            _mobileCtrl,
            isRequired: true, type: TextInputType.phone),
        _F('Email Address', 'Enter email', Icons.email_outlined, _emailCtrl,
            isRequired: true, type: TextInputType.emailAddress),
        _F('Password', 'Enter password', Icons.lock_outline, _passwordCtrl,
            isRequired: true, isPassword: true),
        _F('Role with the vehicle', 'Enter your role with the vehicle',
            Icons.location_on_outlined, _roleCtrl,
            isRequired: false),
        _readonlyDropdown('Profession', 'Bus', Icons.sync_alt_outlined),
        _secHeader('VEHICLE DETAILS'),
        _F('Main Stand', 'e.g. City Bus Terminal', Icons.location_city_outlined,
            _mainStandCtrl),
        Row(children: [
          Expanded(
              child: _F('Bus Name', 'e.g. Star Travels',
                  Icons.directions_bus_outlined, _busNameCtrl)),
          const SizedBox(width: 10),
          Expanded(
              child: _F('Reg. Number', 'KL-XX-0000', Icons.numbers_outlined,
                  _regCtrl)),
        ]),
        _DD('Bus Type', 'Select Bus Type', Icons.category_outlined, _busType,
            _busTypes,
            onChanged: (v) => setState(() => _busType = v)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
              child: _F(
                  'First Stop', 'Origin', Icons.trip_origin, _firstStopCtrl)),
          const SizedBox(width: 10),
          Expanded(
              child: _F('Destination', 'End Point', Icons.location_on_outlined,
                  _destCtrl)),
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

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": _mobileCtrl.text.trim(),
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
        _F('Mobile Number', 'Enter mobile number', Icons.phone_outlined,
            _mobileCtrl,
            isRequired: true, type: TextInputType.phone),
        _F('Email Address', 'Enter email', Icons.email_outlined, _emailCtrl,
            isRequired: true, type: TextInputType.emailAddress),
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
        _F('Main Stand', 'e.g. City Bus Terminal', Icons.business_outlined,
            _mainStandCtrl),
        Row(children: [
          Expanded(
              child: _F('Vehicle Model', 'e.g. Maruti Dzire', null,
                  _vehicleModelCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _F('Reg. Number', 'KL-XX-0000', null, _regCtrl)),
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
      this.validator});

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
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
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
                  size: 18)),
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
  String get _d => time == null
      ? '--:--'
      : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
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

      await FirebaseFirestore.instance.collection("transports").doc(uid).set({
        "username": _nameCtrl.text.trim(),
        "phone": _mobileCtrl.text.trim(),
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
        _F("Mobile Number", "Enter mobile number", Icons.phone_outlined,
            _mobileCtrl,
            isRequired: true, type: TextInputType.phone),
        _F("Email Address", "Enter email", Icons.email_outlined, _emailCtrl,
            isRequired: true, type: TextInputType.emailAddress),
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
        _F("Main Stand", "e.g. City Bus Terminal", Icons.business_outlined,
            _mainStandCtrl),
        Row(children: [
          Expanded(
              child: _F(
                  _vehicleType == "Truck" ? "Vehicle Model" : "JCB Type",
                  _vehicleType == "Truck" ? "e.g. Tata Prima" : "e.g. 3DX",
                  null,
                  _vehicleModelCtrl)),
          const SizedBox(width: 10),
          Expanded(child: _F("Reg. Number", "KL-XX-0000", null, _regCtrl)),
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

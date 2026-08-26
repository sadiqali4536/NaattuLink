import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:naattulink/MVVM/View/Authentication/controller/location_controller.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:naattulink/MVVM/model/services/app_location_service.dart';
import 'package:naattulink/MVVM/utils/zone_detector.dart';
import 'package:naattulink/MVVM/utils/add_sample_zone.dart';

/// Modal bottom sheet content for editing a delivery address.
///
/// IMPORTANT: Always open with [showModalBottomSheet], never with
/// [Navigator.push] or [Get.to].
///
/// ```dart
/// final result = await showModalBottomSheet<AppLocationModel>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   useSafeArea: true,
///   builder: (_) => const AddressFormBottomSheet(),
/// );
/// if (result != null) { /* refresh UI */ }
/// ```
class AddressFormBottomSheet extends StatefulWidget {
  /// Optional pre-existing address to edit. When null the form is prefilled
  /// from [LocationController.to.currentLocationModel].
  final AppLocationModel? initialAddress;

  /// Optional callback invoked with the saved [AppLocationModel] just before
  /// the sheet closes. Use this when the caller needs to persist the address
  /// to local storage / refresh its own list (e.g. [LocationSelectionPage]).
  final void Function(AppLocationModel saved)? onAddressSaved;

  /// Whether this form is editing an existing saved address
  final bool isEdit;

  const AddressFormBottomSheet({
    super.key,
    this.initialAddress,
    this.onAddressSaved,
    this.isEdit = false,
  });

  @override
  State<AddressFormBottomSheet> createState() => _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<AddressFormBottomSheet> {
  // ── brand colours ──────────────────────────────────────────────────────────
  static const Color _primaryBlue = Color(0xFF0F2E5A);
  static const Color _darkText = Color(0xFF171717);
  static const Color _secondaryGray = Color(0xFF777777);
  static const Color _borderGray = Color(0xFFD9D9D9);
  static const Color _locationBg = Color(0xFFF5F5F5);
  static const Color _infoBg = Color(0xFFFFF7E8);
  static const Color _infoText = Color(0xFF8B6914);

  // ── form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _houseCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();

  AppLocationModel? _selectedLocation;
  String _addressType = 'Home';
  bool _isDefaultAddress = false;
  bool _isSaving = false;

  int _zoneDetectionRequestId = 0;
  bool _isDetectingZone = false;
  String? _detectedZoneId;
  String? _detectedZoneName;
  String? _detectedDistrict;

  // ── controllers ──────────────────────────────────────────────────────────────

  @override
  void _prefill() {
    final src = widget.initialAddress ??
        LocationController.to.currentLocationModel.value;
    if (src == null) return;
    _selectedLocation = src;
    _houseCtrl.text = src.landmark ?? '';
    _nameCtrl.text = src.receiverName ?? '';
    _mobileCtrl.text = src.receiverPhone ?? '';
    _altPhoneCtrl.text = src.alternatePhone ?? '';
    _addressType = src.addressType ?? 'Home';
    _isDefaultAddress = src.isPrimary == true;
    _detectedZoneId = src.zoneId;
    _detectedZoneName = src.zoneName;
    _detectedDistrict = src.district.isNotEmpty ? src.district : null;
  }

  @override
  void initState() {
    super.initState();
    _prefill();
    if (_selectedLocation != null) {
      _processSelectedLocation(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
    }
  }

  Future<void> _processSelectedLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) return;

    final requestId = ++_zoneDetectionRequestId;

    setState(() {
      _detectedDistrict = null;
      _detectedZoneId = null;
      _detectedZoneName = null;
      _isDetectingZone = true;
    });

    try {
      // ============================================================
      // STEP 1: REVERSE GEOCODE NEW LOCATION
      // ============================================================

      final reverseLoc = await AppLocationService()
          .getLocationDetailsFromCoordinates(latitude, longitude);

      String? detectedDistrict = _cleanValue(reverseLoc.district);
      if (detectedDistrict?.toLowerCase() == 'unknown') {
        detectedDistrict = null;
      }

      debugPrint('========== LOCATION PROCESSING ==========');
      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');
      debugPrint('Initial Reverse Geocoded District: $detectedDistrict');
      debugPrint('=========================================');

      // ============================================================
      // STEP 2: UPDATE ADDRESS INFORMATION
      // ============================================================

      if (mounted) {
        setState(() {
          _detectedDistrict = detectedDistrict;
        });
      }

      // ============================================================
      // STEP 3: RUN ZONE DETECTION USING NEW COORDINATES
      // ============================================================

      // Pass the detected district (or empty string) to help fetch zones if needed
      final zones = await ZoneDetector.getActiveZonesForDistrict(detectedDistrict ?? '');

      if (!mounted || requestId != _zoneDetectionRequestId) return;

      final match = ZoneDetector.findMatchingZone(latitude, longitude, zones);

      // ============================================================
      // STEP 4: APPLY ZONE RESULT
      // ============================================================

      setState(() {
        _isDetectingZone = false;

        if (match != null) {
          _detectedZoneId = match.id;
          _detectedZoneName = match.name;

          // Zone is the authoritative district when matched.
          final zoneDistrict = _cleanValue(match.districtId);

          if (zoneDistrict != null) {
            _detectedDistrict = zoneDistrict[0].toUpperCase() + 
                                zoneDistrict.substring(1).toLowerCase();
          }

          debugPrint('========== ZONE MATCHED ==========');
          debugPrint('Zone ID: $_detectedZoneId');
          debugPrint('Zone Name: $_detectedZoneName');
          debugPrint('District: $_detectedDistrict');
          debugPrint('==================================');
        } else {
          // ==========================================================
          // NO ZONE
          //
          // IMPORTANT:
          // Do NOT set district to Unknown here.
          // Keep the district from reverse geocoding.
          // ==========================================================

          _detectedZoneId = null;
          _detectedZoneName = null;

          debugPrint('========== NO ZONE MATCH ==========');
          debugPrint(
            'Keeping reverse-geocoded district: $_detectedDistrict',
          );
          debugPrint('===================================');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Location processing error: $e');
      debugPrint('$stackTrace');

      if (!mounted || requestId != _zoneDetectionRequestId) return;

      setState(() {
        _detectedZoneName = null;
        _detectedZoneId = null;
        _isDetectingZone = false;
      });
    }
  }

  String? _cleanValue(String? value) {
    if (value == null) return null;
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  @override
  void dispose() {
    _houseCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _altPhoneCtrl.dispose();
    super.dispose();
  }

  // ── derived strings ────────────────────────────────────────────────────────

  String get _line1 {
    if (_selectedLocation == null) return 'No location selected — tap Change';
    // Return the complete formatted address so the user can see exactly
    // what was selected on the map.
    return _selectedLocation!.formattedAddress;
  }

  String get _line2 {
    if (_selectedLocation == null) return '';
    final parts = <String>[
      if (_selectedLocation!.district.isNotEmpty) _selectedLocation!.district,
      if ((_selectedLocation!.state ?? '').isNotEmpty)
        _selectedLocation!.state!,
      if ((_selectedLocation!.pincode ?? '').isNotEmpty)
        _selectedLocation!.pincode!,
    ];
    return parts.join(', ');
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final lat = _selectedLocation?.latitude ??
        LocationController.to.latitude.value ??
        11.2588;
    final lng = _selectedLocation?.longitude ??
        LocationController.to.longitude.value ??
        75.7804;

    final result = await Navigator.push<AppLocationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectLocationMapPage(
          initialLat: lat,
          initialLng: lng,
          // Don't show the address form again inside the map page —
          // we are already inside AddressFormBottomSheet.
          flow: LocationPickerFlow.registration,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        // Merge: keep user-typed fields, update location metadata.
        _selectedLocation = result.copyWith(
          landmark: _houseCtrl.text.trim().isNotEmpty
              ? _houseCtrl.text.trim()
              : result.landmark,
          receiverName: _nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : result.receiverName,
          receiverPhone: _mobileCtrl.text.trim().isNotEmpty
              ? _mobileCtrl.text.trim()
              : result.receiverPhone,
          alternatePhone: _altPhoneCtrl.text.trim().isNotEmpty
              ? _altPhoneCtrl.text.trim()
              : result.alternatePhone,
          addressType: _addressType,
        );
        _detectedZoneId = null;
        _detectedZoneName = null;
        _isDetectingZone = true;
      });
      await _processSelectedLocation(
        latitude: result.latitude,
        longitude: result.longitude,
      );
    }
  }

  Future<void> _onUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      _showError('Please select a location first.');
      return;
    }
    if (_detectedZoneId == null) {
      _showError(
          'We couldn\'t find a service zone for this location. Please choose another location.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = _selectedLocation!.copyWith(
        landmark: _houseCtrl.text.trim(),
        receiverName: _nameCtrl.text.trim(),
        receiverPhone: _mobileCtrl.text.trim(),
        alternatePhone: _altPhoneCtrl.text.trim().isNotEmpty
            ? _altPhoneCtrl.text.trim()
            : null,
        addressType: _addressType,
        isPrimary: _isDefaultAddress,
        zoneId: _detectedZoneId,
        zoneName: _detectedZoneName,
      );

      // Use the existing controller — pass saveToFirebase: true to save to backend
      await LocationController.to
          .updateLocationManually(updated, saveToFirebase: true);

      // Notify the caller so it can save to local storage / refresh its list.
      widget.onAddressSaved?.call(updated);

      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      debugPrint('AddressFormBottomSheet save error: $e');
      if (mounted) _showError('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    CherryToast.error(
      title: const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
      description: Text(msg),
      animationType: AnimationType.fromTop,
      toastPosition: Position.top,
      displayCloseButton: false,
    ).show(context);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Removed custom drag handle in favor of Flutter's native showDragHandle

            // Scrollable form
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildInfoBanner(),
                      const SizedBox(height: 20),
                      _buildHouseField(),
                      const SizedBox(height: 14),
                      _buildLocationTile(),
                      if (_selectedLocation != null) ...[
                        const SizedBox(height: 14),
                        _buildZoneClassification(),
                      ],
                      const SizedBox(height: 14),
                      _buildDefaultAddressToggle(),
                      const SizedBox(height: 14),
                      _buildNameField(),
                      const SizedBox(height: 14),
                      _buildMobileField(),
                      const SizedBox(height: 20),
                      _buildAltPhoneField(),
                      const SizedBox(height: 20),
                      _buildAddressTypeSection(),
                      const SizedBox(height: 16),
                      _buildUpdateButton(),
                      const SizedBox(height: 16),
                      // Center(
                      //   child: TextButton.icon(
                      //     onPressed: () {
                      //       ZoneSeeder.addSampleZone();
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //             content: Text(
                      //                 'Adding sample zone to Firebase...')),
                      //       );
                      //     },
                      //     icon: const Icon(Icons.add_box, size: 18),
                      //     label: const Text('Seed Sample Zone'),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── section builders ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Address Details',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _darkText,
              letterSpacing: -0.3,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.close, size: 20, color: _darkText),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _infoBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _infoText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ensure your address details are accurate for a smooth experience',
              style: TextStyle(
                fontSize: 13,
                color: _infoText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseField() {
    return TextFormField(
      controller: _houseCtrl,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: _darkText),
      decoration: _inputDeco('Flat/House/building name *'),
      validator: (v) => (v == null || v.trim().isEmpty)
          ? 'Please enter your flat/house/building name'
          : null,
    );
  }

  Widget _buildLocationTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _locationBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                const Text(
                  'Area / Sector / Locality',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _secondaryGray,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Full formatted address
                Text(
                  _line1,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _darkText,
                    height: 1.4,
                  ),
                ),
                // Bold district / state / pincode summary
                if (_line2.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _line2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _secondaryGray,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryBlue, width: 1.5),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneClassification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'District',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _secondaryGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _detectedDistrict ?? 'Unable to detect district',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Zone',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _secondaryGray,
                ),
              ),
              const SizedBox(height: 4),
              if (_isDetectingZone)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryBlue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Detecting zone...',
                      style: TextStyle(
                        fontSize: 14,
                        color: _secondaryGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              else if (_detectedZoneName != null)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _detectedZoneName!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Service zone not available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We couldn\'t find a service zone for this location. Please choose another location.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        height: 1.4,
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(fontSize: 14, color: _darkText),
      decoration: _inputDeco('Enter your full name *'),
      validator: (v) => (v == null || v.trim().isEmpty)
          ? 'Please enter your full name'
          : null,
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileCtrl,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: const TextStyle(fontSize: 14, color: _darkText),
      decoration: _inputDeco('10-digit mobile number *'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter your mobile number';
        }
        if (v.trim().length != 10) {
          return 'Mobile number must be exactly 10 digits';
        }
        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
          return 'Enter a valid Indian mobile number';
        }
        return null;
      },
    );
  }

  Widget _buildAltPhoneField() {
    return TextFormField(
      controller: _altPhoneCtrl,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      style: const TextStyle(fontSize: 14, color: _darkText),
      decoration: _inputDeco('Alternate phone number (Optional)'),
      validator: (v) {
        if (v != null && v.trim().isNotEmpty) {
          if (v.trim().length != 10) return 'Must be exactly 10 digits';
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
            return 'Enter a valid Indian mobile number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildAddressTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type of address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _secondaryGray,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _typeChip('Home', Icons.home_outlined),
            const SizedBox(width: 12),
            _typeChip('Work', Icons.business_outlined),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(String label, IconData icon) {
    final selected = _addressType == label;
    final color = selected ? _primaryBlue : _secondaryGray;
    return GestureDetector(
      onTap: () => setState(() => _addressType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEBF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _primaryBlue : _borderGray,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAddressToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDefaultAddress = !_isDefaultAddress;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Make this my default address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
            ),
            const SizedBox(width: 12),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _isDefaultAddress,
                onChanged: (val) {
                  setState(() {
                    _isDefaultAddress = val;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: _primaryBlue,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
                trackOutlineColor: WidgetStateProperty.all(
                  Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          disabledBackgroundColor: _primaryBlue.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                widget.isEdit ? 'Update address' : 'Save address',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  // ── shared input decoration ────────────────────────────────────────────────

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _secondaryGray),
        floatingLabelStyle: const TextStyle(fontSize: 12, color: _primaryBlue),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderGray, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      );
}

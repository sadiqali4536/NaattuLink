import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_success_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:naattulink/MVVM/View/Screen/location/select_location_map_page.dart';
import 'package:naattulink/MVVM/model/models/app_location_model.dart';
import 'package:intl/intl.dart';
import 'service_payment_page.dart';

class ServiceBookingSummaryPage extends StatefulWidget {
  final String serviceName;
  final dynamic price;
  final String image;
  final double rating;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String? serviceId;
  final String? serviceType;
  final String? providerId;
  final String? providerName;
  final String? providerPhone;
  final String? serviceDescription;
  final String? estimatedDuration;
  final String? serviceCategory;

  const ServiceBookingSummaryPage({
    Key? key,
    required this.serviceName,
    required this.price,
    required this.image,
    required this.rating,
    required this.selectedDate,
    required this.selectedTimeSlot,
    this.serviceType,
    this.serviceId,
    this.providerId,
    this.providerName,
    this.providerPhone,
    this.serviceDescription,
    this.estimatedDuration,
    this.serviceCategory,
  }) : super(key: key);

  @override
  State<ServiceBookingSummaryPage> createState() =>
      _ServiceBookingSummaryPageState();
}

class _ServiceBookingSummaryPageState extends State<ServiceBookingSummaryPage> {
  String addressTitle = "Current Location";
  String addressSubtitle = "Fetching address...";
  bool _isLoading = false;
  bool _isFetchingLocation = true;
  double? _latitude;
  double? _longitude;
  String? _receiverName;
  String? _receiverPhone;
  String? _alternatePhone;
  String? _landmark;
  String? _zoneName;

  double? _platformFee = 50.0;
  double? _taxFee = 0.0;
  bool _isFetchingFee = true;

  String? _paymentId;
  String? _bookingId;
  String? _paidUserName;
  String? _paymentTime;
  String? _qrGeneratedTime;

  @override
  void initState() {
    super.initState();
    _fetchDefaultAddress();
    _fetchPlatformFee();
  }

  Future<void> _fetchPlatformFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_settings')
          .doc('general')
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final status = data['ServicePlatformFeeStatus'];
        if (status == 'Inactive' || status == false) {
          setState(() {
            _platformFee = null;
          });
        } else {
          final feeStr = data['ServicePlatformFee']?.toString();
          setState(() {
            _platformFee = double.tryParse(feeStr ?? '50.0') ?? 50.0;
          });
        }

        final gstStatus = data['ServiceGSTFeeStatus'];
        if (gstStatus == false ||
            gstStatus == 'false' ||
            gstStatus == 'Inactive') {
          setState(() {
            _taxFee = null;
          });
        } else {
          final gstFeeStr = data['ServiceGSTFee']?.toString();
          setState(() {
            _taxFee = double.tryParse(gstFeeStr ?? '5.0') ?? 5.0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching platform fee: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingFee = false;
        });
      }
    }
  }

  Future<void> _fetchDefaultAddress() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists &&
            doc.data() != null &&
            doc.data()!.containsKey('primaryAddress')) {
          final pAddr = doc.data()!['primaryAddress'];
          if (pAddr != null) {
            setState(() {
              addressTitle =
                  pAddr['addressType'] ?? pAddr['receiverName'] ?? "Home";

              String formatted = pAddr['formattedAddress']?.toString() ??
                  pAddr['address']?.toString() ??
                  '';
              if (formatted.isEmpty) {
                List<String> fallbacks = [];
                if (pAddr['locality'] != null &&
                    pAddr['locality'].toString().isNotEmpty)
                  fallbacks.add(pAddr['locality'].toString());
                if (pAddr['district'] != null &&
                    pAddr['district'].toString().isNotEmpty)
                  fallbacks.add(pAddr['district'].toString());
                if (pAddr['state'] != null &&
                    pAddr['state'].toString().isNotEmpty)
                  fallbacks.add(pAddr['state'].toString());
                formatted = fallbacks.join(', ');
              }

              String fullAddress = formatted;
              _landmark = pAddr['landmark']?.toString();

              addressSubtitle = fullAddress.isNotEmpty
                  ? fullAddress
                  : "Address details not available";
              _latitude = pAddr['latitude']?.toDouble();
              _longitude = pAddr['longitude']?.toDouble();
              _receiverName = pAddr['receiverName']?.toString();
              _receiverPhone = pAddr['receiverPhone']?.toString();
              _alternatePhone = pAddr['alternatePhone']?.toString();
              _zoneName = pAddr['zoneName']?.toString();
            });
            return;
          }
        }
      }

      setState(() {
        addressTitle = "No Address Selected";
        addressSubtitle = "Please tap edit to select your address.";
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          addressSubtitle = 'Failed to get saved location';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _editAddress() async {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Select Address",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2E5A))),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.my_location,
                          color: Color(0xFF059669)),
                      title: const Text("Use Current Location",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669))),
                      onTap: () async {
                        Navigator.pop(context); // close bottom sheet
                        _openMapForCurrentLocation();
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('delivery_addresses')
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text("No saved addresses"));
                          }
                          final docs = snapshot.data!.docs.toList();
                          docs.sort((a, b) {
                            final dataA = a.data() as Map<String, dynamic>;
                            final dataB = b.data() as Map<String, dynamic>;

                            bool isASelected = false;
                            bool isBSelected = false;
                            if (_latitude != null && _longitude != null) {
                              if (dataA['latitude']?.toDouble() == _latitude &&
                                  dataA['longitude']?.toDouble() ==
                                      _longitude) {
                                isASelected = true;
                              }
                              if (dataB['latitude']?.toDouble() == _latitude &&
                                  dataB['longitude']?.toDouble() ==
                                      _longitude) {
                                isBSelected = true;
                              }
                            }

                            if (isASelected && !isBSelected) return -1;
                            if (!isASelected && isBSelected) return 1;

                            bool isADefault = dataA['isDefault'] == 1 ||
                                dataA['isPrimary'] == true;
                            bool isBDefault = dataB['isDefault'] == 1 ||
                                dataB['isPrimary'] == true;

                            if (isADefault && !isBDefault) return -1;
                            if (!isADefault && isBDefault) return 1;

                            return 0;
                          });
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;

                              String formatted =
                                  data['formattedAddress']?.toString() ??
                                      data['address']?.toString() ??
                                      '';
                              if (formatted.isEmpty) {
                                List<String> fallbacks = [];
                                if (data['locality'] != null &&
                                    data['locality'].toString().isNotEmpty)
                                  fallbacks.add(data['locality'].toString());
                                if (data['district'] != null &&
                                    data['district'].toString().isNotEmpty)
                                  fallbacks.add(data['district'].toString());
                                if (data['state'] != null &&
                                    data['state'].toString().isNotEmpty)
                                  fallbacks.add(data['state'].toString());
                                formatted = fallbacks.join(', ');
                              }

                              String displayAddress = formatted;
                              if (data['landmark'] != null &&
                                  data['landmark'].toString().isNotEmpty) {
                                displayAddress = displayAddress.isEmpty
                                    ? data['landmark'].toString()
                                    : "${data['landmark']}, $displayAddress";
                              }

                              if (displayAddress.isEmpty) {
                                displayAddress =
                                    "Address details not available";
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    addressTitle = data['addressType'] ??
                                        data['name'] ??
                                        data['receiverName'] ??
                                        "Saved Address";
                                    addressSubtitle = formatted;
                                    _landmark = (data['buildingName'] ??
                                            data['landmark'])
                                        ?.toString();
                                    _latitude = data['latitude']?.toDouble();
                                    _longitude = data['longitude']?.toDouble();
                                    _receiverName =
                                        (data['name'] ?? data['receiverName'])
                                            ?.toString();
                                    _receiverPhone =
                                        (data['phone'] ?? data['receiverPhone'])
                                            ?.toString();
                                    _alternatePhone =
                                        (data['alternativeNumber'] ??
                                                data['alternatePhone'])
                                            ?.toString();
                                    _zoneName = data['zoneName']?.toString();
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF0F2E5A),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if ((data['name'] ??
                                                        data['receiverName']) !=
                                                    null &&
                                                (data['name'] ??
                                                        data['receiverName'])
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              Row(
                                                children: [
                                                  Text(
                                                    (data['name'] ??
                                                            data[
                                                                'receiverName'])
                                                        .toString(),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (data['addressType'] !=
                                                          null &&
                                                      data['addressType']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade200,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        data['addressType']
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black54),
                                                      ),
                                                    ),
                                                  if (data['isDefault'] == 1 ||
                                                      data['isPrimary'] ==
                                                          true) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.blue.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        border: Border.all(
                                                            color: Colors
                                                                .blue.shade200),
                                                      ),
                                                      child: Text(
                                                        "Default",
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .blue.shade700),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            if ((data['buildingName'] ??
                                                        data['landmark']) !=
                                                    null &&
                                                (data['buildingName'] ??
                                                        data['landmark'])
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              Text(
                                                (data['buildingName'] ??
                                                        data['landmark'])
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              formatted,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                  height: 1.3),
                                            ),
                                            if ((data['phone'] ??
                                                        data[
                                                            'receiverPhone']) !=
                                                    null &&
                                                (data['phone'] ??
                                                        data['receiverPhone'])
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                "Phone: ${(data['phone'] ?? data['receiverPhone'])}",
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                            if ((data['alternativeNumber'] ??
                                                        data[
                                                            'alternatePhone']) !=
                                                    null &&
                                                (data['alternativeNumber'] ??
                                                        data['alternatePhone'])
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                "Alt Phone: ${(data['alternativeNumber'] ?? data['alternatePhone'])}",
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  Future<Map<String, String>?> _showAddressDetailsDialog() async {
    final houseCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final altPhoneCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    String userName = user?.displayName ?? 'User';

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Enter Address Details",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: houseCtrl,
                    decoration: InputDecoration(
                      labelText: "House/Building/Flat Name",
                      labelStyle: TextStyle(color: Colors.grey.shade700),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF0F2E5A), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle: TextStyle(color: Colors.grey.shade700),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF0F2E5A), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: altPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: "Alternate Phone Number (Optional)",
                      labelStyle: TextStyle(color: Colors.grey.shade700),
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
                        borderSide: const BorderSide(
                            color: Color(0xFF0F2E5A), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFF0F2E5A)),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2E5A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (houseCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Please enter House/Building Name")));
                              return;
                            }
                            if (phoneCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Please enter Phone Number")));
                              return;
                            }
                            if (phoneCtrl.text.trim().length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Please enter a valid 10-digit Phone Number")));
                              return;
                            }
                            if (altPhoneCtrl.text.trim().isNotEmpty &&
                                altPhoneCtrl.text.trim().length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Please enter a valid 10-digit Alternate Phone Number")));
                              return;
                            }
                            Navigator.pop(context, {
                              'landmark': houseCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'altPhone': altPhoneCtrl.text.trim(),
                              'name': userName,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2E5A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Confirm",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMapForCurrentLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocationMapPage(
          initialLat: _latitude ?? 11.0168,
          initialLng: _longitude ?? 76.9558,
          flow: LocationPickerFlow.serviceBooking,
          requireZone: true,
        ),
      ),
    );

    if (result != null && result is AppLocationModel) {
      final details = await _showAddressDetailsDialog();
      if (details != null) {
        if (mounted) {
          setState(() {
            addressTitle = result.addressType ?? "Selected Location";
            addressSubtitle = result.formattedAddress;
            _landmark = details['landmark'];
            _latitude = result.latitude;
            _longitude = result.longitude;
            _receiverName = details['name'];
            _receiverPhone = details['phone'];
            _alternatePhone = details['altPhone'];
            _zoneName = result.zoneName;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final bgLight = const Color(0xFFF8FAFC);

    // Calculate prices
    final serviceCharge = double.tryParse(widget.price.toString()) ?? 299.0;
    final double? tax = _taxFee;
    final double? confirmationFee = _platformFee; // Loaded from Firestore
    final total = serviceCharge + (tax ?? 0.0) + (confirmationFee ?? 0.0);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        title: const Text(
          "Booking Summary",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF065F46),
                              backgroundImage: widget.image.startsWith('http')
                                  ? NetworkImage(widget.image)
                                  : (widget.image.isNotEmpty
                                      ? AssetImage(widget.image)
                                          as ImageProvider
                                      : null),
                              child: widget.image.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white, size: 36)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Color(0xFF059669), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Service Schedule",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.serviceType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.serviceType == "Urgent"
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.serviceType!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.serviceType == "Urgent"
                                  ? Colors.orange.shade800
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today_outlined,
                              color: Color(0xFF059669), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "DATE & TIME",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy')
                                    .format(widget.selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (widget.selectedTimeSlot.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  "Arrival Time: ${widget.selectedTimeSlot}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Address Card
                  GestureDetector(
                    onTap: _editAddress,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_outlined,
                                color: Color(0xFF3B82F6), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "SERVICE ADDRESS",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_receiverName != null &&
                                    _receiverName!.isNotEmpty) ...[
                                  Text(
                                    "$_receiverName${addressTitle != "Current Location" && addressTitle != "Selected Location" && addressTitle != "No Address Selected" ? " ($addressTitle)" : ""}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (_landmark != null &&
                                    _landmark!.isNotEmpty) ...[
                                  Text(
                                    _landmark!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  addressSubtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                    height: 1.3,
                                  ),
                                ),
                                if (_receiverPhone != null &&
                                    _receiverPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "Phone: $_receiverPhone",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                                if (_alternatePhone != null &&
                                    _alternatePhone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Alt Phone: $_alternatePhone",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_outlined,
                              color: Color(0xFF059669), size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Map Area Card
                  GestureDetector(
                    onTap: () async {
                      if (_latitude != null && _longitude != null) {
                        final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) {
                            CherryToast.error(
                              title: const Text('Could not open map'),
                            ).show(context);
                          }
                        }
                      } else {
                        if (mounted) {
                          CherryToast.warning(
                            title: const Text('Location not available yet'),
                          ).show(context);
                        }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            if (_latitude != null && _longitude != null)
                              AbsorbPointer(
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_latitude!, _longitude!),
                                    zoom: 15.0,
                                  ),
                                  zoomControlsEnabled: false,
                                  mapToolbarEnabled: false,
                                  myLocationButtonEnabled: false,
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('selected_loc'),
                                      position: LatLng(_latitude!, _longitude!),
                                    ),
                                  },
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.send_rounded,
                                        size: 12, color: Color(0xFF059669)),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Service area: ${_isFetchingLocation ? 'Fetching...' : (_zoneName ?? addressTitle)}",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Payment Summary",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentRow(
                            "Service Charge", "₹${serviceCharge.toInt()}"),
                        if (tax != null && tax > 0) ...[
                          const SizedBox(height: 10),
                          _buildPaymentRow("Tax (GST)", "₹${tax.toInt()}"),
                        ],
                        if (confirmationFee != null && confirmationFee > 0) ...[
                          const SizedBox(height: 10),
                          _buildPaymentRow("Booking Confirmation Fee",
                              "₹${confirmationFee.toInt()}"),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Amount",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${total.toInt()}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                const Text(
                                  "Inclusive of all charges",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security,
                                  color: Color(0xFF059669), size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: const Text(
                                  "Payments are secured with 256-bit encryption. You only pay after service completion.",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF3B82F6), size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                "If the worker does not arrive or the booking is cancelled, the confirmation fee will be fully refunded.",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_paymentId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Paid Payment Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: const Text(
                      "Payment Successful",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentRow("Amount", "₹${total.toInt()}"),
                  const SizedBox(height: 10),
                  if (_paidUserName != null) ...[
                    _buildPaymentRow("Paid by", _paidUserName!),
                    const SizedBox(height: 10),
                  ],
                  if (_paymentTime != null) ...[
                    _buildPaymentRow("Payment time", _paymentTime!),
                    const SizedBox(height: 10),
                  ],
                  _buildPaymentRow("Transaction ID", _paymentId!),
                  if (_qrGeneratedTime != null) ...[
                    const SizedBox(height: 16),
                    _buildPaymentRow("QR generated", _qrGeneratedTime!),
                  ],
                ],
              ),
            ),
          ],

          // Bottom Sticky Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading ||
                            _isFetchingLocation ||
                            _latitude == null ||
                            _longitude == null)
                        ? null
                        : () async {
                            final bool hasUpfrontFees =
                                (tax != null && tax > 0) ||
                                    (confirmationFee != null &&
                                        confirmationFee > 0);

                            setState(() => _isLoading = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              String currentBookingId = _bookingId ?? '';

                              if (currentBookingId.isEmpty) {
                                final bookingRef = await FirebaseFirestore
                                    .instance
                                    .collection('service_bookings')
                                    .add({
                                  'userId': user?.uid,
                                  'userEmail': user?.email,
                                  'userName': _receiverName,
                                  'alternatePhone': _alternatePhone,
                                  'serviceId': widget.serviceId,
                                  'serviceName': widget.serviceName,
                                  'serviceCategory': widget.serviceCategory,
                                  'serviceType': widget.serviceType,
                                  'providerId': widget.providerId,
                                  'providerName': widget.providerName,
                                  'providerPhone': widget.providerPhone,
                                  'image': widget.image,
                                  'price': widget.price,
                                  'rating': widget.rating,
                                  'selectedDate':
                                      widget.selectedDate.toIso8601String(),
                                  'selectedTimeSlot': widget.selectedTimeSlot,
                                  'estimatedDuration': widget.estimatedDuration,
                                  'addressTitle': addressTitle,
                                  'addressSubtitle': addressSubtitle,
                                  'houseBuildingNumber': _landmark ?? '',
                                  'latitude': _latitude,
                                  'longitude': _longitude,
                                  'serviceZone': _zoneName ?? '',
                                  'serviceCharge': serviceCharge,
                                  'confirmationFee': confirmationFee ??
                                      'confirmation fee is off',
                                  'taxAmount': tax ?? 'gst is off',
                                  'totalAmount': total,
                                  'status': hasUpfrontFees
                                      ? 'pending_payment'
                                      : 'confirmed',
                                  'paymentStatus': hasUpfrontFees
                                      ? 'Pending'
                                      : 'No Payment Required',
                                  'paymentId': null,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                currentBookingId = bookingRef.id;
                                _bookingId = currentBookingId;
                              }

                              if (hasUpfrontFees && _paymentId == null) {
                                setState(() => _isLoading = false);
                                final result =
                                    await Get.to(() => ServicePaymentPage(
                                          bookingId: currentBookingId,
                                          totalAmount: total,
                                        ));
                                if (result != null && result is Map) {
                                  setState(() {
                                    _paymentId =
                                        result['paymentId']?.toString().trim();
                                    _paidUserName =
                                        result['paidUserName']?.toString();
                                    _paymentTime =
                                        result['paymentTime']?.toString();
                                    _qrGeneratedTime =
                                        result['qrGeneratedTime']?.toString();
                                  });
                                } else if (result != null &&
                                    result.toString().trim().isNotEmpty) {
                                  setState(() {
                                    _paymentId = result.toString().trim();
                                  });
                                }
                                return;
                              }

                              if (hasUpfrontFees && _paymentId != null) {
                                final paymentRef = FirebaseFirestore.instance
                                    .collection('payments')
                                    .doc(_paymentId);
                                final existingPayment = await paymentRef.get();

                                if (!existingPayment.exists) {
                                  await paymentRef.set({
                                    'amount': '₹${total.toStringAsFixed(0)}',
                                    'bookingId': currentBookingId,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'dateTime': DateFormat('yyyy-MM-dd HH:mm')
                                        .format(DateTime.now()),
                                    'itemName': 'Service',
                                    'paymentMode': 'UPI',
                                    'status': 'Submitted',
                                    'transactionId': _paymentId,
                                  });
                                }

                                await FirebaseFirestore.instance
                                    .collection('service_bookings')
                                    .doc(currentBookingId)
                                    .update({
                                  'status': 'confirmed',
                                  'paymentStatus': 'Submitted',
                                  'paymentId': _paymentId,
                                  'confirmedAt': FieldValue.serverTimestamp(),
                                });
                              }

                              if (!mounted) return;
                              Get.off(
                                () => BookingSuccessPage(
                                  bookingId: currentBookingId
                                      .substring(0, 8)
                                      .toUpperCase(),
                                  serviceName: widget.serviceName,
                                  date: widget.selectedDate,
                                  timeSlot: widget.selectedTimeSlot,
                                  serviceType:
                                      widget.serviceType ?? 'Scheduled',
                                ),
                                transition: Transition.fadeIn,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              CherryToast.error(
                                title: const Text("Booking Failed!"),
                                description: Text(
                                    "Something went wrong. Please try again."),
                              ).show(context);
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Confirm Booking",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "By confirming, you agree to our Terms of Service",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

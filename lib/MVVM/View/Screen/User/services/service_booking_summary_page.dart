import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_success_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cherry_toast/cherry_toast.dart';

class ServiceBookingSummaryPage extends StatefulWidget {
  final String serviceName;
  final dynamic price;
  final String image;
  final double rating;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final String? serviceId;
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

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isFetchingLocation = true;
    });

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          addressSubtitle = 'Location services are disabled.';
          _isFetchingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            addressSubtitle = 'Location permissions are denied';
            _isFetchingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          addressSubtitle =
              'Location permissions are permanently denied, we cannot request permissions.';
          _isFetchingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _latitude = position.latitude;
      _longitude = position.longitude;

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          addressTitle = place.name ?? "Home";
          addressSubtitle =
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}'
                  .replaceAll(RegExp(r',\s*,'), ',')
                  .replaceAll(RegExp(r'^,\s*'), '')
                  .replaceAll(RegExp(r',\s*$'), '');
        });
      }
    } catch (e) {
      setState(() {
        addressSubtitle = 'Failed to get location';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  void _editAddress() {
    TextEditingController titleController =
        TextEditingController(text: addressTitle);
    TextEditingController subtitleController =
        TextEditingController(text: addressSubtitle);

    showDialog(
      context: context,
      builder: (context) {
        bool isFetchingDialog = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Address",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2E5A),
                    ),
                  ),
                  IconButton(
                    icon: isFetchingDialog
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF059669)),
                          )
                        : const Icon(Icons.my_location,
                            color: Color(0xFF059669)),
                    onPressed: isFetchingDialog
                        ? null
                        : () async {
                            setStateDialog(() {
                              isFetchingDialog = true;
                            });
                            try {
                              bool serviceEnabled =
                                  await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) {
                                CherryToast.warning(
                                  title: const Text(
                                      'Location services are disabled.'),
                                ).show(context);
                                return;
                              }

                              LocationPermission permission =
                                  await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission =
                                    await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied)
                                  return;
                              }

                              if (permission ==
                                  LocationPermission.deniedForever) {
                                return;
                              }

                              Position position =
                                  await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high);

                              _latitude = position.latitude;
                              _longitude = position.longitude;

                              List<Placemark> placemarks =
                                  await placemarkFromCoordinates(
                                      position.latitude, position.longitude);

                              if (placemarks.isNotEmpty) {
                                Placemark place = placemarks[0];
                                titleController.text = place.name ?? "Home";
                                subtitleController.text =
                                    '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}'
                                        .replaceAll(RegExp(r',\s*,'), ',')
                                        .replaceAll(RegExp(r'^,\s*'), '')
                                        .replaceAll(RegExp(r',\s*$'), '');
                              }
                            } catch (e) {
                              CherryToast.error(
                                title: const Text('Failed to get location'),
                              ).show(context);
                            } finally {
                              if (mounted) {
                                setStateDialog(() {
                                  isFetchingDialog = false;
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subtitleController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Full Address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2E5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      addressTitle = titleController.text;
                      addressSubtitle = subtitleController.text;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final bgLight = const Color(0xFFF8FAFC);

    // Calculate prices
    final visitCharge = double.tryParse(widget.price.toString()) ?? 299.0;
    final tax = 0.0;
    final confirmationFee = 50.0;
    final total = visitCharge + tax + confirmationFee;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
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
                  const Text(
                    "Service Schedule",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                              const SizedBox(height: 2),
                              Text(
                                widget.selectedTimeSlot,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
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
                                const SizedBox(height: 4),
                                Text(
                                  addressSubtitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
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
                        image: const DecorationImage(
                          image: NetworkImage(
                              "https://basemaps.cartocdn.com/light_nolabels/13/4093/2724.png"),
                          fit: BoxFit.cover,
                          opacity: 0.8,
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded,
                                size: 12, color: Color(0xFF059669)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Service area: ${_isFetchingLocation ? 'Fetching...' : addressTitle}",
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
                            "Visit Charge", "₹${visitCharge.toInt()}"),
                        const SizedBox(height: 10),
                        _buildPaymentRow("Tax (GST)", "₹${tax.toInt()}"),
                        const SizedBox(height: 10),
                        _buildPaymentRow("Booking Confirmation Fee",
                            "₹${confirmationFee.toInt()}"),
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
                    onPressed: () {
                      // Final Confirm action
                      CherryToast.success(
                        title: const Text("Booking Confirmed!"),
                      ).show(context);
                      // Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
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

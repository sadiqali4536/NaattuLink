import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'auto_taxi_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';

class VehicleDetailsPage extends StatelessWidget {
  final AutoTaxiListing listing;

  const VehicleDetailsPage({Key? key, required this.listing}) : super(key: key);

  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError(
          "Could not start call. Number: ${phoneNumber.replaceFirst('tel:', '')}");
    }
  }

  List<Map<String, dynamic>> _getAgencyFleet(String agencyName) {
    if (agencyName.toLowerCase().contains('malabar')) {
      return [
        {
          "name": "AC Sedan",
          "models": "Maruti Dzire, Toyota Etios",
          "capacity": "4 Passengers",
          "price": "₹12/km",
          "minCharge": "₹150 (first 3 km)",
          "icon": Icons.directions_car_outlined,
          "luggage": "2 Bags",
          "ac": "Fully Air Conditioned"
        },
        {
          "name": "AC SUV",
          "models": "Maruti Ertiga, Toyota Innova",
          "capacity": "6-7 Passengers",
          "price": "₹18/km",
          "minCharge": "₹300 (first 3 km)",
          "icon": Icons.airport_shuttle_outlined,
          "luggage": "4 Bags",
          "ac": "Fully Air Conditioned"
        },
        {
          "name": "Premium Luxury SUV",
          "models": "Toyota Fortuner",
          "capacity": "7 Passengers",
          "price": "₹35/km",
          "minCharge": "₹1,000 (first 10 km)",
          "icon": Icons.car_rental_outlined,
          "luggage": "4 Bags",
          "ac": "Fully Air Conditioned"
        }
      ];
    } else {
      return [
        {
          "name": "Tempo Traveller (12S)",
          "models": "Force Traveller (Standard)",
          "capacity": "12 Passengers",
          "price": "₹24/km",
          "minCharge": "₹3,500 (flat package base)",
          "icon": Icons.airport_shuttle_outlined,
          "luggage": "Large Carrier",
          "ac": "AC / Non-AC options"
        },
        {
          "name": "Tempo Traveller (17S)",
          "models": "Force Traveller (Pushback)",
          "capacity": "17 Passengers",
          "price": "₹28/km",
          "minCharge": "₹5,000 (flat package base)",
          "icon": Icons.directions_bus_outlined,
          "luggage": "Large Carrier",
          "ac": "AC Available"
        },
        {
          "name": "Luxury Mini Bus",
          "models": "Tata / Eicher Premium Bus",
          "capacity": "26 Passengers",
          "price": "₹38/km",
          "minCharge": "₹8,500 (flat package base)",
          "icon": Icons.directions_bus,
          "luggage": "Under-seat & Rear Boot",
          "ac": "Fully Air Conditioned"
        }
      ];
    }
  }

  String _getVehicleImage(String type) {
    if (type.toLowerCase().contains('auto')) {
      return 'https://images.unsplash.com/photo-1561361513-2d000a50f0db?auto=format&fit=crop&w=800&q=80';
    } else if (type.toLowerCase().contains('van') ||
        type.toLowerCase().contains('traveller')) {
      return 'https://images.unsplash.com/photo-1532581291347-9c39cf10a73c?auto=format&fit=crop&w=800&q=80';
    } else {
      return 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=800&q=80';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final textGrey = const Color(0xFF64748B);
    final bgLight = const Color(0xFFF8FAFC);
    final goldColor = const Color(0xFFFFB800);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          "Vehicle Details",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F2E5A)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sharing driver details..."),
                  backgroundColor: Color(0xFF0F2E5A),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Image Section with overlay
                  Stack(
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bgLight,
                        ),
                        child: Center(
                          child: Icon(
                            listing.isAgency
                                ? Icons.domain_outlined
                                : (listing.type.toLowerCase().contains('auto')
                                    ? Icons.electric_rickshaw_outlined
                                    : Icons.local_taxi_outlined),
                            size: 100,
                            color: primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.stars, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Premium Fleet",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver Name & Verification Badge
                        Row(
                          children: [
                            Text(
                              listing.name,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            if (listing.isVerified)
                              const Icon(Icons.verified_user_rounded,
                                  color: Color(0xFF4F46E5), size: 18),
                            if (listing.isElectric)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.bolt,
                                    color: Color(0xFF059669), size: 18),
                              ),
                            if (listing.isWomenDriver)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.person_pin_circle,
                                    color: Color(0xFFec4899), size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Rating & Experience
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFFB800), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              listing.rating,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              " (1.2k+ Reviews)  •  ",
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 13,
                              ),
                            ),
                            Icon(Icons.trending_up, color: textGrey, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              listing.experienceOrVehicles,
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Driver Avatar
                        // CircleAvatar(
                        //   radius: 20,
                        //   backgroundColor: bgLight,
                        //   backgroundImage: const NetworkImage(
                        //     'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80',
                        //   ),
                        // ),
                        // const SizedBox(height: 24),

                        // Details Grid (2 columns)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          children: [
                            _buildDetailCard(
                              icon: Icons.people_outline,
                              iconColor: const Color(0xFF4F46E5),
                              label: "Seating",
                              value: listing.seating,
                              bgColor: bgLight,
                            ),
                            _buildDetailCard(
                              icon: Icons.ac_unit_outlined,
                              iconColor: const Color(0xFF0ea5e9),
                              label: "AC Status",
                              value: listing.acStatus,
                              bgColor: bgLight,
                            ),
                            _buildDetailCard(
                              icon: Icons.electric_rickshaw_outlined,
                              iconColor: const Color(0xFFeab308),
                              label: "Vehicle",
                              value: listing.vehicleDetails,
                              bgColor: bgLight,
                            ),
                            _buildDetailCard(
                              icon: Icons.business_center_outlined,
                              iconColor: const Color(0xFFf97316),
                              label: "Luggage",
                              value: listing.luggage,
                              bgColor: bgLight,
                            ),
                            _buildDetailCard(
                              icon: Icons.pin_outlined,
                              iconColor: const Color(0xFFec4899),
                              label: "Reg. No.",
                              value: listing.regNo,
                              bgColor: bgLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const SizedBox(height: 24),
                        if (listing.isAgency) ...[
                          Text(
                            "Available Fleet & Rates",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._getAgencyFleet(listing.name).map((fleetItem) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: bgLight,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          fleetItem['icon'] as IconData,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fleetItem['name'] as String,
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              fleetItem['models'] as String,
                                              style: TextStyle(
                                                color: textGrey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            fleetItem['price'] as String,
                                            style: const TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Rate",
                                            style: TextStyle(
                                              color: textGrey,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(
                                      color: Color(0xFFE2E8F0), height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.people_outline,
                                              color: textGrey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            fleetItem['capacity'] as String,
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.ac_unit,
                                              color: textGrey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            "AC Included",
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.business_center_outlined,
                                              color: textGrey, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            fleetItem['luggage'] as String,
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: goldColor, size: 12),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "Base Price: ${fleetItem['minCharge']}",
                                          style: TextStyle(
                                            color: textGrey,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ] else ...[
                          Text(
                            "Transparent Pricing",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Minimum Charge",
                                      style: TextStyle(
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "₹${listing.minCharge}",
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "* Prices are indicative and may vary based on time and traffic.",
                                  style: TextStyle(
                                    color: textGrey.withOpacity(0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // About Driver Section
                        Text(
                          "About Driver",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.aboutDriver,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              if (listing.quoteText.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF059669)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    "\"${listing.quoteText}\"",
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Persistent Bottom Call Button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: OutlinedButton.icon(
                onPressed: () => _makeCall(context, listing.phone),
                icon: Icon(Icons.phone_outlined, color: primaryColor, size: 18),
                label: Text(
                  "Call Now",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor, width: 1.5),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F2E5A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

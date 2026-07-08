import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'auto_taxi_page.dart';

class AgencyPackagesPage extends StatelessWidget {
  final AutoTaxiListing agency;

  const AgencyPackagesPage({Key? key, required this.agency}) : super(key: key);

  List<Map<String, dynamic>> _getAgencyPackages() {
    if (agency.name.contains('Malabar')) {
      return [
        {
          "title": "Calicut Sightseeing Tour",
          "duration": "8 Hours / 80 Km",
          "icon": Icons.map_outlined,
          "description":
              "Explore Calicut beach, Kappad beach, Mananchira Square, and local culinary hubs.",
          "withVehiclePrice": "₹1,500",
          "withVehicleDetails":
              "AC Sedan (Maruti Dzire / Toyota Etios) - 4 Passengers max",
          "withoutVehiclePrice": "₹800",
          "withoutVehicleDetails":
              "Driver/Guide Only (Customer provides the vehicle)",
          "inclusions": [
            "Driver Food & Allowance",
            "Local Route Expertise",
            "Fuel & Tolls (With Vehicle option only)"
          ],
          "extraCharges":
              "Extra Km: ₹14/km after 80 Km (With Vehicle option only)."
        },
        {
          "title": "Airport Transfer (CCJ)",
          "duration": "One-Way Transfer",
          "icon": Icons.local_airport_outlined,
          "description":
              "Hassle-free pickup or drop-off service from Calicut International Airport.",
          "withVehiclePrice": "₹1,200",
          "withVehicleDetails": "AC Sedan (Toyota Etios) with Luggage Carrier",
          "withoutVehiclePrice": "₹600",
          "withoutVehicleDetails":
              "Driver Only (Customer provides the vehicle)",
          "inclusions": [
            "Airport Toll & Parking (With Vehicle option)",
            "Flight Tracking & Delay Wait",
            "Luggage Assistance"
          ],
          "extraCharges": "Night charges may apply between 11 PM to 5 AM."
        },
        {
          "title": "Wayanad Hill Station Package",
          "duration": "1 Day Round Trip (12 hrs)",
          "icon": Icons.landscape_outlined,
          "description":
              "Scenic trip to Lakkidi View Point, Pookode Lake, and Banasura Sagar Dam.",
          "withVehiclePrice": "₹3,500",
          "withVehicleDetails": "AC Ertiga / Innova (SUV) - 6 Passengers max",
          "withoutVehiclePrice": "₹1,800",
          "withoutVehicleDetails":
              "Driver Only (Customer provides the vehicle)",
          "inclusions": [
            "Hill Station Permits & Tolls",
            "12 Hours Disposal",
            "Driver Fooding Included"
          ],
          "extraCharges": "Parking fees to be paid directly by the customer."
        }
      ];
    } else {
      // Default / Calicut Wheels Van Services
      return [
        {
          "title": "Coorg Group Trip (12-Seater)",
          "duration": "2 Days / 1 Night",
          "icon": Icons.groups_outlined,
          "description":
              "Perfect weekend getaway tour for groups to explore Madikeri, Abbey Falls, and Golden Temple.",
          "withVehiclePrice": "₹8,500",
          "withVehicleDetails": "AC Force Traveller (12S, Pushback Seats)",
          "withoutVehiclePrice": "₹4,000",
          "withoutVehicleDetails": "Professional Heavy Vehicle Driver Only",
          "inclusions": [
            "Heavy Driver Allowance",
            "State Border Permits (With Vehicle)",
            "Driver Boarding & Lodging"
          ],
          "extraCharges":
              "Sightseeing entry tickets and parking fees are extra."
        },
        {
          "title": "Ooty Weekend Getaway (17-Seater)",
          "duration": "3 Days / 2 Nights",
          "icon": Icons.explore_outlined,
          "description":
              "High-altitude group travel covering Ooty Botanical Gardens, Doddabetta Peak, and Pykara Falls.",
          "withVehiclePrice": "₹12,000",
          "withVehicleDetails": "AC Force Traveller (17S, Premium Audio)",
          "withoutVehiclePrice": "₹5,500",
          "withoutVehicleDetails": "Professional Heavy Vehicle Driver Only",
          "inclusions": [
            "State Border Permits (With Vehicle)",
            "1000 Km Limit (With Vehicle)",
            "Driver Food & Lodging"
          ],
          "extraCharges": "Extra Km charged at ₹20/km (With Vehicle option)."
        },
        {
          "title": "Local Wedding / Event Disposal",
          "duration": "10 Hours / 100 Km",
          "icon": Icons.celebration_outlined,
          "description":
              "Dedicated luxury van service for guest transfers, weddings, and functions in Calicut.",
          "withVehiclePrice": "₹5,000",
          "withVehicleDetails": "AC Traveller (17-Seater, Clean Interiors)",
          "withoutVehiclePrice": "₹2,500",
          "withoutVehicleDetails": "Heavy Vehicle Driver Only",
          "inclusions": [
            "Flexible Route Choice",
            "Neat & Uniformed Driver",
            "Decorations Allowed (External)"
          ],
          "extraCharges":
              "₹180/hour after 10 hours. Extra Km at ₹18/km (With Vehicle)."
        }
      ];
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError(
          "Could not start call. Number: ${phoneNumber.replaceFirst('tel:', '')}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final textGrey = const Color(0xFF64748B);
    final bgLight = const Color(0xFFF8FAFC);

    final packages = _getAgencyPackages();

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: customBackbutton1(
            onpress: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          "${agency.name} Packages",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agency header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.domain_outlined,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  agency.name,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFFFFB800),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFB800), size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  agency.rating,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.place_outlined,
                                    color: textGrey, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  agency.location,
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Text(
                    "About Agency",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agency.aboutDriver,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Available Tour Packages",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Packages list using stateful PackageCardWidget
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                return PackageCardWidget(
                  package: packages[index],
                  phone: agency.phone,
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PackageCardWidget extends StatefulWidget {
  final Map<String, dynamic> package;
  final String phone;

  const PackageCardWidget({
    Key? key,
    required this.package,
    required this.phone,
  }) : super(key: key);

  @override
  State<PackageCardWidget> createState() => _PackageCardWidgetState();
}

class _PackageCardWidgetState extends State<PackageCardWidget> {
  bool _withVehicle = true;

  Future<void> _makeCall(String phoneNumber) async {
    final Uri url = Uri.parse(phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      toastError(
          "Could not start call. Number: ${phoneNumber.replaceFirst('tel:', '')}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final goldColor = const Color(0xFFFFB800);
    final textGrey = const Color(0xFF64748B);

    final currentPrice = _withVehicle
        ? widget.package['withVehiclePrice'] as String
        : widget.package['withoutVehiclePrice'] as String;

    final currentDetails = _withVehicle
        ? widget.package['withVehicleDetails'] as String
        : widget.package['withoutVehicleDetails'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.package['icon'] as IconData,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.package['title'] as String,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, color: textGrey, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            widget.package['duration'] as String,
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 12,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.package['description'] as String,
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sliding Segmented Toggle for Pricing Option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _withVehicle = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _withVehicle ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "With Vehicle",
                          style: TextStyle(
                            color: _withVehicle ? Colors.white : textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _withVehicle = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              !_withVehicle ? primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Without Vehicle",
                          style: TextStyle(
                            color: !_withVehicle ? Colors.white : textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price & Vehicle Details Info Box
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _withVehicle
                          ? "Total Package Price"
                          : "Driver/Guide Service Price",
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currentPrice,
                      style: TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 10),

                // Option details (vehicle type / driver information)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _withVehicle
                          ? Icons.directions_car
                          : Icons.person_outline,
                      color: primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentDetails,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Package Inclusions
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Included Services",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: (widget.package['inclusions'] as List<String>)
                      .map((inclusion) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                inclusion,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: goldColor, size: 13),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        "Fine Print: ${widget.package['extraCharges']}",
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _makeCall(widget.phone),
              icon: const Icon(Icons.phone_in_talk,
                  color: Colors.white, size: 16),
              label: const Text(
                "Call to Book Package",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

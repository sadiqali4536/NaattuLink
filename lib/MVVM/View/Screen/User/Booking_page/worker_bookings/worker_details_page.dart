import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerDetailsPage extends StatelessWidget {
  final String category;
  final String serviceName;
  final double rating;
  final dynamic originalPrice;
  final dynamic discount;
  final String image;
  final dynamic discountPrice;
  final String? serviceType;
  final double? businessLat;
  final double? businessLng;
  final String? businessAddress;
  final String? businessMapsUrl;

  const WorkerDetailsPage({
    Key? key,
    required this.category,
    required this.serviceName,
    required this.rating,
    required this.originalPrice,
    required this.discount,
    required this.image,
    required this.discountPrice,
    this.serviceType,
    this.businessLat,
    this.businessLng,
    this.businessAddress,
    this.businessMapsUrl,
  }) : super(key: key);

  /// Launch Google Maps navigation to the worker's saved coordinates.
  Future<void> _openMaps(BuildContext context) async {
    String? url = businessMapsUrl;
    if ((url == null || url.isEmpty) &&
        businessLat != null &&
        businessLng != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=$businessLat,$businessLng';
    }
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps.'),
            backgroundColor: Color(0xFF0F2E5A),
          ),
        );
      }
    }
  }

  String _getWorkerDescription() {
    final name = serviceName.toLowerCase();
    if (name.contains('electrician')) {
      return "Expert electrical repairs, wiring, and installation by certified local professionals. Available for emergency call-outs across Thalayadukkar.";
    } else if (name.contains('plumber')) {
      return "Professional plumbing services including leak repairs, pipe installations, drainage cleaning, and sanitary fittings by experienced plumbers.";
    } else if (name.contains('carpenter')) {
      return "Custom woodwork, furniture repairs, door lock installations, and cabinet work by skilled local carpenters.";
    } else if (name.contains('painter')) {
      return "Interior and exterior wall painting, touch-ups, wall putty application, and decorative finishes with premium quality paints.";
    } else {
      return "Expert and reliable $serviceName services provided by certified local professionals. Committed to delivering high-quality workmanship and timely completion.";
    }
  }

  String _getWorkerImage() {
    if (image.isNotEmpty && image.startsWith('http')) {
      return image;
    }
    final name = serviceName.toLowerCase();
    if (name.contains('electrician')) {
      return "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80";
    } else if (name.contains('plumber')) {
      return "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?auto=format&fit=crop&w=800&q=80";
    } else if (name.contains('carpenter')) {
      return "https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=800&q=80";
    } else if (name.contains('painter')) {
      return "https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=800&q=80";
    } else {
      return "https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=800&q=80";
    }
  }

  List<Map<String, dynamic>> _getMockReviews() {
    final name = serviceName.toLowerCase();
    if (name.contains('electrician')) {
      return [
        {
          "initials": "SA",
          "name": "Sadiq Ali",
          "rating": 5,
          "comment":
              "Punctual and very professional. Fixed my main distribution board issues quickly. Highly recommended for Thalayadukkar residents."
        },
        {
          "initials": "LM",
          "name": "Lakshmi Menon",
          "rating": 5,
          "comment":
              "Great service for installing our new inverter system. The pricing was exactly as mentioned."
        }
      ];
    } else if (name.contains('plumber')) {
      return [
        {
          "initials": "AK",
          "name": "Arun Kumar",
          "rating": 5,
          "comment":
              "Fixed my kitchen sink leakage within 15 minutes. Very polite and prompt service."
        },
        {
          "initials": "SN",
          "name": "Saritha Nair",
          "rating": 5,
          "comment":
              "Excellent work installing the water pump. Highly recommended."
        }
      ];
    } else {
      return [
        {
          "initials": "SA",
          "name": "Sadiq Ali",
          "rating": 5,
          "comment":
              "Very neat work and professional attitude. Punctual and cleaned up afterwards."
        },
        {
          "initials": "LM",
          "name": "Lakshmi Menon",
          "rating": 5,
          "comment":
              "Transparent rates and high-quality service. Extremely satisfied."
        }
      ];
    }
  }

  List<Map<String, dynamic>> _getRelatedBookings() {
    final name = serviceName.toLowerCase();
    final allRelated = [
      {
        "name": "Expert Plumber",
        "price": 199,
        "image":
            "https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?auto=format&fit=crop&w=300&q=80"
      },
      {
        "name": "Skilled Carpenter",
        "price": 249,
        "image":
            "https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&w=300&q=80"
      },
      {
        "name": "Wall Painter",
        "price": 499,
        "image":
            "https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&w=300&q=80"
      },
      {
        "name": "Master Electrician",
        "price": 299,
        "image":
            "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=300&q=80"
      }
    ];

    return allRelated
        .where((element) =>
            !(element['name'] as String).toLowerCase().contains(name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0F2E5A);
    final themeGreen = const Color(0xFF059669);
    final bgLight = const Color(0xFFF8FAFC);
    final textGrey = const Color(0xFF64748B);

    final reviews = _getMockReviews();
    final related = _getRelatedBookings();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background/Header image and Scroll view
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Worker Image Header with Gradient
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        foregroundDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.white.withOpacity(0.9),
                              Colors.white,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 0.9, 1.0],
                          ),
                        ),
                        child: Image.network(
                          _getWorkerImage(),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: bgLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0F2E5A)),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: bgLight,
                            child: Icon(Icons.handyman_outlined,
                                size: 80, color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Floating Card Details Overlaid by Padding
                  Transform.translate(
                    offset: const Offset(0, -60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Floating worker info card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                              ],
                              border: Border.all(
                                  color: const Color(0xFFF1F5F9), width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        serviceName,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.check_circle,
                                              color: Color(0xFF059669),
                                              size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            "Verified",
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Color(0xFFFFB800), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      " (124 Reviews)",
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getWorkerDescription(),
                                  style: TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                                // ── View Location Button ─────────────
                                if (businessLat != null ||
                                    (businessMapsUrl != null &&
                                        businessMapsUrl!.isNotEmpty)) ...[
                                  const SizedBox(height: 14),
                                  const Divider(
                                      color: Color(0xFFF1F5F9), height: 1),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () => _openMaps(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded,
                                              color: Color(0xFF0F2E5A),
                                              size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'View Location',
                                                  style: TextStyle(
                                                    color: Color(0xFF0F2E5A),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (businessAddress != null &&
                                                    businessAddress!.isNotEmpty)
                                                  Text(
                                                    businessAddress!,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF64748B),
                                                        fontSize: 11),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.open_in_new_rounded,
                                              color: Color(0xFF0F2E5A),
                                              size: 15),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Why Choose This Service Section
                          Text(
                            "Why Choose This Service",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            icon: Icons.verified_user,
                            title: "Background Checked",
                            subtitle: "Verified by local authorities",
                          ),
                          const SizedBox(height: 10),
                          _buildBenefitRow(
                            icon: Icons.payments_outlined,
                            title: "Transparent Pricing",
                            subtitle: "No hidden charges",
                          ),
                          const SizedBox(height: 10),
                          _buildBenefitRow(
                            icon: Icons.sentiment_satisfied_alt,
                            title: "Satisfaction Guaranteed",
                            subtitle: "Warranty on all works",
                          ),
                          const SizedBox(height: 24),

                          // Pricing Details Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_offer_outlined,
                                        color: primaryColor, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Pricing Details",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Divider(
                                      color: Color(0xFFDBEAFE), height: 1),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Fixed Service Charge",
                                      style: TextStyle(
                                        color: primaryColor.withOpacity(0.8),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "₹$discountPrice",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Customer Reviews Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Customer Reviews",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    color: themeGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final rev = reviews[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFF1F5F9)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              const Color(0xFF3B82F6)
                                                  .withOpacity(0.15),
                                          child: Text(
                                            rev['initials'],
                                            style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            rev['name'],
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (starIdx) => Icon(
                                              Icons.star,
                                              color: starIdx < rev['rating']
                                                  ? themeGreen
                                                  : Colors.grey[200],
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "\"${rev['comment']}\"",
                                      style: TextStyle(
                                        color: primaryColor.withOpacity(0.8),
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // People also booked Section
                          Text(
                            "People also booked",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 155,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: related.length,
                              itemBuilder: (context, index) {
                                final relItem = related[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WorkerDetailsPage(
                                          category: category,
                                          serviceName: relItem['name'],
                                          rating: 4.8,
                                          originalPrice: relItem['price'],
                                          discount: 0,
                                          image: relItem['image'],
                                          discountPrice: relItem['price'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFF1F5F9)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(16)),
                                          child: Image.network(
                                            relItem['image'],
                                            height: 90,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                relItem['name'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Starts ₹${relItem['price']}",
                                                style: TextStyle(
                                                  color: textGrey,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Floating Back Button & Actions overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: primaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(Icons.share, color: primaryColor, size: 20),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(Icons.favorite_border,
                        color: primaryColor, size: 20),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // Bottom sticky navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Starting from",
                          style: TextStyle(color: textGrey, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "₹$discountPrice/hr",
                          style: TextStyle(
                            color: themeGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("Booking request sent for $serviceName!"),
                            backgroundColor: primaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Book Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F2E5A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

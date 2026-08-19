import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:naattulink/MVVM/utils/Config/Toast.dart';
import 'healthcare_page.dart';

class HealthcareDoctorsPage extends StatefulWidget {
  final ClinicListing clinic;

  const HealthcareDoctorsPage({Key? key, required this.clinic})
      : super(key: key);

  @override
  State<HealthcareDoctorsPage> createState() => _HealthcareDoctorsPageState();
}

class _HealthcareDoctorsPageState extends State<HealthcareDoctorsPage> {
  final primaryColor = const Color(0xFF0F2E5A);
  final textGrey = const Color(0xFF64748B);
  final bgLight = const Color(0xFFF8FAFC);
  final goldColor = const Color(0xFFFFB800);

  bool _isLoading = true;

  // Consultations state
  List<Map<String, dynamic>> _consultations = [];
  List<Map<String, dynamic>> _filteredConsultations = [];

  // Selection state
  Map<String, dynamic>? _selectedConsultation;

  // Doctors state
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];

  final Set<String> _expandedPoints = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConsultations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (_selectedConsultation == null) {
      // Searching consultations
      setState(() {
        if (query.isEmpty) {
          _filteredConsultations = List.from(_consultations);
        } else {
          _filteredConsultations = _consultations.where((c) {
            final title = (c['title'] ?? '').toString().toLowerCase();
            return title.contains(query);
          }).toList();
        }
      });
    } else {
      // Searching doctors
      setState(() {
        if (query.isEmpty) {
          _filteredDoctors = List.from(_doctors);
        } else {
          _filteredDoctors = _doctors.where((d) {
            final name = (d['name'] ?? '').toString().toLowerCase();
            final spec = (d['SPECIALIZATION'] ?? '').toString().toLowerCase();
            return name.contains(query) || spec.contains(query);
          }).toList();
        }
      });
    }
  }

  Future<void> _fetchConsultations() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('healthcare')
          .doc(widget.clinic.uid)
          .collection('consultations')
          .where('status', isEqualTo: 'scheduled')
          .get();

      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('healthcare')
          .doc(widget.clinic.uid)
          .collection('doctors')
          .where('status', isEqualTo: 'active')
          .get();

      final Map<String, int> doctorCounts = {};
      for (var doc in doctorsSnapshot.docs) {
        final cid = doc.data()['consultationId'];
        if (cid != null) {
          doctorCounts[cid.toString()] =
              (doctorCounts[cid.toString()] ?? 0) + 1;
        }
      }

      final list = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        data['doctor_count'] = doctorCounts[doc.id] ?? 0;
        return data;
      }).toList();

      setState(() {
        _consultations = list;
        _filteredConsultations = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      toastError("Failed to fetch consultations");
    }
  }

  Future<void> _fetchDoctors(Map<String, dynamic> consultation) async {
    setState(() {
      _selectedConsultation = consultation;
      _isLoading = true;
      _searchController.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('healthcare')
          .doc(widget.clinic.uid)
          .collection('doctors')
          .where('status', isEqualTo: 'active')
          .where('consultationId', isEqualTo: consultation['id'])
          .get();

      final list = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _doctors = list;
        _filteredDoctors = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedConsultation = null;
      });
      toastError("Failed to fetch doctors");
    }
  }

  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    final String urlString =
        phoneNumber.startsWith('tel:') ? phoneNumber : 'tel:$phoneNumber';
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url)) {
        toastError("Could not launch dialer.");
      }
    } catch (e) {
      toastError("Could not start call.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: _selectedConsultation != null
              ? AppBackButton(
                  onPressed: () {
                    setState(() {
                      _selectedConsultation = null;
                      _searchController.clear();
                      _onSearchChanged(); // reset to consultations
                    });
                  },
                )
              : const AppBackButton(),
        ),
        title: Text(
          _selectedConsultation == null
              ? (widget.clinic.profession.toLowerCase() == 'laboratory'
                  ? "Available Tests"
                  : "Consultations")
              : "Available Doctors",
          style: const TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _selectedConsultation == null
                    ? (widget.clinic.profession.toLowerCase() == 'laboratory'
                        ? "Search tests..."
                        : "Search consultations...")
                    : "Search doctors or specialization...",
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF0F2E5A), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedConsultation == null
                    ? _buildConsultationsList()
                    : _buildDoctorsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    if (_filteredConsultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              widget.clinic.speciality.toLowerCase() == 'laboratory'
                  ? "No tests found."
                  : "No consultations found.",
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredConsultations.length,
      itemBuilder: (context, index) {
        final isLab = widget.clinic.profession.toLowerCase() == 'laboratory';
        final cons = _filteredConsultations[index];
        final title =
            cons['title'] ?? (isLab ? 'Unknown Test' : 'Unknown Consultation');
        final mobile = cons['mobile'] ?? 'No contact';
        final doctorCount = cons['doctor_count'] ?? 0;
        final category = cons['category']?.toString() ?? '';
        final price = cons['price']?.toString() ?? '';
        final status = cons['status']?.toString().toUpperCase() ?? '';

        List<dynamic> pointsList = [];
        if (cons['points'] != null && cons['points'] is List) {
          pointsList = cons['points'] as List;
        }

        return GestureDetector(
          onTap: isLab ? null : () => _fetchDoctors(cons),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                        isLab
                            ? Icons.science_outlined
                            : Icons.assignment_ind_outlined,
                        color: const Color(0xFF4F46E5),
                        size: 26),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (price.isNotEmpty)
                            Text(
                              "₹$price",
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          if (['hospital', 'clinic']
                              .contains(widget.clinic.profession.toLowerCase()))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.medical_services_outlined,
                                    color: Color(0xFF059669),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$doctorCount Available Doctor${doctorCount == 1 ? '' : 's'}",
                                    style: const TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (pointsList.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (_expandedPoints.contains(cons['id'])) {
                                _expandedPoints.remove(cons['id']);
                              } else {
                                _expandedPoints.add(cons['id']);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Text(
                                  "Includes:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2E5A),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _expandedPoints.contains(cons['id'])
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF0F2E5A),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_expandedPoints.contains(cons['id']))
                          ...pointsList.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 4, right: 8),
                                      child: Icon(Icons.circle,
                                          size: 6,
                                          color: primaryColor.withOpacity(0.5)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        point.toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: textGrey,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ],
                  ),
                ),
                if (!isLab)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, top: 16),
                    child: Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorsList() {
    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "No doctors available right now.",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        final doc = _filteredDoctors[index];
        final name = doc['name'] ?? 'Unknown Doctor';
        final spec = doc['SPECIALIZATION'] ?? 'General';
        final mobile = doc['mobile'] ?? widget.clinic.phone;
        final fees = doc['fees'] ?? 'N/A';
        final startTime = doc['start_time'] ?? '';
        final endTime = doc['end_time'] ?? '';
        final timing = (startTime.isNotEmpty && endTime.isNotEmpty)
            ? "$startTime - $endTime"
            : "No specific timing";

        List<dynamic> daysList = doc['days'] ?? [];
        String daysStr = daysList.join(", ");
        if (daysStr.isEmpty) daysStr = "Available days not specified";

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline,
                        color: Color(0xFF4F46E5),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            spec,
                            style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.local_hospital_outlined,
                                color: textGrey, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.clinic.facilityName,
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.currency_rupee,
                                color: Color(0xFF64748B), size: 14),
                            Text(
                              fees,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Color(0xFFF1F5F9), height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: textGrey, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      daysStr,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, color: textGrey, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timing,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _makeCall(context, mobile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Book Appointment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

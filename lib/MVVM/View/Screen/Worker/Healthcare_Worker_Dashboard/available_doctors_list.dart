import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/controller/healthcare_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/add_new_doctor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailableDoctorsList extends StatefulWidget {
  final String consultationId;
  const AvailableDoctorsList({super.key, required this.consultationId});

  @override
  State<AvailableDoctorsList> createState() => _AvailableDoctorsListState();
}

class _AvailableDoctorsListState extends State<AvailableDoctorsList> {
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () {
            if (isSearching) {
              setState(() {
                isSearching = false;
                searchQuery = '';
                searchController.clear();
              });
            } else {
              Get.back();
            }
          },
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search name, phone, spec...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                "Available Doctors List",
                style: TextStyle(
                    color: Color(0xFF0A235C),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF0A235C),
            ),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  searchQuery = '';
                  searchController.clear();
                } else {
                  isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (uid != null)
            ? (widget.consultationId.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('healthcare')
                    .doc(uid)
                    .collection('doctors')
                    .where('consultationId', isEqualTo: widget.consultationId)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('healthcare')
                    .doc(uid)
                    .collection('doctors')
                    .snapshots())
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A235C)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No doctors available. Add a new doctor.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var doctorsList = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          if (searchQuery.isNotEmpty) {
            doctorsList = doctorsList.where((doctor) {
              final name = (doctor['name'] ?? '').toString().toLowerCase();
              final phone = (doctor['mobile'] ?? '').toString().toLowerCase();
              final qualification =
                  (doctor['SPECIALIZATION'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery) ||
                  phone.contains(searchQuery) ||
                  qualification.contains(searchQuery);
            }).toList();
          }

          if (doctorsList.isEmpty) {
            return const Center(
              child: Text(
                "No doctors match your search.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: doctorsList.length,
            itemBuilder: (context, index) {
              final doctor = doctorsList[index];
              return _buildDoctorCard(context, doctor);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(
            () => AddNewDoctorPage(consultationId: widget.consultationId)),
        backgroundColor: const Color(0xFF0A235C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  bool _isSpecificDateValid(Map<String, dynamic>? specificDate) {
    if (specificDate == null) return false;
    try {
      final dateStr = specificDate['date'];
      final endTimeStr = specificDate['end'];
      if (dateStr == null || endTimeStr == null) return false;

      final date = DateTime.parse(dateStr);
      final format = DateFormat("h:mm a");
      final time = format.parse(endTimeStr);

      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      return endDateTime.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _getDaysDisplay(List<dynamic>? days) {
    if (days == null || days.isEmpty) return 'No days set';
    if (days.length == 7) {
      return 'Daily';
    }
    return days.join(' • ');
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    final name = doctor['name'] ?? 'Unknown Doctor';
    String initials = '?';
    if (name.isNotEmpty) {
      List<String> nameParts = name.trim().split(RegExp(r'\s+'));
      if (nameParts.length > 1) {
        if (nameParts[0].toLowerCase().replaceAll('.', '') == 'dr' &&
            nameParts.length >= 3) {
          initials =
              nameParts[1][0].toUpperCase() + nameParts[2][0].toUpperCase();
        } else {
          initials =
              nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
        }
      } else {
        initials = nameParts[0]
            .substring(0, nameParts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A235C),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF8BA5D6),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: doctor['status'] == 'inactive'
                                ? Colors.grey
                                : const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doctor['status'] == 'inactive'
                                ? 'NOT AVAILABLE'
                                : 'AVAILABLE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['SPECIALIZATION'] ?? 'General Physician',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'edit') {
                    Get.to(() => AddNewDoctorPage(
                          consultationId: widget.consultationId,
                          editDocId: doctor['id'],
                          editData: doctor,
                        ));
                  } else if (value == 'status') {
                    final newStatus = (doctor['status'] == 'inactive')
                        ? 'active'
                        : 'inactive';
                    HealthcareDashboardController.to.updateDoctorStatus(
                        widget.consultationId, doctor['id'], newStatus);
                  } else if (value == 'delete') {
                    _showDeleteDoctorDialog(context, doctor['id']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit_outlined,
                            size: 20, color: Color(0xFF0F172A)),
                        SizedBox(width: 12),
                        Text("Edit Details",
                            style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                            doctor['status'] == 'inactive'
                                ? Icons.check_circle_outline
                                : Icons.block,
                            size: 20,
                            color: const Color(0xFF0F172A)),
                        const SizedBox(width: 12),
                        Text(
                            doctor['status'] == 'inactive'
                                ? "Mark Available"
                                : "Mark Not Available",
                            style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text("Delete",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 1),
          const SizedBox(height: 16),
          if (doctor['specific_date'] != null &&
              _isSpecificDateValid(doctor['specific_date']))
            _buildDetailRow(
              Icons.event_available_outlined,
              "${doctor['specific_date']['date'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(doctor['specific_date']['date'])) : ''}  •  ${doctor['specific_date']['start']} - ${doctor['specific_date']['end']}",
            )
          else ...[
            _buildDetailRow(Icons.access_time_outlined,
                "${doctor['start_time'] ?? '--:--'} - ${doctor['end_time'] ?? '--:--'}"),
            _buildDetailRow(Icons.calendar_today_outlined,
                _getDaysDisplay(doctor['days'] as List<dynamic>?)),
          ],
          _buildDetailRow(
              Icons.payments_outlined, "₹${doctor['fees'] ?? '0.00'}"),
          //const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_in_talk_outlined,
                      size: 20, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['mobile'] ?? '',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Booking Number',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final phone = doctor['mobile'] ?? '';
                  if (phone.isNotEmpty) {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: phone,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  }
                },
                icon: const Icon(Icons.phone_in_talk_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  "Book",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A235C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F172A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDoctorDialog(BuildContext context, String doctorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Doctor?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this doctor?\nThis action cannot be undone.",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              HealthcareDashboardController.to
                  .deleteDoctor(widget.consultationId, doctorId);
            },
            child: const Text("Delete",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

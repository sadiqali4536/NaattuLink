import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/controller/healthcare_dashboard_controller.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/new_consultation.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Healthcare_Worker_Dashboard/available_doctors_list.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';

class HealthcareWorkerHomepage extends StatelessWidget {
  const HealthcareWorkerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HealthcareDashboardController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A235C)));
        }

        final user = controller.userData;
        final facilityName = user['facility_name'] ?? 'Healthcare Provider';
        final totalDoctors = controller.doctors.length;
        final availableDoctors =
            controller.doctors.where((d) => d['status'] != 'inactive').length;
        final scheduledConsultations = controller.consultations
            .where((c) =>
                (c['status']?.toString().toLowerCase() ?? 'scheduled') ==
                'scheduled')
            .length;
        final earnings = user['earnings']?.toString();
        final isKeyboardOpen = controller.isSearchFocused.value;

        final profileImage = user['profile_image'] ?? '';

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                  isKeyboardOpen,
                  facilityName,
                  profileImage,
                  totalDoctors,
                  availableDoctors,
                  earnings,
                  scheduledConsultations,
                  controller.consultations.length,
                  user['profession']?.toString().toLowerCase() == 'laboratory'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            // Active Consultations List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final consultation =
                        controller.filteredConsultations[index];
                    return _buildConsultationCard(context, consultation);
                  },
                  childCount: controller.filteredConsultations.length,
                ),
              ),
            ),
            if (controller.filteredConsultations.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      "No active consultations.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
                child: SizedBox(height: 120)), // Space for bottom panel
          ],
        );
      }),
    );
  }

  Widget _buildHeader(
      bool isKeyboardOpen,
      String facilityName,
      String profileImage,
      int totalDoctors,
      int availableDoctors,
      String? earnings,
      int scheduledConsultations,
      int totalTests,
      bool isLaboratory) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, isKeyboardOpen ? 40 : 50, 20, isKeyboardOpen ? 15 : 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0A235C), // Dark blue from mockup
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 3),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.local_hospital,
                          color: Color(0xFF0A235C))
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome back,",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      facilityName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.store, color: Colors.white),
                onPressed: () {
                  Get.to(() => const user_Dashboard());
                },
              ),
            ],
          ),
          SizedBox(height: isKeyboardOpen ? 12 : 24),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: HealthcareDashboardController.to.searchController,
              focusNode: HealthcareDashboardController.to.searchFocusNode,
              onChanged: (value) =>
                  HealthcareDashboardController.to.searchQuery.value = value,
              style: const TextStyle(
                decoration: TextDecoration.none,
                decorationThickness: 0,
              ),
              decoration: InputDecoration(
                hintText: "Search consultation or number...",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: isKeyboardOpen ? 13 : 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: isKeyboardOpen ? 21 : 24,
                ),
                suffixIcon: Obx(() {
                  if (HealthcareDashboardController
                      .to.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        HealthcareDashboardController.to.searchController
                            .clear();
                        HealthcareDashboardController.to.searchQuery.value = '';
                      },
                    );
                  }
                  return Icon(Icons.filter_list, color: Colors.grey[400]);
                }),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isKeyboardOpen ? 11 : 15,
                ),
              ),
            ),
          ),
          if (!isKeyboardOpen) ...[
            const SizedBox(height: 24),
            // Stats Row
            if (isLaboratory) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.category_outlined,
                      value: "Laboratory",
                      label: "CATEGORY",
                      isYellow: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.biotech,
                      value: totalTests.toString(),
                      label: "TOTAL TESTS",
                      isYellow: true,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.medical_services_outlined,
                      value: totalDoctors.toString(),
                      label: "TOTAL DOCTORS",
                      isYellow: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.person_outline_rounded,
                      value: availableDoctors.toString(),
                      label: "AVAILABLE DOCTORS",
                      isYellow: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.event_available,
                      value: scheduledConsultations.toString(),
                      label: "SCHEDULED",
                      isYellow: false,
                    ),
                  ),
                  if (earnings != null &&
                      earnings.isNotEmpty &&
                      earnings != '0') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.currency_rupee,
                        value: earnings,
                        label: "EARNINGS",
                        isYellow: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String value,
      required String label,
      required bool isYellow}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color:
            isYellow ? const Color(0xFFEAB308) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isYellow ? const Color(0xFF0A235C) : Colors.white,
              size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isYellow ? const Color(0xFF0A235C) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isYellow
                  ? const Color(0xFF0A235C).withOpacity(0.7)
                  : Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(
      BuildContext context, Map<String, dynamic> consultation) {
    final status = consultation['status']?.toString().toLowerCase() ?? '';
    final isScheduled = status == 'scheduled';

    final user = HealthcareDashboardController.to.userData;
    final profession = user['profession']?.toString().toLowerCase() ?? '';
    final isLaboratory = profession == 'laboratory';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  consultation['title'] ?? 'Unknown Consultation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isScheduled ? const Color(0xFF22C55E) : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isScheduled ? "SCHEDULED" : "UNSCHEDULED",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: Colors.white,
                onSelected: (value) {
                  if (value == 'status') {
                    final newStatus = isScheduled ? 'unscheduled' : 'scheduled';
                    HealthcareDashboardController.to.updateConsultationStatus(
                        consultation['id'], newStatus);
                  } else if (value == 'edit') {
                    Get.to(() => NewConsultationPage(
                          editDocId: consultation['id'],
                          editData: consultation,
                        ));
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, consultation['id']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                            isScheduled
                                ? Icons.event_busy
                                : Icons.event_available,
                            size: 20,
                            color: const Color(0xFF0F172A)),
                        const SizedBox(width: 12),
                        Text(
                            isScheduled ? "Mark Unscheduled" : "Mark Scheduled",
                            style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit_outlined,
                            size: 20, color: Color(0xFF0A235C)),
                        SizedBox(width: 12),
                        Text("Edit",
                            style: TextStyle(
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
          if (isLaboratory) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  consultation['category'] ?? 'N/A',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.currency_rupee,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  consultation['price']?.toString() ?? 'N/A',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
            Builder(builder: (context) {
              final points = consultation['points'];
              final bool hasPoints = points != null &&
                  ((points is List && points.isNotEmpty) ||
                      (points is String && points.trim().isNotEmpty));
              if (!hasPoints) return const SizedBox();

              final pointsText = (points is List)
                  ? points.map((e) => '• $e').join('\n')
                  : '• $points';
              return _ExpandableIncludes(pointsText: pointsText);
            }),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_in_talk_outlined,
                    size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  consultation['mobile'] ?? 'N/A',
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
            if (consultation['description'] != null &&
                consultation['description'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      consultation['description'],
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (!isLaboratory) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Get.to(() => AvailableDoctorsList(
                      consultationId: consultation['id'] ?? '',
                    )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A235C).withOpacity(0.05),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Available Doctors List",
                  style: TextStyle(
                    color: Color(0xFF0A235C),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String consultationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Consultation?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this consultation?\nThis action cannot be undone.",
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
                  .deleteConsultation(consultationId);
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

class _ExpandableIncludes extends StatefulWidget {
  final String pointsText;

  const _ExpandableIncludes({Key? key, required this.pointsText})
      : super(key: key);

  @override
  State<_ExpandableIncludes> createState() => _ExpandableIncludesState();
}

class _ExpandableIncludesState extends State<_ExpandableIncludes> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Includes",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: widget.pointsText,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              );
              final tp = TextPainter(
                text: span,
                maxLines: 2,
                textDirection: TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);

              final isOverflowing = tp.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pointsText,
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (isOverflowing || _isExpanded)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF0A235C),
                          size: 20,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

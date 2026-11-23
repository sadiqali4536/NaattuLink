import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:get/get.dart';
import 'package:naattulink/MVVM/controller/user/queue_controller.dart';
import 'package:naattulink/MVVM/utils/service_functions/auth_lookup_service.dart';

class BusinessQueueProfilePage extends StatelessWidget {
  final String businessDocId;
  final String businessPublicId;
  final String businessName;
  final String category;
  final String profession;
  final double rating;
  final String address;

  const BusinessQueueProfilePage({
    super.key,
    required this.businessDocId,
    required this.businessPublicId,
    required this.businessName,
    required this.category,
    required this.profession,
    required this.rating,
    required this.address,
  });

  Future<List<String>> _resolveUserIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final ids = <String>{};
    final storedPid = prefs.getString('publicId');
    if (storedPid != null && storedPid.isNotEmpty) {
      ids.add(storedPid);
    }
    ids.add(user.uid);

    try {
      final participant =
          await AuthLookupService.resolveUniversalParticipant(user.uid);
      if (participant != null) {
        if (participant.publicId.isNotEmpty) {
          ids.add(participant.publicId);
        }
        if (participant.documentId.isNotEmpty) {
          ids.add(participant.documentId);
        }
      }
    } catch (_) {}

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        ids.add(query.docs.first.id);
      }
    } catch (_) {}

    return ids.toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F2E5A);
    final queueController = Get.put(QueueController());
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          businessName.isNotEmpty ? businessName : 'Queue Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: businessDocId.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('businesses')
                .doc(businessDocId)
                .snapshots()
            : const Stream.empty(),
        builder: (context, bDocSnap) {
          final bData = (bDocSnap.data?.data() as Map<String, dynamic>?) ?? {};
          final name = bData['shopName'] ?? bData['name'] ?? businessName;
          final bannerImage = bData['shopImage'] ??
              bData['profileImage'] ??
              bData['imageUrl'] ??
              '';
          final displayAddress =
              (bData['address'] ?? address).toString().trim();
          final displayProf = (bData['profession'] ?? profession).toString();
          final double avgServiceMin =
              (bData['averageServiceTime'] ?? 15).toDouble();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Shop Profile Header Card
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop Avatar / Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 76,
                          height: 76,
                          color: const Color(0xFFF1F5F9),
                          child: bannerImage.isNotEmpty
                              ? Image.network(
                                  bannerImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.storefront_outlined,
                                      color: Color(0xFF0F3E7A),
                                      size: 34),
                                )
                              : const Icon(Icons.storefront_outlined,
                                  color: Color(0xFF0F3E7A), size: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFD97706), size: 15),
                                      const SizedBox(width: 3),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF10B981), size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Open Now',
                                        style: TextStyle(
                                          color: Color(0xFF047857),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (displayAddress.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Color(0xFF64748B), size: 15),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      displayAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Services & Estimated Time Pill Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0F3E7A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medical_services_outlined,
                              color: Color(0xFF0F3E7A), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayProf.isNotEmpty
                                    ? displayProf
                                    : 'Standard Service',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Walk-in & Queue service',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: Color(0xFF475569)),
                              const SizedBox(width: 4),
                              Text(
                                '~${avgServiceMin.toInt()} min',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Real-time Live Queue Status Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('businesses')
                        .doc(businessDocId)
                        .collection('queue_state')
                        .doc(todayStr)
                        .snapshots(),
                    builder: (context, queueStateSnapshot) {
                      if (queueStateSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !queueStateSnapshot.hasData) {
                        return Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0F2E5A),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }

                      int waiting = 0;
                      int currentToken = 0;
                      bool isOpen = true;

                      if (queueStateSnapshot.data != null &&
                          queueStateSnapshot.data!.exists) {
                        final data = queueStateSnapshot.data!.data()
                            as Map<String, dynamic>;
                        waiting = data['waitingCount'] ?? 0;
                        currentToken = data['currentToken'] ?? 0;
                        isOpen = data['isOpen'] ?? true;
                      }

                      return FutureBuilder<List<String>>(
                        future: _resolveUserIds(),
                        builder: (context, idsSnapshot) {
                          final userIds = idsSnapshot.data ?? [];

                          if (idsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildQueueCard(
                              context: context,
                              primaryColor: primaryColor,
                              queueController: queueController,
                              currentToken: currentToken,
                              waiting: waiting,
                              isOpen: isOpen,
                              activeTokenData: null,
                              isLoadingUserStatus: true,
                            );
                          }

                          if (userIds.isEmpty) {
                            return _buildQueueCard(
                              context: context,
                              primaryColor: primaryColor,
                              queueController: queueController,
                              currentToken: currentToken,
                              waiting: waiting,
                              isOpen: isOpen,
                              activeTokenData: null,
                              isLoadingUserStatus: false,
                            );
                          }

                          final streams = userIds.map((id) => FirebaseFirestore
                              .instance
                              .collection('users')
                              .doc(id)
                              .collection('active_queue')
                              .snapshots());

                          return StreamBuilder<List<QuerySnapshot>>(
                            stream: rx.Rx.combineLatestList(streams),
                            builder: (context, activeSnapshot) {
                              Map<String, dynamic>? activeTokenData;

                              if (activeSnapshot.hasData &&
                                  activeSnapshot.data != null) {
                                for (final querySnap in activeSnapshot.data!) {
                                  for (final doc in querySnap.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final status = data['status'] ?? '';
                                    final date = data['queueDate'] ?? '';
                                    final docBusinessPublicId =
                                        data['businessPublicId'] ??
                                            data['businessId'] ??
                                            '';

                                    final matchesBusiness = (doc.id ==
                                            businessPublicId ||
                                        doc.id == businessDocId ||
                                        docBusinessPublicId ==
                                            businessPublicId ||
                                        docBusinessPublicId == businessDocId);

                                    if (matchesBusiness &&
                                        ['waiting', 'called', 'in_service']
                                            .contains(status) &&
                                        date == todayStr) {
                                      activeTokenData = data;
                                      break;
                                    }
                                  }
                                  if (activeTokenData != null) break;
                                }
                              }

                              final bool isLoadingActive =
                                  activeSnapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      !activeSnapshot.hasData;

                              return _buildQueueCard(
                                context: context,
                                primaryColor: primaryColor,
                                queueController: queueController,
                                currentToken: currentToken,
                                waiting: waiting,
                                isOpen: isOpen,
                                activeTokenData: activeTokenData,
                                isLoadingUserStatus: isLoadingActive,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueueCard({
    required BuildContext context,
    required Color primaryColor,
    required QueueController queueController,
    required int currentToken,
    required int waiting,
    required bool isOpen,
    required Map<String, dynamic>? activeTokenData,
    bool isLoadingUserStatus = false,
  }) {
    final bool hasActiveToken = activeTokenData != null;
    final int userTokenNumber =
        hasActiveToken ? (activeTokenData['tokenNumber'] ?? 0) : 0;
    final String tokenStatus =
        hasActiveToken ? (activeTokenData['status'] ?? 'waiting') : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live queue header pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isOpen
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOpen ? 'LIVE QUEUE' : 'QUEUE CLOSED',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isOpen
                          ? const Color(0xFF047857)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_outlined,
                        size: 14, color: Color(0xFF475569)),
                    const SizedBox(width: 5),
                    Text(
                      '$waiting Waiting',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Split Box: [ Now Serving #X | Your Token #Y / Next ]
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: Row(
              children: [
                // Left side: Now Serving (mint bg)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFFDF5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Now Serving',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentToken > 0 ? '#$currentToken' : '--',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1.2,
                  height: 60,
                  color: const Color(0xFFE2E8F0),
                ),

                // Right side: Your Token or Queue Status (soft blue bg)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasActiveToken ? 'Your Token' : 'Next In Line',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasActiveToken
                              ? '#$userTokenNumber'
                              : (currentToken > 0
                                  ? '#${currentToken + waiting + 1}'
                                  : '#1'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button / State Banner
          if (isLoadingUserStatus)
            Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF0F2E5A),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Obx(() {
              final bool isTaking = queueController.isLoading.value;

              if (hasActiveToken) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              tokenStatus == 'called'
                                  ? 'You are called! (Token #$userTokenNumber)'
                                  : (tokenStatus == 'in_service'
                                      ? 'In Service (Token #$userTokenNumber)'
                                      : 'You are in Queue • Token #$userTokenNumber'),
                              style: const TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You cannot take another token until this queue is finished or completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                );
              }

              if (!isOpen) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Center(
                    child: Text(
                      'Queue is Currently Closed',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isTaking
                      ? null
                      : () {
                          queueController.takeToken(
                            context,
                            businessDocId: businessDocId,
                            businessPublicId: businessPublicId,
                            serviceName: profession,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isTaking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Take Token",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

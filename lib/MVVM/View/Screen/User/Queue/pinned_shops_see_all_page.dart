import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/User/Queue/business_queue_profile_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/services/service_details_page.dart';
import 'package:naattulink/MVVM/utils/service_functions/auth_lookup_service.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';

class PinnedShopsSeeAllPage extends StatelessWidget {
  const PinnedShopsSeeAllPage({super.key});

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
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pinned Shops',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<String>>(
        future: _resolveUserIds(),
        builder: (context, idsSnapshot) {
          if (idsSnapshot.connectionState == ConnectionState.waiting &&
              !idsSnapshot.hasData) {
            return _buildShimmerGrid();
          }

          final userIds = idsSnapshot.data ?? [];
          if (userIds.isEmpty) {
            return _buildEmptyState();
          }

          final streams = userIds.map((id) => FirebaseFirestore.instance
              .collection('users')
              .doc(id)
              .collection('pinnedShops')
              .snapshots());

          return StreamBuilder<List<QuerySnapshot>>(
            stream: Rx.combineLatestList(streams),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return _buildShimmerGrid();
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return _buildEmptyState();
              }

              final Map<String, QueryDocumentSnapshot> uniquePinned = {};
              for (final querySnap in snapshot.data!) {
                for (final doc in querySnap.docs) {
                  if (!uniquePinned.containsKey(doc.id)) {
                    uniquePinned[doc.id] = doc;
                  }
                }
              }

              if (uniquePinned.isEmpty) {
                return _buildEmptyState();
              }

              final pinnedDocs = uniquePinned.values.toList();
              pinnedDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>?)?['pinnedAt'];
                final bTime = (b.data() as Map<String, dynamic>?)?['pinnedAt'];
                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }
                return 0;
              });

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: pinnedDocs.length,
                itemBuilder: (context, index) {
                  final data =
                      pinnedDocs[index].data() as Map<String, dynamic>;
                  final businessName =
                      data['shopName'] ?? 'Pinned Business';
                  final category = data['category'] ?? '';
                  final profession = data['profession'] ?? '';
                  final address = data['address'] ?? '';
                  final businessDocId = data['shopId'] ?? '';
                  final businessPublicId = data['shopPublicId'] ?? '';
                  final shopImage = data['shopImage'] ?? '';

                  return StreamBuilder<DocumentSnapshot>(
                    stream: businessDocId.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(businessDocId)
                            .collection('queue_state')
                            .doc(todayDate)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, qsSnap) {
                      int queueCount = 0;
                      if (qsSnap.hasData && qsSnap.data!.exists) {
                        final qsData =
                            qsSnap.data!.data() as Map<String, dynamic>?;
                        queueCount = qsData?['waitingCount'] ??
                            qsData?['waitingLength'] ??
                            0;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                              color: const Color(0xFFF1F5F9), width: 1.2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              final type = data['type'] ?? 'business';
                              if (type == 'worker') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ServiceDetailsPage(
                                      category: category,
                                      serviceName: businessName,
                                      rating: 4.5,
                                      originalPrice: 0,
                                      discount: 0,
                                      image: shopImage,
                                      discountPrice: 0,
                                      providerId: businessPublicId,
                                      serviceId: businessDocId,
                                      businessAddress: address,
                                      serviceType: profession,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BusinessQueueProfilePage(
                                      businessDocId: businessDocId,
                                      businessPublicId: businessPublicId,
                                      businessName: businessName,
                                      category: category,
                                      profession: profession,
                                      rating: 4.6,
                                      address: address,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        child: Container(
                                          height: 105,
                                          width: double.infinity,
                                          color: const Color(0xFFF1F5F9),
                                          child: shopImage.isNotEmpty
                                              ? Image.network(
                                                  shopImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (context, error,
                                                              stackTrace) =>
                                                          const Icon(
                                                    Icons
                                                        .storefront_outlined,
                                                    color:
                                                        Color(0xFF0F3E7A),
                                                    size: 34,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.storefront_outlined,
                                                  color: Color(0xFF0F3E7A),
                                                  size: 34,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F3E7A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.push_pin,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Text(
                                    businessName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (profession.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      profession,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Q • $queueCount',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2E5A).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.push_pin_outlined,
                color: Color(0xFF0F2E5A), size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Pinned Shops Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pin your favorite shops to quickly access them here.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.76,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return ShimmerEffect(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}


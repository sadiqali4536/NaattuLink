import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/View/Screen/User/Queue/business_queue_profile_page.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/model/services/queue_repository.dart';
import 'package:naattulink/MVVM/utils/service_functions/auth_lookup_service.dart';

class GenericListingPage extends StatefulWidget {
  final String title;
  final String? profession;

  const GenericListingPage({Key? key, required this.title, this.profession})
      : super(key: key);

  @override
  State<GenericListingPage> createState() => _GenericListingPageState();
}

class _GenericListingPageState extends State<GenericListingPage> {
  final Set<String> _activeQueueBusinessIds = {};
  final Set<String> _processingQueueIds = {};
  final Set<String> _pinnedBusinessIds = {};
  final Set<String> _processingPinIds = {};
  final QueueRepository _queueRepository = QueueRepository();
  bool _isLoadingQueues = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<QuerySnapshot>? _businessesFuture;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchActiveQueues();
    if (widget.profession != null && widget.profession!.isNotEmpty) {
      _businessesFuture = FirebaseFirestore.instance
          .collection('businesses')
          .where('category', isEqualTo: 'Shops & Businesses')
          .where('profession', isEqualTo: widget.profession)
          .get();
    }
  }

  Future<void> _fetchActiveQueues() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingQueues = false);
        return;
      }

      final participant =
          await AuthLookupService.resolveUniversalParticipant(user.uid);
      if (participant == null) {
        if (mounted) setState(() => _isLoadingQueues = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(participant.collection)
          .doc(participant.documentId)
          .collection('active_queue')
          .get();

      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (mounted) {
        setState(() {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final status = data['status'] ?? '';
            final date = data['queueDate'] ?? '';
            if (['waiting', 'called', 'in_service'].contains(status) &&
                date == todayStr) {
              _activeQueueBusinessIds.add(doc.id);
            }
          }
        });
      }

      final pinnedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(participant.publicId)
          .collection('pinnedShops')
          .get();

      if (mounted) {
        setState(() {
          for (var doc in pinnedSnapshot.docs) {
            _pinnedBusinessIds.add(doc.id);
          }
          _isLoadingQueues = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQueues = false);
    }
  }

  Future<void> _handleTakeToken(
      String docId, String businessPublicId, String facilityName) async {
    if (businessPublicId.isEmpty) {
      CherryToast.error(
        title: const Text('Error', style: TextStyle(color: Colors.black)),
        description: const Text('Business ID missing'),
      ).show(context);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CherryToast.warning(
        title:
            const Text('Login Required', style: TextStyle(color: Colors.black)),
      ).show(context);
      return;
    }

    setState(() {
      _processingQueueIds.add(businessPublicId);
    });

    final prefs = await SharedPreferences.getInstance();

    // Resolve universal participant
    final participant =
        await AuthLookupService.resolveUniversalParticipant(user.uid);
    if (participant == null) {
      if (mounted) {
        setState(() {
          _processingQueueIds.remove(businessPublicId);
        });
        CherryToast.error(
          title: const Text('Error', style: TextStyle(color: Colors.black)),
          description: const Text('Could not verify your account identity.'),
        ).show(context);
      }
      return;
    }

    final result = await _queueRepository.assignTokenAtomically(
      businessDocId: docId,
      businessPublicId: businessPublicId,
      participant: participant,
    );

    if (mounted) {
      setState(() {
        _processingQueueIds.remove(businessPublicId);
        if (result['success'] || result['existing'] == true) {
          _activeQueueBusinessIds.add(businessPublicId);
        }
      });

      if (result['success']) {
        CherryToast.success(
          title: Text("Added to $facilityName queue",
              style: const TextStyle(color: Colors.black)),
        ).show(context);
      } else if (result['existing'] == true) {
        CherryToast.info(
          title: Text("Already in $facilityName queue",
              style: const TextStyle(color: Colors.black)),
        ).show(context);
      } else {
        CherryToast.error(
          title: Text(result['error'] ?? "Failed to join queue",
              style: const TextStyle(color: Colors.black)),
        ).show(context);
      }
    }
  }

  Future<void> _handlePinToggle(
      String businessPublicId, Map<String, dynamic> data) async {
    if (businessPublicId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CherryToast.warning(
        title:
            const Text('Login Required', style: TextStyle(color: Colors.black)),
      ).show(context);
      return;
    }

    setState(() {
      _processingPinIds.add(businessPublicId);
    });

    final prefs = await SharedPreferences.getInstance();
    String? publicId = prefs.getString('publicId');

    // Resolve participant/user document
    final candidateIds = <String>{};
    if (publicId != null && publicId.isNotEmpty) candidateIds.add(publicId);
    candidateIds.add(user.uid);
    try {
      final participant =
          await AuthLookupService.resolveUniversalParticipant(user.uid);
      if (participant != null) {
        if (participant.publicId.isNotEmpty) {
          candidateIds.add(participant.publicId);
          publicId = participant.publicId;
        }
        if (participant.documentId.isNotEmpty) {
          candidateIds.add(participant.documentId);
        }
      }
    } catch (_) {}

    if (publicId == null || publicId.isEmpty) {
      // Fallback: try to find user doc by authUid
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          publicId = query.docs.first.id;
          candidateIds.add(publicId);
          await prefs.setString('publicId', publicId);
        } else {
          publicId = user.uid;
        }
      } catch (e) {
        publicId = user.uid;
      }
    }

    final isPinned = _pinnedBusinessIds.contains(businessPublicId);

    try {
      // Sync across candidate IDs so both publicId and authUid have identical pin state
      for (final pid in candidateIds) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(pid)
            .collection('pinnedShops')
            .doc(businessPublicId);

        if (isPinned) {
          await ref.delete();
        } else {
          await ref.set({
            'shopId': data['authUid'] ?? '',
            'shopPublicId': businessPublicId,
            'shopName': data['facility_name'] ?? data['username'] ?? 'Unknown',
            'category': data['category'] ?? '',
            'profession': data['profession'] ?? '',
            'shopImage': data['profile_img'] ?? '',
            'address': data['address'] ?? '',
            'pinnedAt': FieldValue.serverTimestamp(),
            'type': 'business',
          });
        }
      }

      if (mounted) {
        setState(() {
          if (isPinned) {
            _pinnedBusinessIds.remove(businessPublicId);
          } else {
            _pinnedBusinessIds.add(businessPublicId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Failed to pin/unpin',
              style: TextStyle(color: Colors.black)),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingPinIds.remove(businessPublicId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumAppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: (widget.profession == null || widget.profession!.isEmpty)
          ? Center(
              child: Text(
                "${widget.title} Listings coming soon...",
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
            )
          : FutureBuilder<QuerySnapshot>(
              future: _businessesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading data',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No ${widget.title} found.",
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 16),
                    ),
                  );
                }

                final allBusinesses = snapshot.data!.docs;
                final query = _searchQuery.trim().toLowerCase();
                final businesses = query.isEmpty
                    ? allBusinesses
                    : allBusinesses.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final facilityName =
                            (data['facility_name'] ?? data['username'] ?? '')
                                .toString()
                                .toLowerCase();
                        final address =
                            (data['address'] ?? '').toString().toLowerCase();
                        final contact =
                            (data['contact_number'] ?? data['phone'] ?? '')
                                .toString()
                                .toLowerCase();
                        return facilityName.contains(query) ||
                            address.contains(query) ||
                            contact.contains(query);
                      }).toList();

                return Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F2E5A)
                                  .withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.title}...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF0F2E5A), size: 22),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Color(0xFF94A3B8), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    // Results List
                    Expanded(
                      child: businesses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F2E5A)
                                          .withValues(alpha: 0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.search_off_rounded,
                                        color: Color(0xFF0F2E5A), size: 36),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No results for "$_searchQuery"',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              itemCount: businesses.length,
                              itemBuilder: (context, index) {
                                final doc = businesses[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final facilityName = data['facility_name'] ??
                                    data['username'] ??
                                    'Unknown Business';
                                final address =
                                    data['address'] ?? 'No address provided';
                                final contact = data['contact_number'] ??
                                    data['phone'] ??
                                    '';
                                final time = data['available_time'] ?? '';

                                final iconCode = data['category_icon'] as int?;
                                final IconData displayIcon = iconCode != null
                                    ? IconData(iconCode,
                                        fontFamily: 'MaterialIcons')
                                    : Icons.storefront_outlined;

                                final businessPublicId =
                                    data['businessPublicId']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? data['businessPublicId']
                                        : doc.id;
                                final isAdded = _activeQueueBusinessIds
                                    .contains(businessPublicId);
                                final isProcessing = _processingQueueIds
                                    .contains(businessPublicId);
                                final isPinned = _pinnedBusinessIds
                                    .contains(businessPublicId);
                                final isPinProcessing = _processingPinIds
                                    .contains(businessPublicId);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: const Color(0xFFF1F5F9),
                                        width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F2E5A)
                                                    .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Icon(displayIcon,
                                                  color:
                                                      const Color(0xFF0F2E5A),
                                                  size: 28),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    facilityName,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0F2E5A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (time.isNotEmpty)
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.access_time,
                                                            size: 14,
                                                            color:
                                                                Colors.green),
                                                        const SizedBox(
                                                            width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            time,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: isPinProcessing
                                                  ? null
                                                  : () => _handlePinToggle(
                                                      businessPublicId, data),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isPinned
                                                      ? const Color(0xFF0F2E5A)
                                                          .withOpacity(0.1)
                                                      : Colors.grey
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: isPinned
                                                          ? const Color(
                                                              0xFF0F2E5A)
                                                          : Colors.transparent),
                                                ),
                                                child: isPinProcessing
                                                    ? const SizedBox(
                                                        height: 16,
                                                        width: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2))
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            isPinned
                                                                ? '📌 Unpin'
                                                                : '📌 Pin',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isPinned
                                                                  ? const Color(
                                                                      0xFF0F2E5A)
                                                                  : Colors.grey[
                                                                      700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(
                                            height: 1,
                                            color: Color(0xFFE2E8F0)),
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                                Icons.location_on_outlined,
                                                size: 18,
                                                color: Color(0xFF64748B)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                address,
                                                style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 13,
                                                    height: 1.3),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (contact.isNotEmpty)
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined,
                                                  size: 18,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 8),
                                              Text(
                                                contact,
                                                style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        if (data['queueEnabled'] == true ||
                                            isAdded) ...[
                                          const SizedBox(height: 16),
                                          StreamBuilder<DocumentSnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('businesses')
                                                .doc(doc.id)
                                                .collection('queue_state')
                                                .doc(
                                                    "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}")
                                                .snapshots(),
                                            builder:
                                                (context, queueStateSnapshot) {
                                              final stateData =
                                                  queueStateSnapshot.data
                                                              ?.data()
                                                          as Map<String,
                                                              dynamic>? ??
                                                      {};
                                              final isOpen =
                                                  stateData['isOpen'] == true;
                                              final status =
                                                  stateData['status'] ??
                                                      (isOpen
                                                          ? 'open'
                                                          : 'closed');
                                              final isQueueOpen =
                                                  status == 'open';

                                              if (!isQueueOpen && !isAdded) {
                                                return Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: Colors.red
                                                            .withOpacity(0.3)),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Queue is Currently Closed',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              return SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: isProcessing
                                                      ? null
                                                      : () {
                                                          if (!isAdded) {
                                                            _handleTakeToken(
                                                                doc.id,
                                                                businessPublicId,
                                                                facilityName);
                                                          } else {
                                                            Navigator
                                                                .pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const user_Dashboard(
                                                                  initialIndex:
                                                                      0,
                                                                  initialHomeCategoryIndex:
                                                                      3,
                                                                ),
                                                              ),
                                                              (route) => false,
                                                            );
                                                          }
                                                        },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF0F2E5A),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 0,
                                                  ),
                                                  child: isProcessing
                                                      ? const SizedBox(
                                                          height: 18,
                                                          width: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2))
                                                      : Text(
                                                          isAdded
                                                              ? 'Visit'
                                                              : 'Take Token',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    ));
  }
}

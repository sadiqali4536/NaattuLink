import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Screen/User/Queue/business_queue_profile_page.dart';

class ActiveTokenCard extends StatefulWidget {
  const ActiveTokenCard({Key? key}) : super(key: key);

  @override
  State<ActiveTokenCard> createState() => _ActiveTokenCardState();
}

class _ActiveTokenCardState extends State<ActiveTokenCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userPublicId;

  @override
  void initState() {
    super.initState();
    _loadUserPublicId();
  }

  Future<void> _loadUserPublicId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userPublicId = prefs.getString('publicId');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userPublicId == null) return const SizedBox.shrink();

    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_userPublicId)
          .collection('active_queue')
          .where('status',
              whereIn: ['waiting', 'called', 'in_service', 'now_serving'])
          .where('queueDate', isEqualTo: todayDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeDoc = snapshot.data!.docs.first;
        final data = activeDoc.data() as Map<String, dynamic>;

        final businessName = data['businessName'] ?? 'Business';
        final tokenNumber = data['tokenNumber'] ?? 0;
        final estimatedWait = data['estimatedWaitMinutes'] ?? 0;
        final status = data['status'] ?? 'waiting';
        final businessDocId = data['businessId'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            color: const Color(0xFF0F2E5A),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "YOUR ACTIVE TOKEN",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'called'
                              ? Colors.orange
                              : (status == 'in_service' ||
                                      status == 'now_serving'
                                  ? Colors.blue
                                  : Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          businessName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "#$tokenNumber",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Live tracking using queue_state
                  if (businessDocId.isNotEmpty)
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('businesses')
                          .doc(businessDocId)
                          .collection('queue_state')
                          .doc('today')
                          .snapshots(),
                      builder: (context, qsSnapshot) {
                        if (!qsSnapshot.hasData || !qsSnapshot.data!.exists)
                          return const SizedBox.shrink();

                        final qsData =
                            qsSnapshot.data!.data() as Map<String, dynamic>;
                        final currentServing = qsData['currentToken'] ?? 0;
                        final peopleAhead =
                            (tokenNumber - currentServing - 1).clamp(0, 9999);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_outline,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    status == 'called'
                                        ? "It's your turn!"
                                        : (status == 'now_serving' || status == 'in_service'
                                            ? "You are currently being served"
                                            : (peopleAhead <= 0
                                                ? "You are next!"
                                                : "$peopleAhead people ahead")),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Now serving #$currentServing",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (businessDocId.isNotEmpty) {
                          try {
                            final doc = await _firestore
                                .collection('businesses')
                                .doc(businessDocId)
                                .get();
                            if (doc.exists && mounted) {
                              final bData = doc.data() as Map<String, dynamic>;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BusinessQueueProfilePage(
                                    businessDocId: businessDocId,
                                    businessPublicId: bData['publicId'] ?? '',
                                    businessName:
                                        bData['business_name'] ?? businessName,
                                    category: bData['category'] ?? '',
                                    profession: bData['profession'] ?? '',
                                    rating: (bData['rating'] ?? 5.0).toDouble(),
                                    address: bData['location'] ??
                                        bData['address'] ??
                                        '',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error fetching business: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F2E5A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("View Live Queue",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

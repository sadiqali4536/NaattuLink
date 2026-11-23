import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class BusinessQueueLivePage extends StatefulWidget {
  final String businessDocId;
  final String collection;

  const BusinessQueueLivePage({
    Key? key,
    required this.businessDocId,
    required this.collection,
  }) : super(key: key);

  @override
  State<BusinessQueueLivePage> createState() => _BusinessQueueLivePageState();
}

class _BusinessQueueLivePageState extends State<BusinessQueueLivePage> {
  String get todayId {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _updateQueueStatus(String newStatus) async {
    final stateRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue_state')
        .doc(todayId);

    await stateRef.set({
      'status': newStatus,
      'isOpen': newStatus == 'open',
    }, SetOptions(merge: true));
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  Future<void> _completeToken(String tokenId) async {
    final tokenRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue')
        .doc(tokenId);

    final stateRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue_state')
        .doc(todayId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final tokenDoc = await transaction.get(tokenRef);
      if (!tokenDoc.exists) return;

      transaction.update(tokenRef, {'status': 'completed'});
      transaction.update(stateRef, {'completedCount': FieldValue.increment(1)});

      final data = tokenDoc.data() as Map<String, dynamic>;
      final pCollection = data['participantCollection'] ?? 'users';
      final pDocId = data['participantDocumentId'] ??
          data['userPublicId'] ??
          data['userId'];
      if (pDocId != null && pDocId.toString().isNotEmpty) {
        final String? bPubId = data['businessPublicId'];
        if (bPubId != null && bPubId.isNotEmpty) {
          final activeQueueRef = FirebaseFirestore.instance
              .collection(pCollection)
              .doc(pDocId)
              .collection('active_queue')
              .doc(bPubId);
          transaction.update(activeQueueRef, {
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp()
          });
        }
      }
    });
  }

  Future<void> _cancelToken(String tokenId, String nextWaitingId) async {
    final tokenRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue')
        .doc(tokenId);

    final stateRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue_state')
        .doc(todayId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final tokenDoc = await transaction.get(tokenRef);
      if (!tokenDoc.exists) return;

      final data = tokenDoc.data() as Map<String, dynamic>;
      final currentStatus = data['status'];

      transaction.update(tokenRef, {'status': 'cancelled'});
      if (currentStatus == 'waiting') {
        transaction
            .update(stateRef, {'waitingCount': FieldValue.increment(-1)});
      } else if (currentStatus == 'now_serving') {
        transaction.update(stateRef, {'currentServingNumber': 0});
      }

      // Update universal participant active_queue
      final pCollection = data['participantCollection'] ?? 'users';
      final pDocId = data['participantDocumentId'] ??
          data['userPublicId'] ??
          data['userId'];
      if (pDocId != null && pDocId.toString().isNotEmpty) {
        final activeQueueRef = FirebaseFirestore.instance
            .collection(pCollection)
            .doc(pDocId)
            .collection('active_queue')
            .doc(widget
                .businessDocId); // public ID might be better but we use businessDocId here, wait, in assignToken it used businessPublicId!
        // We might not have businessPublicId here, let's just query it or update based on what's available
        // Actually, tokenData has businessPublicId!
        final String? bPubId = data['businessPublicId'];
        if (bPubId != null && bPubId.isNotEmpty) {
          final activeQueueRef = FirebaseFirestore.instance
              .collection(pCollection)
              .doc(pDocId)
              .collection('active_queue')
              .doc(bPubId);
          transaction.update(activeQueueRef, {
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp()
          });
        }
      }
    });
  }

  Future<void> _startNextToken(
      String currentServingId, String nextWaitingId) async {
    final batch = FirebaseFirestore.instance.batch();

    final stateRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(widget.businessDocId)
        .collection('queue_state')
        .doc(todayId);

    if (currentServingId.isNotEmpty) {
      final currentRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessDocId)
          .collection('queue')
          .doc(currentServingId);

      final currentDoc = await currentRef.get();
      if (currentDoc.exists) {
        batch.update(currentRef, {'status': 'completed'});
        batch.update(stateRef, {'completedCount': FieldValue.increment(1)});

        final data = currentDoc.data()!;
        final pCollection = data['participantCollection'] ?? 'users';
        final pDocId = data['participantDocumentId'] ??
            data['userPublicId'] ??
            data['userId'];
        if (pDocId != null && pDocId.toString().isNotEmpty) {
          final String? bPubId = data['businessPublicId'];
          if (bPubId != null && bPubId.isNotEmpty) {
            final activeQueueRef = FirebaseFirestore.instance
                .collection(pCollection)
                .doc(pDocId)
                .collection('active_queue')
                .doc(bPubId);
            batch.update(activeQueueRef, {
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp()
            });
          }
        }
      }
    }

    if (nextWaitingId.isNotEmpty) {
      final nextRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessDocId)
          .collection('queue')
          .doc(nextWaitingId);

      final nextDoc = await nextRef.get();
      if (nextDoc.exists) {
        int nextNum = nextDoc.data()?['tokenNumber'] ?? 0;
        batch.update(nextRef, {'status': 'now_serving'});
        batch.update(stateRef, {
          'currentServingNumber': nextNum,
          'waitingCount': FieldValue.increment(-1),
        });

        final data = nextDoc.data()!;
        final pCollection = data['participantCollection'] ?? 'users';
        final pDocId = data['participantDocumentId'] ??
            data['userPublicId'] ??
            data['userId'];
        if (pDocId != null && pDocId.toString().isNotEmpty) {
          final String? bPubId = data['businessPublicId'];
          if (bPubId != null && bPubId.isNotEmpty) {
            final activeQueueRef = FirebaseFirestore.instance
                .collection(pCollection)
                .doc(pDocId)
                .collection('active_queue')
                .doc(bPubId);
            batch.update(activeQueueRef, {
              'status': 'now_serving',
              'updatedAt': FieldValue.serverTimestamp()
            });
          }
        }
      }
    } else if (currentServingId.isNotEmpty) {
      // If we just completed the last one and there is no next
      batch.update(stateRef, {
        'currentServingNumber': 0,
      });
    }

    await batch.commit();
  }

  void _showCustomerDetails(
      Map<String, dynamic> tokenData, String tokenId, String nextWaitingId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer Details',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Token #${tokenData['tokenNumber']}',
                        style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                  'Name', tokenData['customerName']?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _detailRow(
                  'Service', tokenData['serviceName']?.toString() ?? 'General'),
              const SizedBox(height: 12),
              _detailRow('Phone',
                  tokenData['participantPhone']?.toString() ?? 'Unknown'),
              const SizedBox(height: 12),
              _detailRow('Status',
                  (tokenData['status'] ?? '').toString().toUpperCase()),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tokenData['participantPhone'] != null &&
                      tokenData['participantPhone'].toString().isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _callCustomer(tokenData['participantPhone'].toString());
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Customer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F2E5A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  if (tokenData['participantPhone'] != null &&
                      tokenData['participantPhone'].toString().isNotEmpty)
                    const SizedBox(height: 12),
                  Row(
                    children: [
                      if (tokenData['status'] == 'waiting' ||
                          tokenData['status'] == 'now_serving')
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _cancelToken(tokenId, nextWaitingId);
                            },
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.red),
                            label: const Text('Cancel',
                                style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      if (tokenData['status'] == 'waiting' ||
                          tokenData['status'] == 'now_serving')
                        const SizedBox(width: 12),
                      if (tokenData['status'] == 'now_serving')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _completeToken(tokenId);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if (tokenData['status'] == 'waiting')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _startNextToken('', tokenId);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2E5A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('queue'.tr,
            style: TextStyle(
                color: Color(0xFF0F2E5A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F2E5A)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessDocId)
            .collection('queue_state')
            .doc(todayId)
            .snapshots(),
        builder: (context, stateSnapshot) {
          if (stateSnapshot.hasError) {
            return Center(
                child:
                    Text('Error loading queue state: ${stateSnapshot.error}'));
          }
          if (!stateSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final stateData =
              stateSnapshot.data!.data() as Map<String, dynamic>? ?? {};

          debugPrint('===== BUSINESS QUEUE STATE DEBUG =====');
          debugPrint('Business ID: ${widget.businessDocId}');
          debugPrint('Today ID: $todayId');
          debugPrint('Path: ${stateSnapshot.data!.reference.path}');
          debugPrint('Exists: ${stateSnapshot.data!.exists}');
          debugPrint('Data: $stateData');
          debugPrint('======================================');

          final isOpen = stateData['isOpen'] == true;
          final status = stateData['status'] ?? (isOpen ? 'open' : 'closed');
          final waitingCount = stateData['waitingCount'] ?? 0;
          final completedCount =
              stateData['completedCount'] ?? 0; // Fallback if missing
          final currentServingNumber = stateData['currentToken'] ??
              stateData['currentServingNumber'] ??
              0;

          return Column(
            children: [
              _buildStatusHeader(
                  status, currentServingNumber, waitingCount, completedCount),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(widget.businessDocId)
                      .collection('queue')
                      .where('queueDate', isEqualTo: todayId)
                      .snapshots(),
                  builder: (context, queueSnapshot) {
                    if (queueSnapshot.hasError) {
                      debugPrint('Queue Stream Error: ${queueSnapshot.error}');
                      return Center(
                          child: Text(
                              'Error loading queue: ${queueSnapshot.error}'));
                    }
                    if (!queueSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final docs = queueSnapshot.data!.docs.toList();

                    debugPrint('===== BUSINESS QUEUE DOCS DEBUG =====');
                    debugPrint('Business ID: ${widget.businessDocId}');
                    debugPrint('Today ID: $todayId');
                    debugPrint('Documents: ${docs.length}');
                    for (final doc in docs) {
                      debugPrint('DOC PATH: ${doc.reference.path}');
                      debugPrint('DOC ID: ${doc.id}');
                      debugPrint('DOC DATA: ${doc.data()}');
                    }
                    debugPrint('=====================================');
                    docs.sort((a, b) {
                      final numA = (a.data() as Map)['tokenNumber'] ?? 0;
                      final numB = (b.data() as Map)['tokenNumber'] ?? 0;
                      return numA.compareTo(numB);
                    });
                    final nowServing = docs
                        .where(
                            (d) => (d.data() as Map)['status'] == 'now_serving')
                        .toList();
                    final waiting = docs
                        .where((d) => (d.data() as Map)['status'] == 'waiting')
                        .toList();

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (nowServing.isNotEmpty) ...[
                          const Text('NOW SERVING',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          _buildCustomerCard(nowServing.first, true,
                              waiting.isNotEmpty ? waiting.first.id : ''),
                          const SizedBox(height: 24),
                        ],
                        if (waiting.isNotEmpty) ...[
                          const Text('NEXT CUSTOMERS',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          ...waiting
                              .map((doc) => _buildCustomerCard(doc, false, ''))
                              .toList(),
                        ],
                        if (nowServing.isEmpty && waiting.isEmpty)
                          _buildEmptyState(status),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(
      String status, int current, int waiting, int completed) {
    Color statusColor = status == 'open'
        ? Colors.green
        : (status == 'paused' ? Colors.orange : Colors.red);
    String statusText = status.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Queue $statusText',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: _updateQueueStatus,
                itemBuilder: (context) => [
                  if (status != 'open')
                    PopupMenuItem(
                        value: 'open',
                        child: Text(
                            status == 'paused' ? 'Start Queue' : 'Open Queue')),
                  if (status == 'open')
                    const PopupMenuItem(
                        value: 'paused', child: Text('Pause Queue')),
                  if (status != 'closed')
                    const PopupMenuItem(
                        value: 'closed', child: Text('Close Queue')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Text('Change Status', style: TextStyle(fontSize: 12)),
                      Icon(Icons.arrow_drop_down, size: 16)
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statBox('Serving', current > 0 ? '#$current' : '-', Colors.blue),
              _statBox('Waiting', '$waiting', Colors.orange),
              _statBox('Completed', '$completed', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(status == 'closed' ? 'Queue Closed' : 'Queue is Empty',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              status == 'closed'
                  ? "Today's queue is closed."
                  : 'No customers are currently waiting.',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
      DocumentSnapshot doc, bool isServing, String nextWaitingId) {
    final data = doc.data() as Map<String, dynamic>;
    final num = data['tokenNumber'];
    final name = data['customerName'] ?? 'Unknown';
    final service = data['serviceName'] ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isServing ? const Color(0xFF2563EB) : Colors.grey.shade200,
            width: isServing ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(data, doc.id, nextWaitingId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: isServing
                        ? const Color(0xFFEEF2FF)
                        : Colors.grey.shade200,
                    backgroundImage: data['participantImage'] != null &&
                            data['participantImage'].toString().isNotEmpty
                        ? NetworkImage(data['participantImage'])
                        : null,
                    child: data['participantImage'] == null ||
                            data['participantImage'].toString().isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isServing
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade700),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isServing
                                    ? const Color(0xFF2563EB).withOpacity(0.1)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Token #$num',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isServing
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey.shade700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(service.isNotEmpty ? service : 'General Service',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
              if (isServing || (!isServing && data['status'] == 'waiting')) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelToken(
                            doc.id, isServing ? nextWaitingId : ''),
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        label: const Text('Cancel',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isServing)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _startNextToken(doc.id, nextWaitingId),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Complete & Next',
                              style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2E5A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    if (!isServing && data['status'] == 'waiting')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _startNextToken('', doc.id),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

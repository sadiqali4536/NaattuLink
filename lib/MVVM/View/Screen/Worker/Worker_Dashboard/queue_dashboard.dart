import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';

class BusinessQueueDashboard extends StatefulWidget {
  final String businessDocId;
  const BusinessQueueDashboard({Key? key, required this.businessDocId}) : super(key: key);

  @override
  State<BusinessQueueDashboard> createState() => _BusinessQueueDashboardState();
}

class _BusinessQueueDashboardState extends State<BusinessQueueDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateTokenStatus(String tokenId, String newStatus) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(widget.businessDocId)
          .collection('queue')
          .doc(tokenId)
          .update({
        'status': newStatus,
        '${newStatus}At': FieldValue.serverTimestamp(),
      });
      
      // Update queue state waiting count if cancelled
      if (newStatus == 'cancelled') {
         final queueStateRef = _firestore.collection('businesses').doc(widget.businessDocId).collection('queue_state').doc('today');
         await queueStateRef.update({'waitingCount': FieldValue.increment(-1)});
      }
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error'),
          description: Text(e.toString()),
          animationType: AnimationType.fromTop,
        ).show(context);
      }
    }
  }

  Future<void> _completeAndStartNext(String currentTokenId, String nextTokenId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final currentRef = _firestore
            .collection('businesses')
            .doc(widget.businessDocId)
            .collection('queue')
            .doc(currentTokenId);
            
        final nextRef = _firestore
            .collection('businesses')
            .doc(widget.businessDocId)
            .collection('queue')
            .doc(nextTokenId);

        transaction.update(currentRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
        
        transaction.update(nextRef, {
          'status': 'in_service',
          'calledAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) {
        CherryToast.error(
          title: const Text('Error'),
          description: Text(e.toString()),
          animationType: AnimationType.fromTop,
        ).show(context);
      }
    }
  }


  Future<void> _openQueueSettings() async {
    final businessDoc = await _firestore.collection('businesses').doc(widget.businessDocId).get();
    if (!businessDoc.exists) return;
    
    final data = businessDoc.data()!;
    bool queueEnabled = data['queueEnabled'] ?? false;
    int avgTime = data['averageServiceTime'] ?? 20;
    int maxQueue = data['maxQueueCapacity'] ?? 30;
    bool allowCancel = data['allowCancelToken'] ?? true;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Queue & Token Settings", style: TextStyle(color: Color(0xFF0F2E5A), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text("Enable Queue & Token"),
                      value: queueEnabled,
                      activeColor: const Color(0xFF0F2E5A),
                      onChanged: (val) => setState(() => queueEnabled = val),
                    ),
                    if (queueEnabled) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: avgTime.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Avg Service Time (mins)", border: OutlineInputBorder()),
                        onChanged: (val) => avgTime = int.tryParse(val) ?? 20,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: maxQueue.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Max Queue Capacity", border: OutlineInputBorder()),
                        onChanged: (val) => maxQueue = int.tryParse(val) ?? 30,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Allow Cancellations"),
                        value: allowCancel,
                        activeColor: const Color(0xFF0F2E5A),
                        onChanged: (val) => setState(() => allowCancel = val),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _firestore.collection('businesses').doc(widget.businessDocId).update({
                      'queueEnabled': queueEnabled,
                      'queueType': 'queue',
                      'averageServiceTime': avgTime,
                      'maxQueueCapacity': maxQueue,
                      'allowCancelToken': allowCancel,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      CherryToast.success(title: const Text("Settings Saved")).show(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2E5A)),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Queue"),
        backgroundColor: const Color(0xFF0F2E5A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openQueueSettings,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('businesses')
            .doc(widget.businessDocId)
            .collection('queue')
            .orderBy('tokenNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          
          final inService = docs.where((doc) => doc['status'] == 'in_service').toList();
          final waiting = docs.where((doc) => doc['status'] == 'waiting').toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Now Serving", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (inService.isNotEmpty)
                _buildCurrentTokenCard(inService.first, waiting.isNotEmpty ? waiting.first : null)
              else if (waiting.isNotEmpty)
                _buildStartNextCard(waiting.first)
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No active tokens at the moment.", style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 24),
              const Text("Waiting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...waiting.map((doc) => _buildWaitingCard(doc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentTokenCard(QueryDocumentSnapshot current, QueryDocumentSnapshot? next) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "#${current['tokenNumber']}",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF0F2E5A)),
            ),
            const Text("IN SERVICE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (next != null) {
                        _completeAndStartNext(current.id, next.id);
                      } else {
                        _updateTokenStatus(current.id, 'completed');
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2E5A)),
                    child: Text(next != null ? "Complete & Start Next" : "Complete", style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStartNextCard(QueryDocumentSnapshot next) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Ready for next customer?"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _updateTokenStatus(next.id, 'in_service'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Start #${next['tokenNumber']}", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCard(QueryDocumentSnapshot doc) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Text("#${doc['tokenNumber']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ),
        title: const Text("Waiting"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _updateTokenStatus(doc.id, 'cancelled'),
              child: const Text("Skip", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

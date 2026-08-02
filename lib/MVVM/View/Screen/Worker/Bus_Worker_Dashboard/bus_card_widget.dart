import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cherry_toast/cherry_toast.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/add_new_bus.dart';

class BusCardWidget extends StatelessWidget {
  final String busName;
  final String regNumber;
  final String firstStop;
  final String destination;
  final String arrivalTime;
  final String departureTime;
  final String status;
  final String? docId;
  final bool isMainBus;
  final Map<String, dynamic> rawData;

  const BusCardWidget({
    Key? key,
    required this.busName,
    required this.regNumber,
    required this.firstStop,
    required this.destination,
    required this.arrivalTime,
    required this.departureTime,
    required this.status,
    required this.docId,
    required this.isMainBus,
    required this.rawData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(busName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE' ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: status == 'ACTIVE',
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (val) async {
                    if (val) {
                      CherryToast.info(
                        title:
                            const Text('Please edit the bus to make it Active'),
                      ).show(context);
                      return;
                    }
                    String newStatus = 'INACTIVE';
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;
                    if (isMainBus) {
                      await FirebaseFirestore.instance
                          .collection('transports')
                          .doc(uid)
                          .update({'status': newStatus});
                    } else if (docId != null) {
                      await FirebaseFirestore.instance
                          .collection('transports')
                          .doc(uid)
                          .collection('buses')
                          .doc(docId)
                          .update({'status': newStatus});
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(regNumber,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text('$firstStop -> $destination',
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text('$arrivalTime - $departureTime',
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNewBusScreen(
                            isEdit: true,
                            busId: docId,
                            isMainBus: isMainBus,
                            initialData: rawData,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0C1F41),
                      side: const BorderSide(color: Color(0xFF0C1F41)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Bus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naattulink/MVVM/View/Screen/Worker/Bus_Worker_Dashboard/bus_card_widget.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';

class SeeAllBusesScreen extends StatelessWidget {
  const SeeAllBusesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C1F41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: AppBackButton(),
        ),
        title: const Text('All Buses',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transports')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final hasOriginalBus = (data['bus_name'] != null &&
                data['bus_name'].toString().isNotEmpty);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transports')
                  .doc(uid)
                  .collection('buses')
                  .snapshots(),
              builder: (context, busSnapshot) {
                if (busSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = busSnapshot.hasData ? busSnapshot.data!.docs : [];
                final totalCount = docs.length + (hasOriginalBus ? 1 : 0);

                if (totalCount == 0) {
                  return const Center(child: Text("No buses found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (hasOriginalBus && index == 0) {
                      return BusCardWidget(
                        busName: data['bus_name'] ?? 'N/A',
                        regNumber: data['reg_number'] ?? 'N/A',
                        firstStop: data['first_stop'] ?? 'N/A',
                        destination: data['destination'] ?? 'N/A',
                        arrivalTime: data['arrival_time'] ?? 'N/A',
                        departureTime: data['departure_time'] ?? 'N/A',
                        status: data['status']?.toString().toUpperCase() ??
                            'ACTIVE',
                        docId: uid,
                        isMainBus: true,
                        rawData: data,
                      );
                    }

                    final docIndex = hasOriginalBus ? index - 1 : index;
                    final docSnapshot = docs[docIndex];
                    final bData = docSnapshot.data() as Map<String, dynamic>;
                    return BusCardWidget(
                      busName: bData['bus_name'] ?? 'Unknown',
                      regNumber: bData['registration_number'] ?? 'N/A',
                      firstStop: bData['start_place'] ?? 'Start',
                      destination: bData['destination'] ?? 'End',
                      arrivalTime: bData['arrival_time'] ?? '--:--',
                      departureTime: bData['departure_time'] ?? '--:--',
                      status: (bData['status'] == true ||
                              bData['status'] == 'true' ||
                              bData['status'] == 'active' ||
                              bData['status'] == 'ACTIVE')
                          ? 'ACTIVE'
                          : 'INACTIVE',
                      docId: docSnapshot.id,
                      isMainBus: false,
                      rawData: bData,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

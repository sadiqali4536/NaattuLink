// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:swiftclean_project/MVVM/View/Screen/Worker/worker_main_page.dart';
// import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

// class WorkerDashboard extends StatefulWidget {
//   const WorkerDashboard({super.key});

//   @override
//   State<WorkerDashboard> createState() => _WorkerDashboardState();
// }

// class _WorkerDashboardState extends State<WorkerDashboard> {
//   final user = FirebaseAuth.instance.currentUser;

//   @override
//   Widget build(BuildContext context) {
//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Please login first.")),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Worker Dashboard"),
//         backgroundColor: gradientgreen2.c,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person_outline),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const WorkerMainPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

//           final allBookings = snapshot.data!.docs;

//           final myRequested = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data.containsKey('workerId') &&
//                 data['workerId'] == user!.uid &&
//                 data['status'] == 'requested';
//           }).toList();

//           final myApproved = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data.containsKey('workerId') &&
//                 data['workerId'] == user!.uid &&
//                 data['status'] == 'approved';
//           }).toList();

//           final myCompleted = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data.containsKey('workerId') &&
//                 data['workerId'] == user!.uid &&
//                 data['status'] == 'completed';
//           }).toList();

//           final available = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['status'] == 'pending';
//           }).toList();

//           final hasActiveJob = myRequested.isNotEmpty || myApproved.isNotEmpty;

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               if (myRequested.isNotEmpty)
//                 _jobCard(myRequested.first, "Requested (Waiting for Admin)", Colors.orange),

//               if (myApproved.isNotEmpty)
//                 _jobCard(myApproved.first, "In Progress", Colors.green, showCompleteButton: true),

//               if (myCompleted.isNotEmpty) ...[
//                 const SizedBox(height: 20),
//                 const Text("Completed Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 ...myCompleted.map((doc) => _jobCard(doc, "Completed", Colors.grey)),
//               ],

//               const SizedBox(height: 20),
//               const Divider(thickness: 1),
//               const SizedBox(height: 10),

//               const Text("Available Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),

//               if (hasActiveJob)
//                 const Padding(
//                   padding: EdgeInsets.all(12),
//                   child: Text(
//                     "⚠️ You already have an active job. Complete it before requesting a new one.",
//                     style: TextStyle(color: Colors.red, fontSize: 15),
//                     textAlign: TextAlign.center,
//                   ),
//                 )
//               else if (available.isEmpty)
//                 const Text("No jobs available at the moment.")
//               else
//                 ...available.map((doc) => _availableJobCard(doc)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _jobCard(QueryDocumentSnapshot doc, String label, Color color, {bool showCompleteButton = false}) {
//     final data = doc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 4,
//       child: ListTile(
//         title: Text(data['serviceTitle'] ?? 'No title'),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Category: ${data['category'] ?? ''}"),
//             Text("Status: $label"),
//             Text("Price: ₹${data['discountPrice'] ?? '0'}"),
//           ],
//         ),
//         trailing: showCompleteButton
//             ? ElevatedButton(
//                 onPressed: () => _markCompleted(doc.id),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 child: const Text("Complete"),
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _availableJobCard(QueryDocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 3,
//       child: ListTile(
//         title: Text(data['serviceTitle'] ?? ''),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Category: ${data['category'] ?? ''}"),
//             Text("Price: ₹${data['discountPrice'] ?? '0'}"),
//           ],
//         ),
//         trailing: ElevatedButton(
//           onPressed: () => _requestJob(doc.id),
//           style: ElevatedButton.styleFrom(backgroundColor: gradientgreen2.c),
//           child: const Text("Request"),
//         ),
//       ),
//     );
//   }

//   Future<void> _requestJob(String bookingId) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
//       'status': 'requested',
//       'workerId': user.uid.toString(),
//       'workerName': user.workerName ?? '',
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       content: Text("✅ Job requested. Waiting for admin approval."),
//     ));
//   }

//   Future<void> _markCompleted(String bookingId) async {
//     await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
//       'status': 'completed',
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       content: Text("✅ Job marked as completed."),
//     ));
//   }
// }

// extension on User {
//   get workerName => null;
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:swiftclean_project/MVVM/View/Screen/Worker/worker_main_page.dart';
// import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

// class WorkerDashboard extends StatefulWidget {
//   const WorkerDashboard({super.key});

//   @override
//   State<WorkerDashboard> createState() => _WorkerDashboardState();
// }

// class _WorkerDashboardState extends State<WorkerDashboard> {
//   final user = FirebaseAuth.instance.currentUser;
//   String? workerCategory;
//   String? workerName;

//   @override
//   void initState() {
//     super.initState();
//     fetchWorkerDetails();
//   }

//   Future<void> fetchWorkerDetails() async {
//     if (user == null) return;

//     final doc = await FirebaseFirestore.instance
//         .collection('workers')
//         .doc(user!.uid)
//         .get();

//     if (doc.exists) {
//       final data = doc.data();
//       if (data != null) {
//         setState(() {
//           workerCategory = data['category']?.toString().toLowerCase();
//           workerName = data['name'] ?? 'Unnamed';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Please login first.")),
//       );
//     }

//     if (workerCategory == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Worker Dashboard"),
//         backgroundColor: gradientgreen2.c,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person_outline),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const WorkerMainPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final allBookings = snapshot.data!.docs;

//           final myRequested = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['workerId'] == user!.uid && data['status'] == 'requested';
//           }).toList();

//           final myApproved = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['workerId'] == user!.uid && data['status'] == 'approved';
//           }).toList();

//           final myCompleted = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return data['workerId'] == user!.uid && data['status'] == 'completed';
//           }).toList();

//           final available = allBookings.where((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             final bookingCategory = data['category']?.toString().toLowerCase();
//             return data['status'] == 'pending' && bookingCategory == workerCategory;
//           }).toList();

//           final hasActiveJob = myRequested.isNotEmpty || myApproved.isNotEmpty;

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               if (myRequested.isNotEmpty)
//                 _jobCard(myRequested.first, "Requested (Waiting for Admin)", Colors.orange),

//               if (myApproved.isNotEmpty)
//                 _jobCard(myApproved.first, "In Progress", Colors.green, showCompleteButton: true),

//               if (myCompleted.isNotEmpty) ...[
//                 const SizedBox(height: 20),
//                 const Text("Completed Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 ...myCompleted.map((doc) => _jobCard(doc, "Completed", Colors.grey)),
//               ],

//               const SizedBox(height: 20),
//               const Divider(thickness: 1),
//               const SizedBox(height: 10),

//               const Text("Available Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 10),

//               if (hasActiveJob)
//                 const Padding(
//                   padding: EdgeInsets.all(12),
//                   child: Text(
//                     "⚠️ You already have an active job. Complete it before requesting a new one.",
//                     style: TextStyle(color: Colors.red, fontSize: 15),
//                     textAlign: TextAlign.center,
//                   ),
//                 )
//               else if (available.isEmpty)
//                 const Text("No jobs available at the moment.")
//               else
//                 ...available.map((doc) => _availableJobCard(doc)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _jobCard(QueryDocumentSnapshot doc, String label, Color color, {bool showCompleteButton = false}) {
//     final data = doc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 4,
//       child: ListTile(
//         title: Text(data['serviceTitle'] ?? 'No title'),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Category: ${data['category'] ?? ''}"),
//             Text("Status: $label"),
//             Text("Price: ₹${data['discountPrice'] ?? '0'}"),
//             Text("Worker: ${data['workerName'] ?? 'Not assigned'}"),
//           ],
//         ),
//         trailing: showCompleteButton
//             ? ElevatedButton(
//                 onPressed: () => _markCompleted(doc.id),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                 child: const Text("Complete"),
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _availableJobCard(QueryDocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;

//     return Card(
//       elevation: 3,
//       child: ListTile(
//         title: Text(data['serviceTitle'] ?? ''),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Category: ${data['category'] ?? ''}"),
//             Text("Price: ₹${data['discountPrice'] ?? '0'}"),
//           ],
//         ),
//         trailing: ElevatedButton(
//           onPressed: () => _requestJob(doc.id),
//           style: ElevatedButton.styleFrom(backgroundColor: gradientgreen2.c),
//           child: const Text("Request"),
//         ),
//       ),
//     );
//   }

//   Future<void> _requestJob(String bookingId) async {
//     if (user == null || workerName == null) return;

//     await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
//       'status': 'requested',
//       'workerId': user!.uid,
//       'workerName': workerName,
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       content: Text("✅ Job requested. Waiting for admin approval."),
//     ));
//   }

//   Future<void> _markCompleted(String bookingId) async {
//     await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
//       'status': 'completed',
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//       content: Text("✅ Job marked as completed."),
//     ));
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swiftclean_project/MVVM/View/Screen/Worker/worker_main_page.dart';
import 'package:swiftclean_project/MVVM/Viewmodel/location_controller.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  String? workerName;
  String? workerCategory;

  @override
  void initState() {
    super.initState();
    fetchWorkerDetails();
  }

  Future<void> fetchWorkerDetails() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('workers')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          workerName = data['name'] ?? 'Unnamed';
          workerCategory = data['category']?.toString().toLowerCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Worker Dashboard',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Obx(() {
              final loc = LocationController.to.currentLocation.value;
              if (loc.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFF5B544), size: 13),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      loc,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        backgroundColor: gradientgreen2.c,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerMainPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allBookings = snapshot.data!.docs;

          final myRequested = allBookings.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['workerId'] == user!.uid &&
                data['status'] == 'requested';
          }).toList();

          final myApproved = allBookings.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['workerId'] == user!.uid &&
                data['status'] == 'approved';
          }).toList();

          final myCompleted = allBookings.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['workerId'] == user!.uid &&
                data['status'] == 'completed';
          }).toList();

          final available = allBookings.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending' &&
                (data['category']?.toString().toLowerCase() == workerCategory);
          }).toList();

          final hasActiveJob = myRequested.isNotEmpty || myApproved.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (myRequested.isNotEmpty)
                _jobCard(myRequested.first, "Requested (Waiting for Admin)", Colors.orange),

              if (myApproved.isNotEmpty)
                _jobCard(myApproved.first, "In Progress", Colors.green, showCompleteButton: true),

              if (myCompleted.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text("Completed Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...myCompleted.map((doc) => _jobCard(doc, "Completed", Colors.grey)),
              ],

              const SizedBox(height: 20),
              const Divider(thickness: 1),
              const SizedBox(height: 10),

              const Text("Available Jobs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (hasActiveJob)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "⚠️ You already have an active job. Complete it before requesting a new one.",
                    style: TextStyle(color: Colors.red, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (available.isEmpty)
                const Text("No jobs available at the moment.")
              else
                ...available.map((doc) => _availableJobCard(doc)),
            ],
          );
        },
      ),
    );
  }

  Widget _jobCard(QueryDocumentSnapshot doc, String label, Color color, {bool showCompleteButton = false}) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(data['serviceTitle'] ?? 'No title'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${data['category'] ?? ''}"),
            Text("Status: $label"),
            Text("Worker: ${data['workerName'] ?? 'Not assigned'}"),
            Text("Price: ₹${data['discountPrice'] ?? '0'}"),
          ],
        ),
        trailing: showCompleteButton
            ? ElevatedButton(
                onPressed: () => _markCompleted(doc.id),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Complete"),
              )
            : null,
      ),
    );
  }

  Widget _availableJobCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Card(
      elevation: 3,
      child: ListTile(
        title: Text(data['serviceTitle'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${data['category'] ?? ''}"),
            Text("Price: ₹${data['discountPrice'] ?? '0'}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _requestJob(doc.id),
          style: ElevatedButton.styleFrom(backgroundColor: gradientgreen2.c),
          child: const Text("Request"),
        ),
      ),
    );
  }

  Future<void> _requestJob(String bookingId) async {
    if (user == null || workerName == null) return;

    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'requested',
      'workerId': user!.uid,
      'workerName': workerName,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ Job requested. Waiting for admin approval."),
    ));
  }

  Future<void> _markCompleted(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'completed',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ Job marked as completed."),
    ));
  }
}

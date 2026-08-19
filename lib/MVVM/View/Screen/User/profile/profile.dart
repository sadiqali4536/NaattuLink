import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/My_Address/address_page.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/loyalty_points.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/my_bookings.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/profile_page.dart';
import 'package:naattulink/MVVM/model/services/firebaseauthservices.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/Founctions/helper_functions.dart';
import 'package:naattulink/MVVM/utils/widget/containner/shimmer_skeleton.dart';
import 'package:naattulink/main.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  String _formattedTime(DateTime time) {
    return DateFormat("hh:mm a").format(time);
  }

  String _getDateHeader(DateTime time) {
    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(time) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return "Today";
    } else if (DateFormat('yyyy-MM-dd').format(time) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat("dd MMM yyyy").format(time);
    }
  }

  Future<Map<String, String>?> _resolveUserIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    var doc = await getUserDocument(user, 'users');
    if (doc != null && doc.exists) return {'id': doc.id, 'collection': 'users'};

    doc = await getUserDocument(user, 'healthcare');
    if (doc != null && doc.exists)
      return {'id': doc.id, 'collection': 'healthcare'};

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 239, 239),
      body: FutureBuilder<Map<String, String>?>(
        future: _resolveUserIdentity(),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const ProfileSkeleton();
          }

          if (!futureSnapshot.hasData || futureSnapshot.data == null) {
            return const Center(child: Text('User not found'));
          }

          final identity = futureSnapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection(identity['collection']!)
                .doc(identity['id'])
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const ProfileSkeleton();
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  return _buildProfileUI(context, mq, data);
                }
              }

              return const Center(child: Text('Something went wrong'));
            },
          );
        },
      ),
    );
  }

  Widget _buildPharmacyInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showEditPharmacyDialog(
      BuildContext context, Map<String, dynamic> data) {
    final TextEditingController facilityCtrl =
        TextEditingController(text: data['facility_name'] ?? '');

    // Clean up existing contact number (remove +91 if present for the text field)
    String currentContact = data['contact_number'] ?? '';
    if (currentContact.startsWith('+91')) {
      currentContact = currentContact.substring(3).trim();
    }
    final TextEditingController contactCtrl =
        TextEditingController(text: currentContact);

    String openTime = "10:00 AM";
    String closeTime = "05:00 PM";
    if (data['available_time'] != null) {
      final parts = data['available_time'].split('-');
      if (parts.length == 2) {
        openTime = parts[0].trim();
        closeTime = parts[1].trim();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Edit Pharmacy Details",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2E5A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildCustomTextField(
                        controller: facilityCtrl,
                        label: "Facility Name",
                        icon: Icons.business,
                      ),
                      const SizedBox(height: 15),
                      _buildCustomTextField(
                        controller: contactCtrl,
                        label: "Contact Number",
                        icon: Icons.phone_in_talk,
                        keyboardType: TextInputType.phone,
                        prefixText: "+91 ",
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Available Time",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerCard(
                              context: context,
                              label: "Open",
                              time: openTime,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0F2E5A),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF0F2E5A),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    openTime = picked.format(context);
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTimePickerCard(
                              context: context,
                              label: "Close",
                              time: closeTime,
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF0F2E5A),
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF0F2E5A),
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    closeTime = picked.format(context);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2E5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance
                                    .collection('healthcare')
                                    .doc(uid)
                                    .update({
                                  'facility_name': facilityCtrl.text.trim(),
                                  'contact_number':
                                      "+91${contactCtrl.text.trim()}",
                                  'available_time': "$openTime - $closeTime",
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
  }

  Widget _buildTimePickerCard({
    required BuildContext context,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2E5A),
                  ),
                ),
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF0F2E5A)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF0F2E5A)),
        prefixText: prefixText,
        counterText: "", // Hide the default character counter
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F2E5A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildProfileUI(
      BuildContext context, Size mq, Map<String, dynamic> data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(35),
                      child: SizedBox(
                        height: 70,
                        width: 70,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 50,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: gradientgreen2.c,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        data["username"],
                        style: TextStyle(
                            fontSize: 23, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      data['created_at'] != null
                          ? formatDate(data['created_at'] as Timestamp)
                          : 'N/A',
                      style: const TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "0 Total Bookings",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (data['role'] == 'healthcare' &&
                data['profession'] == 'Pharmacy') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A235C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A235C).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_pharmacy_outlined,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                "Pharmacy Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              _showEditPharmacyDialog(context, data);
                            },
                            icon: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPharmacyInfoRow(Icons.business, "Facility",
                          data['facility_name'] ?? 'N/A'),
                      const SizedBox(height: 12),
                      _buildPharmacyInfoRow(Icons.phone_in_talk, "Contact",
                          data['contact_number'] ?? 'N/A'),
                      const SizedBox(height: 12),
                      _buildPharmacyInfoRow(Icons.access_time, "Time",
                          data['available_time'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
            Padding(
              padding: EdgeInsets.only(right: mq.height * 0.37),
              child: Text(
                'General',
                style: TextStyle(color: const Color.fromRGBO(133, 118, 138, 1)),
              ),
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ProfilePage(
                              image: data['image'],
                              email: data['email'],
                              phone: data['phone'],
                              username: data['username'],
                              createDate: data['created_at'] != null
                                  ? formatDate(data['created_at'] as Timestamp)
                                  : 'N/A',
                            )));
              },
              child: Container(
                child: Row(
                  children: [
                    SizedBox(width: mq.width * 0.05),
                    Icon(Icons.person),
                    SizedBox(width: mq.width * 0.05),
                    Text("Profile")
                  ],
                ),
                height: 60,
                width: mq.width * 0.900,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    color: Colors.white),
              ),
            ),
            SizedBox(height: 2),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddressPage()));
              },
              child: Container(
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Icon(Icons.my_location),
                    SizedBox(width: 10),
                    Text("My Address")
                  ],
                ),
                height: 60,
                width: mq.width * 0.900,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    color: Colors.white),
              ),
            ),
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MyBookings()));
              },
              child: Container(
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Image.asset("assets/icons/booking.png"),
                    SizedBox(width: 10),
                    Text("My Bookings")
                  ],
                ),
                height: 60,
                width: mq.width * 0.900,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(right: mq.width * 0.680),
              child: Text(
                'Loyality Points',
                style: TextStyle(color: const Color.fromRGBO(133, 118, 138, 1)),
              ),
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoyaltyPoints()));
              },
              child: Container(
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color.fromARGB(255, 0, 0, 0)),
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text("Loyality Points"),
                    SizedBox(width: mq.width * 0.250),
                    Container(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, left: 6),
                        child: Text(
                          "0 Points",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      height: 30,
                      width: 60,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.red),
                    )
                  ],
                ),
                height: 60,
                width: mq.width * 0.900,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxWidth = constraints.maxWidth > 400
                                ? 347.0
                                : constraints.maxWidth * 0.9;
                            final maxHeight = constraints.maxHeight > 300
                                ? 270.0
                                : constraints.maxHeight * 0.9;

                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxWidth,
                                maxHeight: maxHeight,
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 15),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 20),
                                      Container(
                                        height: 60,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: gradientgreen2.c,
                                        ),
                                        child: Icon(
                                          Icons.question_mark,
                                          size: 35,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 30),
                                      Text(
                                        "Are you sure want to logout",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromRGBO(125, 117, 128, 1),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: 146,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: Color.fromARGB(
                                                    255, 219, 219, 219),
                                              ),
                                              child: TextButton(
                                                onPressed: () async {
                                                  await FirebaseAuthServices()
                                                      .signOut(context);
                                                  Get.off(LoginAndSigning());
                                                },
                                                child: Text(
                                                  "Yes",
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                          ),
                                          Expanded(
                                            child: Container(
                                              width: 146,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: gradientgreen2.c,
                                              ),
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  "NO",
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  width: 120,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 238, 238, 238),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icons/Logout_button.png",
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 8),
                      Text("Logout"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/My_Address/address_page.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/loyalty_points.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/my_bookings.dart';
import 'package:swiftclean_project/MVVM/View/Screen/User/profile/profile_page.dart';
import 'package:swiftclean_project/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/Founctions/helper_functions.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/shimmer_skeleton.dart';
import 'package:swiftclean_project/main.dart';

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

  @override
  Widget build(BuildContext context) {
    final mq =
        MediaQuery.of(context).size; // You use mq but didn't show it defined

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 239, 239),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ProfileSkeleton();
          }

          final data = snapshot.data?.data();

          if (data == null) {
            return Center(
              child: Text('Something went wrong'),
            );
          }

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 5),
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
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.only(right: mq.height * 0.37),
                    child: Text(
                      'General',
                      style: TextStyle(
                          color: const Color.fromRGBO(133, 118, 138, 1)),
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
                                        ? formatDate(
                                            data['created_at'] as Timestamp)
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddressPage()));
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyBookings()));
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
                      style: TextStyle(
                          color: const Color.fromRGBO(133, 118, 138, 1)),
                    ),
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoyaltyPoints()));
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
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
                                                color: Color.fromRGBO(
                                                    125, 117, 128, 1),
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
                                                          BorderRadius.circular(
                                                              20),
                                                      color: Color.fromARGB(
                                                          255, 219, 219, 219),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () async {
                                                        await FirebaseAuthServices()
                                                            .signOut(context);
                                                        Get.off(
                                                            LoginAndSigning());
                                                      },
                                                      child: Text(
                                                        "Yes",
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            color:
                                                                Colors.black),
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
                                                          BorderRadius.circular(
                                                              20),
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
                                                            color:
                                                                Colors.white),
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
        },
      ),
    );
  }
}

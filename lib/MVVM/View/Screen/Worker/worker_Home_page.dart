import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swiftclean_project/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:swiftclean_project/MVVM/View/Screen/Worker/Edit_address.dart';
import 'package:swiftclean_project/MVVM/View/Screen/Worker/check_out_page.dart';
import 'package:swiftclean_project/MVVM/model/services/firebaseauthservices.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';
import 'package:swiftclean_project/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:swiftclean_project/MVVM/utils/widget/containner/shimmer_skeleton.dart';
import 'package:swiftclean_project/main.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  File? _Image;
  final ImagePicker picker = ImagePicker();

  Future<void> pickimage(ImageSource Source) async {
    final PickedFile = await picker.pickImage(source: Source);

    if (PickedFile != null) {
      setState(() {
        _Image = File(PickedFile.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext Context) {
          return SafeArea(
              child: Wrap(
            children: [
              ListTile(
                trailing: Icon(Icons.cancel),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickimage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickimage(ImageSource.camera);
                },
              ),
              if (_Image != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text("Remove Profile Picture"),
                  onTap: () {
                    setState(() {
                      _Image = null;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ));
        });
  }

  Widget _buildConfirmationDialog(String message, VoidCallback onConfirm) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 270,
        width: 374,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: gradientgreen2.c,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.question_mark,
                size: 30,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            Text(
              message,
              style: TextStyle(
                  fontSize: 20,
                  color: Color.fromRGBO(125, 117, 128, 1),
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color.fromARGB(255, 204, 206, 200)),
                    child: TextButton(
                        onPressed: onConfirm,
                        child: Text(
                          "Yes",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: const Color.fromARGB(255, 0, 0, 0)),
                        )),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: gradientgreen2.c),
                    child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "No",
                          style: TextStyle(
                              fontSize: 20,
                              color: const Color.fromRGBO(217, 217, 217, 1)),
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      body: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('workers')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const WorkerProfileSkeleton();
            }

            final data = snapshot.data?.data();

            if (data == null) {
              return Center(
                child: Text('No user found'),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),
                    // Profile Section
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 83,
                              width: 83,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 111, 111, 111))),
                              child: GestureDetector(
                                onTap: _showImagePicker,
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _Image != null
                                      ? FileImage(_Image!)
                                      : null,
                                  child: _Image == null
                                      ? Icon(Icons.person,
                                          size: 44, color: Colors.black)
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: GestureDetector(
                                onTap: _showImagePicker,
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color.fromARGB(
                                            255, 139, 139, 139),
                                        width: 1),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello ${data['username']}",
                              style: TextStyle(
                                  fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Welcome Back !",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    // Service Type
                    Text(
                      data["category"],
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),

                    SizedBox(height: 30),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            elevation: 13,
                            shadowColor: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 136,
                              decoration: BoxDecoration(
                                color: primary.c,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Color.fromRGBO(223, 220, 220, 1)),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: 20),
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            153, 255, 9, 0.25),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Image.asset(
                                      "assets/icons/worker.png",
                                      color: Color.fromRGBO(53, 120, 1, 1),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "0",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Total Work",
                                    style: TextStyle(color: formletters.c),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Material(
                            elevation: 13,
                            shadowColor: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 136,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Color.fromRGBO(223, 220, 220, 1)),
                                  color: primary.c),
                              child: Column(
                                children: [
                                  SizedBox(height: 20),
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            153, 255, 9, 0.25),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child:
                                        Image.asset("assets/icons/money.png"),
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "0",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Total Payment",
                                    style: TextStyle(color: formletters.c),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 44),

                    // Address Card
                    Material(
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 137,
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Color.fromRGBO(223, 220, 220, 1)),
                            color: primary.c),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['phone'],
                                  style:
                                      TextStyle(color: black.c, fontSize: 17),
                                ),
                                GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EditAddress()));
                                    },
                                    child: Image.asset("assets/icons/edit.png"))
                              ],
                            ),
                            SizedBox(height: 15),
                            Expanded(
                              child: Text(
                                "15/24, Rose Villa MG Road, Kochi - 682001 Kerala, India",
                                style: TextStyle(fontSize: 17),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Check out Work Payment
                    Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CheckOutPage()));
                        },
                        child: Container(
                          height: 53,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(221, 227, 227, 227)),
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/icons/clock_payment.png",
                                scale: 15,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Check out Work Payment",
                                style: TextStyle(fontSize: 14),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_forward_ios)
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 27),

                    // Delete Account
                    Material(
                      elevation: 13,
                      shadowColor: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(15),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return _buildConfirmationDialog(
                                    "Are you sure to delete your account?",
                                    () {});
                              });
                        },
                        child: Container(
                          height: 53,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                              color: primary.c,
                              border: Border.all(
                                  color: Color.fromRGBO(223, 220, 220, 1)),
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              Image.asset("assets/icons/delete_user.png"),
                              SizedBox(width: 10),
                              Text(
                                "Delete Account",
                                style: TextStyle(color: black.c),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 47),

                    // Logout
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return _buildConfirmationDialog(
                                    "Are you sure want to logout", () async {
                                  await FirebaseAuthServices().signOut(context);
                                  Get.off(LoginAndSigning());
                                });
                              });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset("assets/icons/Logout_button.png"),
                            SizedBox(width: 5),
                            Text(
                              "Logout",
                              style: TextStyle(color: black.c),
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 50),
                  ],
                ),
              ),
            );
          }),
    );
  }
}

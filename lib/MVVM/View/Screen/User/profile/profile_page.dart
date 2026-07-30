import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:naattulink/MVVM/View/Authentication/LoginandSigning.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/Change_password/changepassword.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/edit_profile.dart';
import 'package:naattulink/MVVM/Viewmodel/themes_bloc.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/containner/custom_image_banner2.dart';
import 'package:naattulink/MVVM/utils/widget/containner/custom_image_banner.dart';
import 'package:naattulink/MVVM/utils/widget/containner/premium_app_background.dart';

class ProfilePage extends StatefulWidget {
  String? username;
  String? createDate;
  String? email;
  String? phone;
  String? image;
  ProfilePage(
      {super.key,
      required this.username,
      required this.createDate,
      required this.email,
      required this.phone,
      required this.image});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkMode = false;
  bool _isNotificationOn = true;

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isEmailUser = user.providerData.any((p) => p.providerId == 'password');

      if (isEmailUser) {
        final password = await _showPasswordPromptDialog();
        if (password == null || password.isEmpty) return; // User cancelled

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // Delete Firestore document first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete Firebase Auth user
      await user.delete();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginAndSigning()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: ${e.toString()}')),
      );
    }
  }

  Future<String?> _showPasswordPromptDialog() async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to confirm account deletion:'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumAppBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: const AppBackButton(),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 180),
              child: Text(
                "Profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const SizedBox(width: 60),
                Text(
                  widget.username ?? 'Guest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfile(
                            username: widget.username ?? '',
                            email: widget.email ?? '',
                            phone: widget.phone ?? '',
                            image: widget.image ?? '',
                          ),
                        ));
                  },
                  child: const Image(
                    image: AssetImage("assets/icons/edit.png"),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 60),
              child: Text(
                'Created: ${widget.createDate}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  color: Color.fromARGB(255, 250, 249, 249),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        // Top banners side by side aligned with other items
                        SizedBox(
                          width: 350,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              CustomImageBanner(),
                              CustomImageBanner2(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Dark Mode toggle
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 50,
                            width: 350,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 232, 232, 232),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 15),
                                const Image(
                                    image:
                                        AssetImage("assets/icons/darkmod.png")),
                                const SizedBox(width: 10),
                                const Text("Dark Mode"),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: BlocBuilder<ThemeBloc, ThemeState>(
                                    builder: (context, state) {
                                      return CupertinoSwitch(
                                        value:
                                            state.themeMode == ThemeMode.dark,
                                        onChanged: (_) {
                                          context
                                              .read<ThemeBloc>()
                                              .add(ToggleThemeEvent());
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notification toggle
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 50,
                            width: 350,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color.fromARGB(255, 232, 232, 232),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    SizedBox(width: 15),
                                    Icon(Icons.notifications),
                                    SizedBox(width: 10),
                                    Text("Notification"),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: CupertinoSwitch(
                                    value: _isNotificationOn,
                                    onChanged: (bool value) {
                                      setState(() {
                                        _isNotificationOn = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Change Password button
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChangePasswordPage()),
                              );
                            },
                            child: Container(
                              height: 50,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 232, 232, 232),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 15),
                                  Image(
                                      image:
                                          AssetImage("assets/icons/lock.png")),
                                  SizedBox(width: 10),
                                  Text("Change Password"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Delete Account button
                        Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: SizedBox(
                                      height: 276,
                                      width: 347,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 40),
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              color: gradientgreen2.c,
                                            ),
                                            child: const Icon(
                                              Icons.question_mark,
                                              size: 35,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Text(
                                              "Are you sure to delete your account ?",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromRGBO(
                                                    125, 117, 128, 1),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    width: 146,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              219,
                                                              219,
                                                              219),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: _deleteAccount,
                                                      child: const Text(
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
                                                  width: 10,
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
                                                      child: const Text(
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 50,
                              width: 350,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      const Color.fromARGB(255, 232, 232, 232),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(width: 15),
                                  Image(
                                      image: AssetImage(
                                          "assets/icons/delete_user.png")),
                                  SizedBox(width: 10),
                                  Text("Delete Account"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

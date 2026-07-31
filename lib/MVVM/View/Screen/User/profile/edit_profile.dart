import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield.dart';

class EditProfile extends StatefulWidget {
  String username;
  String email;
  String phone;
  String image;
  EditProfile(
      {super.key,
      required this.email,
      required this.phone,
      required this.username,
      required this.image});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();

  File? _image;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top indicator
                Container(
                  height: 5,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 186, 185, 185),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Camera & Gallery Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera
                    GestureDetector(
                      onTap: () {
                        pickImage(ImageSource.camera);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child: Image.asset("assets/icons/camera.png",
                                height: 40),
                          ),
                          const SizedBox(height: 8),
                          const Text("Camera"),
                        ],
                      ),
                    ),
                    // Gallery
                    GestureDetector(
                      onTap: () {
                        pickImage(ImageSource.gallery);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child: Image.asset("assets/icons/gallery.png",
                                height: 50),
                          ),
                          const SizedBox(height: 8),
                          const Text("Gallery"),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Cancel Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 232, 232),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 120, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                const SizedBox(height: 10),

                // Remove Image Option
                if (_image != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text("Remove Profile Picture"),
                    onTap: () {
                      setState(() {
                        _image = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String imageUrl = widget.image;

    // if (_image != null) {
    //   final ref = FirebaseStorage.instance
    //       .ref()
    //       .child('profile_images')
    //       .child('$uid.jpg');
    //   await ref.putFile(_image!);
    //   imageUrl = await ref.getDownloadURL();
    // }

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "username": username.text.trim(),
      "phone": "+91${phone.text.trim()}",
      "email": email.text.trim(),
      "profile_img": imageUrl,
      "updated_at": FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    email.text = widget.email;
    phone.text = widget.phone.replaceAll('+91', '').trim();
    username.text = widget.username;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 208, 208, 208),
      body: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 60, left: 180),
            child: Text(
              "Profile",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 10),
            child: AppBackButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  MaterialPageRoute(builder: (context) => user_Dashboard()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 146),
            child: Container(
              height: 750,
              width: 420,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                color: Colors.white,
              ),
              child: const Center(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100, left: 160),
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(),
                color: const Color.fromARGB(255, 227, 227, 227),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white,
                      backgroundImage: _image == null
                          ? NetworkImage(widget.image ?? '')
                          : _image != null
                              ? FileImage(_image!)
                              : null,
                      child: _image == null
                          ? const Icon(Icons.person,
                              size: 44, color: Colors.black)
                          : Image.file(_image!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 210, left: 25),
            child: Text(
              "User name",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(126, 126, 126, 1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 230, left: 30),
            child: Customformfield(
                color: Colors.white,
                hinttext: "Enter your Username",
                controller: username,
                hintstyle:
                    TextStyle(color: const Color.fromARGB(255, 156, 156, 156))),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 280, left: 25),
            child: Text(
              "Email",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(126, 126, 126, 1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 300, left: 30),
            child: Customformfield(
                color: Colors.white,
                controller: email,
                hinttext: "Enter your email",
                hintstyle:
                    TextStyle(color: const Color.fromARGB(255, 156, 156, 156))),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 355, left: 25),
            child: Text(
              "Phone",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(126, 126, 126, 1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 380, left: 30),
            child: Customformfield(
                color: Colors.white,
                hinttext: "00000 00000",
                controller: phone,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                    return 'Invalid 10-digit Indian mobile number';
                  }
                  return null;
                },
                hintstyle:
                    TextStyle(color: const Color.fromARGB(255, 156, 156, 156))),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 690),
              child: SizedBox(
                height: 46,
                width: 350,
                child: Custombutton(
                    text: Text(
                      "Update",
                      style: TextStyle(color: Colors.white),
                    ),
                    onpress: _updateProfile),
              ),
            ),
          )
        ],
      ),
    );
  }
}

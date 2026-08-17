import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield2.dart';

class EditAddress extends StatefulWidget {
  const EditAddress({super.key});

  @override
  State<EditAddress> createState() => _EditAddressState();
}

class _EditAddressState extends State<EditAddress> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 102, 214, 10),
                  Color.fromARGB(255, 113, 191, 4),
                  Color.fromARGB(255, 26, 159, 6),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 30),
                const Text(
                  '"Edit Address"',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Form(
          key: formkey,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(15),
                  child: Customformfield2(
                    keyboardtype: TextInputType.phone,
                    hight: 55,
                    width: 370,
                    color: primary.c,
                    hinttext: "00000 00000",
                    hintstyle:
                        TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                    controller: phoneController,
                    prefixText: '+91 ',
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your Phone Number";
                      } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                        return "Enter a valid 10-digit Indian mobile number";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: 370,
                    child: Customformfield2(
                      maxline: 15,
                      keyboardtype: TextInputType.streetAddress,
                      hight: 100,
                      color: primary.c,
                      hinttext: "Enter your Address",
                      hintstyle:
                          TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                      controller: addressController,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your Address";
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40, left: 120),
                    child: Container(
                      height: 45,
                      width: 119,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 226, 27, 12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          phoneController.clear();
                          addressController.clear();
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40, left: 30),
                    child: SizedBox(
                      height: 45,
                      width: 119,
                      child: Custombutton(
                        text: Text(
                          "Save",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        onpress: () {
                          if (formkey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Saved:\nPhone: ${phoneController.text}\nAddress: ${addressController.text}",
                                ),
                                backgroundColor: Colors.white,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

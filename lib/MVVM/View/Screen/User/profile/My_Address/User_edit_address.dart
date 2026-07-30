import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/My_Address/address_page.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';
import 'package:naattulink/MVVM/utils/widget/formfield/customformfield2.dart';

class userEditAddress extends StatelessWidget {
  const userEditAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 20), // general horizontal padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  AppBackButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddressPage()),
                      );
                    },
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  Text(
                    "My Address",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Customformfield2(
                    maxline: 15,
                    keyboardtype: TextInputType.streetAddress,
                    hight: 100,
                    color: primary.c,
                    hinttext: "Enter your Address",
                    hintstyle:
                        TextStyle(color: Color.fromRGBO(153, 153, 153, 1)),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your Address";
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 45,
                      width: 119,
                      child: Custombutton(
                        text: Text(
                          "Update",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        onpress: () {
                          // Add your update logic here
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // some bottom spacing
            ],
          ),
        ),
      ),
    );
  }
}

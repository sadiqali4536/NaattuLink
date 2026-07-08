import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/profile/My_Address/User_edit_address.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';
import 'package:naattulink/MVVM/utils/widget/card/addresscard.dart';

class AddressPage extends StatelessWidget {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  customBackbutton1(
                    onpress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => user_Dashboard()),
                      );
                    },
                  ),
                  SizedBox(
                    width: 75,
                  ),
                  Text(
                    "My Address",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 370,
                height: 160,
                child: Addresscard(
                  address:
                      "15/24, Rose Villa\nMG Road, Kochi - 682001\nKerala, India",
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => userEditAddress()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

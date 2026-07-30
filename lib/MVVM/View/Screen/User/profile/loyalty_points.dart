import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/View/Screen/User/User_Dashboard/user_Dashboard.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/app_back_button.dart';
import 'package:naattulink/MVVM/utils/widget/button/custombutton.dart';

class LoyaltyPoints extends StatelessWidget {
  const LoyaltyPoints({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 246, 246),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title row
              Row(
                children: [
                  AppBackButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => user_Dashboard()),
                      );
                    },
                  ),
                  const SizedBox(width: 50),
                  const Text(
                    "Loyality Points",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Card with points info
              Center(
                child: Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 50,
                          left: 150,
                          child: Text(
                            "Convertible Points !",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        Positioned(
                          top: 60,
                          left: 60,
                          child: SizedBox(
                            height: 70,
                            width: 70,
                            child:
                                Image.asset("assets/icons/loyality_point.png"),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: 150,
                          child: Text(
                            "0",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Point History title
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  "Point History",
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 30),

              // No data image
              Center(
                child: Image.asset(
                  "assets/icons/no_data_found.png",
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 60),

              Center(
                child: SizedBox(
                  height: 54,
                  width: 303,
                  child: Custombutton(
                    text: const Text(
                      "Convert to Booking",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    onpress: () {},
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

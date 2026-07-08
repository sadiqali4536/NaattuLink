import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';

class customBackbutton1 extends StatelessWidget {
  final VoidCallback onpress;

  const customBackbutton1({super.key, required this.onpress});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(40),
      shadowColor: Colors.black.withOpacity(0.8),
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
            color: primary.c,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Color.fromRGBO(217, 216, 216, 1))),
        child: IconButton(
          onPressed: onpress,
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: const Color.fromARGB(255, 3, 3, 3)),
        ),
      ),
    );
  }
}

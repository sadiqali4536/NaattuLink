import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';
import 'package:toggle_switch/toggle_switch.dart';

class CustomToggleButton extends StatefulWidget {
  const CustomToggleButton({super.key});

  @override
  State<CustomToggleButton> createState() => _CustomToggleButtonState();
}

class _CustomToggleButtonState extends State<CustomToggleButton> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        elevation: 15,
        borderRadius: BorderRadius.circular(30),
        child: ToggleSwitch(
          borderColor: [const Color.fromARGB(255, 248, 246, 246)],
          minWidth: 120.0,
          minHeight: 45,
          cornerRadius: 30.0,
          activeBgColors: [
            [Color.fromARGB(255, 56, 122, 2)],
            [Color.fromARGB(255, 56, 122, 2)],
          ],
          activeFgColor: primary.c,
          inactiveBgColor: primary.c,
          inactiveFgColor: black.c,
          initialLabelIndex: selectedIndex,
          totalSwitches: 2,
          labels: ['User', 'Worker'],
          fontSize: 18,
          radiusStyle: true,
          onToggle: (index) {
            setState(() {
              selectedIndex = index!;
            });
          },
        ),
      ),
    );
  }
}

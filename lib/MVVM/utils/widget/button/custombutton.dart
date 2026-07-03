import 'package:flutter/material.dart';
import 'package:swiftclean_project/MVVM/utils/Constants/colors.dart';

class Custombutton extends StatelessWidget {
  final VoidCallback onpress;
  final Widget text;
  final Color? color;
  final List<Color>? gradientColors;
  final double? borderRadius;

  const Custombutton({
    super.key,
    required this.text,
    required this.onpress,
    this.color,
    this.gradientColors,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 40.0;
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: color == null
            ? LinearGradient(
                colors: gradientColors ?? [
                  gradientgreen1.c,
                  gradientgreen2.c,
                  gradientgreen3.c,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: onpress,
        child: text,
      ),
    );
  }
}

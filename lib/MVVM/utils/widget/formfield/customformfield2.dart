import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';

class Customformfield2 extends StatelessWidget {
  final TextInputType? keyboardtype;
  final double hight;
  final double? width;
  final Color color;
  final String hinttext;
  final TextStyle hintstyle;
  final String? helpertext;
  final Widget? prefixicon;
  final Widget? suffixicon;
  final Widget? icon;
  final TextEditingController? controller;
  final Function()? suffix;
  final String? Function(String?)? validator;
  final int? maxline;

  const Customformfield2({
    super.key,
    required this.color,
    required this.hinttext,
    required this.hintstyle,
    this.helpertext,
    this.prefixicon,
    this.suffixicon,
    this.icon,
    this.suffix,
    this.validator,
    this.controller,
    required this.hight,
    this.keyboardtype,
    this.width,
    this.maxline,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hight,
      width: width,
      child: TextFormField(
        maxLines: maxline,
        keyboardType: keyboardtype,
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: formfield.c),
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: formfield.c),
            borderRadius: BorderRadius.circular(15),
          ),
          fillColor: color,
          filled: true,
          hintText: hinttext,
          hintStyle: hintstyle,
          helperText: helpertext,
          prefixIcon: prefixicon,
          suffixIcon: suffixicon,
        ),
      ),
    );
  }
}

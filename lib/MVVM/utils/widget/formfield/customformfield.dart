import 'package:flutter/material.dart';

class Customformfield extends StatefulWidget {
  final Color color;
  final String hinttext;
  final TextStyle hintstyle;
  final String? helpertext;
  final Widget? prefixicon;
  final Widget? suffixicon;
  final Widget? icon;
  final Function()? suffix;
  final TextEditingController? controller;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final Color? borderColor;
  final double? borderRadius;

  const Customformfield({
    super.key,
    required this.color,
    required this.hinttext,
    required this.hintstyle,
    this.helpertext,
    this.prefixicon,
    this.suffixicon,
    this.icon,
    this.suffix,
    this.controller,
    this.obscureText = false,
    this.validator,
    this.borderColor,
    this.borderRadius,
  });

  @override
  State<Customformfield> createState() => _CustomformfieldState();
}

class _CustomformfieldState extends State<Customformfield> {
  bool _obscureText = true; 

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant Customformfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? 50.0;
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText, 
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderSide: widget.borderColor != null
              ? BorderSide(color: widget.borderColor!, width: 1)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(radius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: widget.borderColor != null
              ? BorderSide(color: widget.borderColor!, width: 1)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(radius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.blue,
            width: widget.borderColor != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        fillColor: widget.color,
        filled: true,
        hintText: widget.hinttext,
        hintStyle: widget.hintstyle,
        helperText: widget.helpertext,
        prefixIcon: widget.prefixicon,
        suffixIcon: widget.suffixicon ?? (widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color.fromRGBO(144, 144, 144, 1),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null),     
      ),
    );
  }
}

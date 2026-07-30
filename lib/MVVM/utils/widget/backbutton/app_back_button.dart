import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry margin;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.margin = const EdgeInsets.only(left: 16, top: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        shadowColor: Colors.black.withOpacity(0.1),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed ??
              () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Get.back();
                }
              },
          child: Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color.fromRGBO(230, 230, 230, 1)),
            ),
            child: const Center(
              child: Padding(
                padding:
                    EdgeInsets.only(right: 2.0), // Visually center the chevron
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Color(0xFF0F2E5A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

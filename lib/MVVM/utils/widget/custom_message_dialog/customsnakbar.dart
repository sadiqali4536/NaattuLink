import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/animation_widget/tickmark.dart';

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    Color color = Colors.black,
    Color iconcolor = Colors.black,
    Widget? leadingWidget,
    IconData icon = Icons.info_outline,
    bool useTick = false,
  }) {
    if (context.mounted) {
      Flushbar(
        messageText: Text(
          message,
          style: const TextStyle(color: Colors.black, fontSize: 15),
        ),
        icon: leadingWidget ??
            (useTick
                ? const SizedBox(width: 32, height: 32, child: Tickmark())
                : Icon(icon, color: iconcolor, size: 24)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: BorderRadius.circular(12),
        flushbarPosition: FlushbarPosition.TOP,
        isDismissible: true,
      ).show(context);
    }
  }
}

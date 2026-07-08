import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';

class Custdropdown extends StatelessWidget {
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onchanged;
  final String? selectedValue;

  const Custdropdown(
      {super.key,
      required this.items,
      this.hint = "Select an options",
      required this.onchanged,
      this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      borderRadius: BorderRadius.circular(30),
      value: selectedValue,
      decoration: InputDecoration(
          fillColor: formfield.c,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          )),
      hint: Text(hint),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onchanged,
    );
  }
}

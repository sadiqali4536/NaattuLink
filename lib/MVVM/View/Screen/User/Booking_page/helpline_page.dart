import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';

class HelplinePage extends StatefulWidget {
  const HelplinePage({Key? key}) : super(key: key);

  @override
  State<HelplinePage> createState() => _HelplinePageState();
}

class _HelplinePageState extends State<HelplinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: customBackbutton1(onpress: () => Navigator.pop(context)),
        ),
        centerTitle: true,
        title: const Text(
          "Helpline",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Helpline Numbers coming soon...",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

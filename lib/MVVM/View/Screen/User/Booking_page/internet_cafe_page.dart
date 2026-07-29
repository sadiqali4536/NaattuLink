import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/widget/backbutton/custombackbutton.dart';

class InternetCafePage extends StatefulWidget {
  const InternetCafePage({Key? key}) : super(key: key);

  @override
  State<InternetCafePage> createState() => _InternetCafePageState();
}

class _InternetCafePageState extends State<InternetCafePage> {
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
          "Internet Cafe",
          style: TextStyle(
            color: Color(0xFF0F2E5A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Internet Cafe Listings coming soon...",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

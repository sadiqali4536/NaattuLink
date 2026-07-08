import 'package:flutter/material.dart';
import 'package:naattulink/MVVM/utils/Constants/colors.dart';

class Tickmark extends StatefulWidget {
  const Tickmark({super.key});

  @override
  State<Tickmark> createState() => _TickmarkState();
}

class _TickmarkState extends State<Tickmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleanimation;
  late Animation<double> _opacityanimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleanimation = Tween<double>(begin: 0.0, end: 1.4)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);

    _opacityanimation =
        Tween<double>(begin: 0.0, end: 1.70).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleanimation,
      child: FadeTransition(
        opacity: _opacityanimation,
        child: const Icon(
          Icons.check_circle,
          color: gradientgreen2.c,
          size: 20,
        ),
      ),
    );
  }
}

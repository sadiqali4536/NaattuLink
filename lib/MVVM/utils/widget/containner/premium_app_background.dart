import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumAppBackground extends StatelessWidget {
  final Widget child;

  const PremiumAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF), // Pure white
            Color.fromARGB(
                255, 251, 250, 245), // Soft warm cream/light gold tint
            Color.fromARGB(255, 251, 247, 240), // Soft pale yellow/gold
            Color(0xFFFFFFFF), // Back to pure white
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PremiumBackgroundPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class PremiumBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw a soft glowing radial gradient in the top-right corner (light gold/yellow)
    final yellowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB800).withOpacity(0.08),
          const Color(0xFFFFB800).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.15),
        radius: size.width * 0.65,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), yellowPaint);

    // 2. Draw a soft glowing radial gradient in the middle-left corner (light blue)
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color.fromARGB(255, 136, 183, 204).withOpacity(0.05),
          const Color.fromARGB(255, 142, 183, 202).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.15, size.height * 0.55),
        radius: size.width * 0.75,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bluePaint);

    // 3. Draw extremely subtle city skyline and tree vector outlines at the bottom
    final outlinePaint = Paint()
      ..color = const Color(0xFF0F2E5A)
          .withOpacity(0.06) // Faint but clearly visible watermark opacity (6%)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double h = size.height;
    final double w = size.width;

    // Minimalist house outlines at the bottom
    // House 1
    path.moveTo(w * 0.06, h);
    path.lineTo(w * 0.06, h - 55);
    path.lineTo(w * 0.13, h - 80); // Roof peak
    path.lineTo(w * 0.20, h - 55);
    path.lineTo(w * 0.20, h);

    // House 1 Details (Door)
    path.moveTo(w * 0.11, h);
    path.lineTo(w * 0.11, h - 30);
    path.lineTo(w * 0.15, h - 30);
    path.lineTo(w * 0.15, h);

    // Minimal tree outline next to house
    path.addOval(Rect.fromCircle(center: Offset(w * 0.26, h - 45), radius: 20));
    path.moveTo(w * 0.26, h);
    path.lineTo(w * 0.26, h - 25);

    // Skyline shapes
    path.moveTo(w * 0.35, h);
    path.lineTo(w * 0.35, h - 100);
    path.lineTo(w * 0.48, h - 100);
    path.lineTo(w * 0.48, h - 35);
    path.lineTo(w * 0.56, h - 35);
    path.lineTo(w * 0.63, h - 75);
    path.lineTo(w * 0.70, h - 35);
    path.lineTo(w * 0.70, h);

    // Minimal tree outline on the right
    path.addOval(Rect.fromCircle(center: Offset(w * 0.81, h - 60), radius: 18));
    path.addOval(Rect.fromCircle(center: Offset(w * 0.85, h - 45), radius: 22));
    path.moveTo(w * 0.83, h);
    path.lineTo(w * 0.83, h - 25);

    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

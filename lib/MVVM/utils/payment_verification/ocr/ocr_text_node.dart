import 'dart:ui';

class OcrTextNode {
  final String text;
  final Rect boundingBox;
  final int blockIndex;
  final int lineIndex;
  final double? confidence;

  const OcrTextNode({
    required this.text,
    required this.boundingBox,
    required this.blockIndex,
    required this.lineIndex,
    this.confidence,
  });

  double get left => boundingBox.left;
  double get right => boundingBox.right;
  double get top => boundingBox.top;
  double get bottom => boundingBox.bottom;

  double get centerX => boundingBox.center.dx;
  double get centerY => boundingBox.center.dy;

  double get height => boundingBox.height;
  double get width => boundingBox.width;
}

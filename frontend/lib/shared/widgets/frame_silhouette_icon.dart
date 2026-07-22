import 'package:flutter/material.dart';

/// Circular silhouette that matches the round avatar frames in the store.
class FrameSilhouetteIcon extends StatelessWidget {
  const FrameSilhouetteIcon({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FrameSilhouettePainter(color: color),
      ),
    );
  }
}

class _FrameSilhouettePainter extends CustomPainter {
  const _FrameSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer ring (main frame border).
    stroke.strokeWidth = size.width * 0.1;
    canvas.drawCircle(center, size.width * 0.38, stroke);

    // Inner ring (photo opening).
    stroke.strokeWidth = size.width * 0.07;
    canvas.drawCircle(center, size.width * 0.26, stroke);

    // Soft accent bumps like ears / crown ornaments on round frames.
    final accent = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bumpRadius = size.width * 0.07;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.22, center.dy - size.height * 0.3),
      bumpRadius,
      accent,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.22, center.dy - size.height * 0.3),
      bumpRadius,
      accent,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.38),
      size.width * 0.055,
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant _FrameSilhouettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

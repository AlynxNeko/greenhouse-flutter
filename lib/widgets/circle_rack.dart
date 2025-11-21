import 'dart:math';
import 'package:flutter/material.dart';

class CircleRack extends StatelessWidget {
  final int current;
  const CircleRack({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RackPainter(current),
      size: Size(250, 250),
    );
  }
}

class RackPainter extends CustomPainter {
  final int current;
  RackPainter(this.current);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..strokeWidth = 2
      ..color = Colors.white
      ..style = PaintingStyle.stroke;

    final center = Offset(s.width/2, s.height/2);
    final radius = s.width/2 - 10;

    c.drawCircle(center, radius, p);

    for (int i = 0; i < 8; i++) {
      final ang = (i * 45) * pi / 180;
      final x = center.dx + radius * cos(ang);
      final y = center.dy + radius * sin(ang);
      c.drawLine(center, Offset(x, y), p);

      TextPainter(
        text: TextSpan(
          text: "${i+1}",
          style: TextStyle(
            fontSize: 18,
            color: (i+1 == current) ? Colors.red : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(
          c,
          Offset(
            center.dx + (radius - 25) * cos(ang),
            center.dy + (radius - 25) * sin(ang),
          ),
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

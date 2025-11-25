import 'dart:math';
import 'package:flutter/material.dart';

class CircleRack extends StatelessWidget {
  final double angleDegrees; // Exact angle from ESP32
  final int activeRack;      // Current "Logic" Rack (1-8)

  const CircleRack({
    super.key, 
    required this.angleDegrees, 
    required this.activeRack
  });

  @override
  Widget build(BuildContext context) {
    // Convert degrees to radians for Canvas rotation
    final double angleRad = (angleDegrees * pi) / 180;

    return Column(
      children: [
        Text(
          "Angle: ${angleDegrees.toStringAsFixed(1)}°", 
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 10),
        CustomPaint(
          painter: RackPainter(angleRad, activeRack),
          size: const Size(250, 250),
        ),
      ],
    );
  }
}

class RackPainter extends CustomPainter {
  final double rotation;
  final int activeRack;
  
  RackPainter(this.rotation, this.activeRack);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final radius = s.width / 2 - 10;

    final paintCircle = Paint()
      ..color = Colors.greenAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintLine = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // 1. Draw Static Outer Ring (Fixed Frame)
    c.drawCircle(center, radius + 5, paintCircle);

    // 2. Rotate the Canvas for the "Inner Wheel"
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rotation); // <--- Dynamic Rotation
    c.translate(-center.dx, -center.dy);

    // Draw Inner Wheel contents
    for (int i = 0; i < 8; i++) {
      // 8 Slots, 45 degrees each
      final double slotAngle = (i * 45) * pi / 180; 
      final x = center.dx + radius * cos(slotAngle);
      final y = center.dy + radius * sin(slotAngle);

      // Draw Spoke
      c.drawLine(center, Offset(x, y), paintLine);

      // Draw Number (Counter-rotate text so it stays upright?)
      // For simplicity, we just draw it rotated with the wheel for now.
      final textOffset = Offset(
        center.dx + (radius * 0.7) * cos(slotAngle),
        center.dy + (radius * 0.7) * sin(slotAngle),
      );

      _drawText(c, "${i + 1}", textOffset, (i + 1) == activeRack);
    }
    
    // Draw a small marker for "Slot 1" physical position
    c.drawCircle(
      Offset(center.dx + radius, center.dy), 
      5, 
      Paint()..color = Colors.red
    );

    c.restore(); // Restore rotation for static elements

    // 3. Draw "Front" Indicator (Static Arrow at top or right)
    // Assuming "Front" is at 0 degrees (Right side)
    final paintIndicator = Paint()..color = Colors.yellow;
    c.drawPath(
      Path()
        ..moveTo(center.dx + radius + 10, center.dy)
        ..lineTo(center.dx + radius + 20, center.dy - 5)
        ..lineTo(center.dx + radius + 20, center.dy + 5)
        ..close(),
      paintIndicator
    );
  }

  void _drawText(Canvas c, String text, Offset pos, bool isActive) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: isActive ? Colors.greenAccent : Colors.white,
        fontSize: isActive ? 22 : 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant RackPainter old) => old.rotation != rotation;
}
import 'package:flutter/material.dart';

class CalculatorAnswerPauseGlow extends StatelessWidget {
  final Color? color;

  const CalculatorAnswerPauseGlow({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnswerPauseGlowPainter(color),
      child: const SizedBox.expand(),
    );
  }
}

class _AnswerPauseGlowPainter extends CustomPainter {
  final Color? color;

  const _AnswerPauseGlowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final glowColor = color;
    if (glowColor == null) return;

    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    ).deflate(12);

    canvas.drawRRect(
      outline,
      Paint()
        ..color = glowColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawRRect(
      outline,
      Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(covariant _AnswerPauseGlowPainter oldDelegate) =>
      oldDelegate.color != color;
}

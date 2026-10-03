import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Deepwork's mark: a focus ring with a progress arc.
class DeepworkMark extends StatelessWidget {
  const DeepworkMark({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(size * 0.28)),
      child: CustomPaint(painter: _MarkPainter(p.onAccent)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 8.5 / 32;
    final w = size.width * 2.6 / 32;
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = color.withValues(alpha: 0.35));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, math.pi / 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = color);
    canvas.drawCircle(c, size.width * 2.4 / 32, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum RingStatus { active, paused, complete, interrupted, breakTime }

/// Large circular progress ring around the timer. Glows softly and intensifies as the session
/// progresses; pulses once on completion; fades to grey when a session ends early.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.status,
    required this.style,
    required this.glow,
    required this.completionAnimation,
    required this.child,
    this.size,
  });

  final double progress;
  final RingStatus status;
  final String style; // thin | bold | segmented
  final bool glow, completionAnimation;
  final Widget child;
  final double? size;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.status == RingStatus.complete && widget.completionAnimation) _pulse.forward();
  }

  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    if (widget.status == RingStatus.complete && old.status != RingStatus.complete && widget.completionAnimation && !context.reduceMotion) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final target = switch (widget.status) {
      RingStatus.interrupted => p.muted,
      RingStatus.breakTime => p.success,
      _ => p.accent,
    };
    final size = widget.size ?? math.min(MediaQuery.sizeOf(context).width * 0.8, math.min(360.0, MediaQuery.sizeOf(context).height * 0.46));
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: target),
      duration: const Duration(milliseconds: 800),
      builder: (context, color, _) => AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          final scale = 1 + 0.045 * math.sin(t * math.pi);
          return SizedBox(
            width: size,
            height: size,
            child: Stack(alignment: Alignment.center, children: [
              Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _RingPainter(
                    progress: widget.progress.clamp(0, 1),
                    color: color ?? target,
                    track: p.border,
                    style: widget.style,
                    glow: widget.glow && widget.status != RingStatus.interrupted,
                    dim: widget.status == RingStatus.interrupted ? 0.5 : widget.status == RingStatus.paused ? 0.7 : 1,
                  ),
                ),
              ),
              // Expanding ring on completion.
              if (_pulse.isAnimating || (t > 0 && t < 1))
                Opacity(
                  opacity: (1 - t) * 0.7,
                  child: Container(
                    width: size * (0.86 + 0.3 * t),
                    height: size * (0.86 + 0.3 * t),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: (color ?? target), width: 2)),
                  ),
                ),
              widget.child,
            ]),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track, required this.style, required this.glow, required this.dim});
  final double progress, dim;
  final Color color, track;
  final String style;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = style == 'thin' ? 4.0 : style == 'bold' ? 14.0 : 12.0;
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 24;
    final rect = Rect.fromCircle(center: center, radius: r);
    final c = color.withValues(alpha: dim);

    // Soft ambient glow behind the ring, intensifying with progress.
    if (glow) {
      final bg = Paint()
        ..shader = RadialGradient(colors: [c.withValues(alpha: 0.05 + 0.18 * progress), c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: center, radius: r * 1.15));
      canvas.drawCircle(center, r * 1.15, bg);
    }

    if (style == 'segmented') {
      const n = 60;
      const gap = 0.9 * math.pi / 180;
      final filled = progress * n;
      for (var i = 0; i < n; i++) {
        final a0 = -math.pi / 2 + i * 2 * math.pi / n + gap / 2;
        final sweep = 2 * math.pi / n - gap;
        canvas.drawArc(rect, a0, sweep, false, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track.withValues(alpha: 0.8));
        final f = (filled - i).clamp(0.0, 1.0);
        if (f > 0) {
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..color = c.withValues(alpha: dim * (0.35 + 0.65 * f));
          if (glow) {
            canvas.drawArc(rect, a0, sweep, false, Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..color = c.withValues(alpha: 0.35 + 0.4 * progress)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 14 * progress));
          }
          canvas.drawArc(rect, a0, sweep, false, paint);
        }
      }
      return;
    }

    canvas.drawCircle(center, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track.withValues(alpha: 0.8));
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    if (glow) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 2
        ..strokeCap = StrokeCap.round
        ..color = c.withValues(alpha: 0.3 + 0.45 * progress)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + 18 * progress));
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.style != style || old.glow != glow || old.dim != dim || old.track != track;
}

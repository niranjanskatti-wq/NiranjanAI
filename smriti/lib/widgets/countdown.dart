import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/util/occurrence.dart';

/// Live days : hours : minutes : seconds until local midnight of [target].
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.target, this.compact = false});

  final Day target;
  final bool compact;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = widget.target.asDateTime.difference(DateTime.now());
    setState(() => _left = left.isNegative ? Duration.zero : left);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _left.inSeconds;
    final parts = [
      (s ~/ 86400, 'Days'),
      (s % 86400 ~/ 3600, 'Hrs'),
      (s % 3600 ~/ 60, 'Min'),
      (s % 60, 'Sec'),
    ];
    return Semantics(
      label: '${parts[0].$1} days, ${parts[1].$1} hours, ${parts[2].$1} minutes left',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) SizedBox(width: widget.compact ? 6 : 8),
            Expanded(child: _Cell(value: parts[i].$1, label: parts[i].$2, compact: widget.compact)),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label, required this.compact});

  final int value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = value.toString().padLeft(2, '0');
    final reduce = MediaQuery.of(context).disableAnimations;
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 9),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRect(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (var i = 0; i < text.length; i++) _Digit(char: text[i], compact: compact, animate: !reduce)],
            ),
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontFamily: sans, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: c.muted)),
        ],
      ),
    );
  }
}

/// One digit that slides and fades when it changes (a soft "flip").
class _Digit extends StatelessWidget {
  const _Digit({required this.char, required this.compact, required this.animate});

  final String char;
  final bool compact, animate;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: sans,
      fontSize: compact ? 22 : 30,
      fontWeight: FontWeight.w600,
      height: 1.1,
      color: context.c.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final digit = Text(char, key: ValueKey(char), style: style);
    if (!animate) return digit;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final incoming = child.key == ValueKey(char);
        final offset = Tween<Offset>(
          begin: incoming ? const Offset(0, -0.6) : const Offset(0, 0.6),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(opacity: anim, child: SlideTransition(position: offset, child: child));
      },
      layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: digit,
    );
  }
}

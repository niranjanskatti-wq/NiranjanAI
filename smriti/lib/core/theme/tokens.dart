import 'package:flutter/material.dart';

import '../../data/enums.dart';

/// Design tokens from the approved design review (docs/design-review.html).
class SmritiColors extends ThemeExtension<SmritiColors> {
  const SmritiColors({
    required this.bg,
    required this.surface,
    required this.raised,
    required this.text,
    required this.muted,
    required this.line,
    required this.gold,
    required this.goldText,
    required this.onGold,
    required this.call,
    required this.alert,
    required this.shadow,
  });

  final Color bg, surface, raised, text, muted, line, gold, goldText, onGold, call, alert;
  final List<BoxShadow> shadow;

  static const dark = SmritiColors(
    bg: Color(0xFF121214),
    surface: Color(0xFF1C1B20),
    raised: Color(0xFF27262C),
    text: Color(0xFFF4EFE4),
    muted: Color(0xFFA8A294),
    line: Color(0xFF34323A),
    gold: Color(0xFFD6B26E),
    goldText: Color(0xFFE2C27F),
    onGold: Color(0xFF1A1408),
    call: Color(0xFF5CC08F),
    alert: Color(0xFFE88A73),
    shadow: [BoxShadow(color: Color(0x73000000), blurRadius: 30, offset: Offset(0, 10))],
  );

  static const light = SmritiColors(
    bg: Color(0xFFFAF7F0),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFF1ECE1),
    text: Color(0xFF1C1B1F),
    muted: Color(0xFF6E685D),
    line: Color(0xFFE4DDCF),
    gold: Color(0xFFC9A45C),
    goldText: Color(0xFF8A6A2B),
    onGold: Color(0xFF1A1408),
    call: Color(0xFF2F8A5E),
    alert: Color(0xFFB4452F),
    shadow: [BoxShadow(color: Color(0x1A3C2D14), blurRadius: 24, offset: Offset(0, 8))],
  );

  @override
  SmritiColors copyWith() => this;

  @override
  SmritiColors lerp(SmritiColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

/// Event-type colours: calendar dots, list icons and rings.
Color groupColor(EventGroup g) => switch (g) {
      EventGroup.birthday => const Color(0xFFD4789A),
      EventGroup.anniversary => const Color(0xFFC9A45C),
      EventGroup.festival => const Color(0xFFE0892E),
      EventGroup.important => const Color(0xFF5E86B8),
      EventGroup.other => const Color(0xFF6E9E7A),
    };

/// Warm gradients for photo-less avatars, picked by name so they stay stable.
const avatarGradients = [
  [Color(0xFFE9CF97), Color(0xFFB98D45)],
  [Color(0xFFEBB7C6), Color(0xFFC0718C)],
  [Color(0xFFB8CBE3), Color(0xFF6F8FB8)],
  [Color(0xFFF2C48E), Color(0xFFD27E2B)],
  [Color(0xFFBFD8C4), Color(0xFF6E9E7A)],
];

class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0, xxxl = 48.0;
}

class Radii {
  static const chip = 8.0, button = 14.0, card = 20.0, sheet = 28.0;
}

const serif = 'Cormorant';
const sans = 'Manrope';

/// Hindi and Kannada fall back to Noto so messages render offline.
const fontFallback = ['NotoDevanagari', 'NotoKannada'];

extension SmritiContext on BuildContext {
  SmritiColors get c => Theme.of(this).extension<SmritiColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

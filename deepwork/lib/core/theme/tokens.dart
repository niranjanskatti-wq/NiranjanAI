import 'package:flutter/material.dart';

/// Design tokens. Dark palette by default, a polished light palette, and an accent that can be changed.
class Palette {
  const Palette({
    required this.bg,
    required this.card,
    required this.card2,
    required this.border,
    required this.fg,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.isDark,
  });

  final Color bg, card, card2, border, fg, muted, accent, onAccent, success, warning, danger;
  final bool isDark;

  Color get accentSoft => accent.withValues(alpha: isDark ? 0.16 : 0.12);

  static Palette dark(Color accent) => Palette(
        bg: const Color(0xFF0B0B0F),
        card: const Color(0xFF15151C),
        card2: const Color(0xFF1C1C25),
        border: const Color(0xFF24242E),
        fg: const Color(0xFFEDEDF2),
        muted: const Color(0xFF8A8A99),
        accent: accent,
        onAccent: onColor(accent),
        success: const Color(0xFF4ADE80),
        warning: const Color(0xFFFBBF24),
        danger: const Color(0xFFF87171),
        isDark: true,
      );

  static Palette light(Color accent) => Palette(
        bg: const Color(0xFFFAFAFB),
        card: const Color(0xFFFFFFFF),
        card2: const Color(0xFFF3F3F6),
        border: const Color(0xFFE7E7EC),
        fg: const Color(0xFF111118),
        muted: const Color(0xFF6B6B7B),
        accent: accent,
        onAccent: onColor(accent),
        success: const Color(0xFF16A34A),
        warning: const Color(0xFFD97706),
        danger: const Color(0xFFE5484D),
        isDark: false,
      );
}

Color onColor(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF0B0B0F) : Colors.white;

Color parseHex(String hex, [Color fallback = const Color(0xFF7C7CFF)]) {
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  final v = int.tryParse(h, radix: 16);
  if (v == null || h.length != 6) return fallback;
  return Color(0xFF000000 | v);
}

String toHex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

const radiusCard = 16.0;
const radiusButton = 12.0;

/// Palette lookup from anywhere below the app's Theme.
extension PaletteX on BuildContext {
  Palette get pal => Theme.of(this).extension<PaletteExt>()!.palette;
  AppDensity get density => Theme.of(this).extension<PaletteExt>()!.density;
  bool get reduceMotion => Theme.of(this).extension<PaletteExt>()!.reduceMotion;
}

class AppDensity {
  const AppDensity(this.compact);
  final bool compact;
  double get pad => compact ? 14 : 20;
  double get gap => compact ? 10 : 16;
}

class PaletteExt extends ThemeExtension<PaletteExt> {
  const PaletteExt(this.palette, this.density, this.reduceMotion);
  final Palette palette;
  final AppDensity density;
  final bool reduceMotion;

  @override
  PaletteExt copyWith() => this;

  @override
  PaletteExt lerp(ThemeExtension<PaletteExt>? other, double t) => other is PaletteExt && t > 0.5 ? other : this;
}

/// Tabular figures for timers and stats.
const tabular = [FontFeature.tabularFigures()];

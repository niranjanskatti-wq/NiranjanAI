import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings.dart';
import 'tokens.dart';

ThemeData buildTheme(AppSettings s, Brightness brightness, {required bool systemReduceMotion}) {
  final accent = parseHex(s.s('appearance.accent'));
  final p = brightness == Brightness.dark ? Palette.dark(accent) : Palette.light(accent);
  final family = switch (s.s('appearance.font')) { 'geist' => 'Geist', 'serif' => 'SourceSerif', _ => 'Inter' };
  final animations = s.s('appearance.animations');
  final reduce = animations != 'full' || systemReduceMotion;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: family,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.danger,
      onError: Colors.white,
      surface: p.card,
      onSurface: p.fg,
      surfaceContainerHighest: p.card2,
      outline: p.border,
      outlineVariant: p.border,
    ),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: reduce ? const _FadeOnlyTransitions() : const FadeForwardsPageTransitionsBuilder(),
    }),
  );

  final text = base.textTheme.apply(bodyColor: p.fg, displayColor: p.fg);
  return base.copyWith(
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.8, fontSize: 32),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.6, fontSize: 28),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3, fontSize: 19),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2, fontSize: 15.5),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 14.5, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(fontSize: 12.5, color: p.muted),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: p.fg,
      systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w600, color: p.fg),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Colors.white : (p.isDark ? const Color(0xFF9A9AAA) : Colors.white)),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? p.accent : p.border),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.border,
      thumbColor: Colors.white,
      overlayColor: p.accent.withValues(alpha: 0.15),
      trackHeight: 5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card2.withValues(alpha: 0.6),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.8)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusButton), borderSide: BorderSide(color: p.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusButton), borderSide: BorderSide(color: p.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusButton), borderSide: BorderSide(color: p.accent.withValues(alpha: 0.8), width: 1.5)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.card,
      showDragHandle: true,
      dragHandleColor: p.border,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: p.border)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.card2,
      contentTextStyle: TextStyle(color: p.fg, fontFamily: family, fontSize: 14),
      actionTextColor: p.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: p.border)),
      elevation: 6,
    ),
    popupMenuTheme: PopupMenuThemeData(color: p.card2, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.border))),
    timePickerTheme: TimePickerThemeData(backgroundColor: p.card),
    datePickerTheme: DatePickerThemeData(backgroundColor: p.card, surfaceTintColor: Colors.transparent),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, linearTrackColor: p.border),
    extensions: [PaletteExt(p, AppDensity(s.s('appearance.density') == 'compact'), reduce)],
  );
}

double textScaleFor(AppSettings s) => switch (s.s('appearance.textSize')) { 'small' => 0.92, 'large' => 1.1, _ => 1.0 };

class _FadeOnlyTransitions extends PageTransitionsBuilder {
  const _FadeOnlyTransitions();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      FadeTransition(opacity: animation, child: child);
}

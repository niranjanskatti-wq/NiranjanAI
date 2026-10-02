import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? SmritiColors.dark : SmritiColors.light;

  TextStyle s(double size, FontWeight w, {String family = sans, double? height, double? ls}) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: fontFallback,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: ls,
        color: c.text,
      );

  final textTheme = TextTheme(
    displayLarge: s(40, FontWeight.w600, family: serif, height: 1.1),
    displayMedium: s(34, FontWeight.w600, family: serif, height: 1.1),
    headlineLarge: s(28, FontWeight.w600, family: serif, height: 1.15),
    headlineMedium: s(24, FontWeight.w600, family: serif, height: 1.15),
    headlineSmall: s(22, FontWeight.w600, family: serif, height: 1.2),
    titleLarge: s(17, FontWeight.w600),
    titleMedium: s(15, FontWeight.w600),
    titleSmall: s(13, FontWeight.w600),
    bodyLarge: s(15, FontWeight.w400, height: 1.45),
    bodyMedium: s(14, FontWeight.w400, height: 1.45),
    bodySmall: s(12, FontWeight.w400, height: 1.4).copyWith(color: c.muted),
    labelLarge: s(14, FontWeight.w700),
    labelMedium: s(12, FontWeight.w700, ls: 0.4),
    labelSmall: s(11, FontWeight.w700, ls: 1.2).copyWith(color: c.muted),
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.gold,
    onPrimary: c.onGold,
    secondary: c.gold,
    onSecondary: c.onGold,
    error: c.alert,
    onError: Colors.white,
    surface: c.bg,
    onSurface: c.text,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.raised,
    surfaceContainerHighest: c.raised,
    onSurfaceVariant: c.muted,
    outline: c.line,
    outlineVariant: c.line,
  );

  final roundedButton = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button));

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: sans,
    fontFamilyFallback: fontFallback,
    textTheme: textTheme,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: c.line),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.gold,
        foregroundColor: c.onGold,
        minimumSize: const Size(64, 48),
        shape: roundedButton,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.line),
        minimumSize: const Size(64, 48),
        shape: roundedButton,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.goldText, textStyle: textTheme.labelLarge),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.gold,
      foregroundColor: c.onGold,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      labelStyle: TextStyle(color: c.muted),
      hintStyle: TextStyle(color: c.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.button),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.button),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.button),
        borderSide: BorderSide(color: c.gold, width: 1.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.text,
      side: BorderSide(color: c.line),
      labelStyle: textTheme.titleSmall,
      secondaryLabelStyle: textTheme.titleSmall?.copyWith(color: c.bg),
      checkmarkColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.gold.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => textTheme.labelMedium?.copyWith(
          color: st.contains(WidgetState.selected) ? c.goldText : c.muted,
          letterSpacing: 0,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(color: st.contains(WidgetState.selected) ? c.goldText : c.muted),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
      titleTextStyle: textTheme.headlineSmall,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.text,
      contentTextStyle: textTheme.titleSmall?.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? c.onGold : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? c.gold : c.raised,
      ),
      trackOutlineColor: WidgetStateProperty.all(c.line),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.muted,
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodySmall,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: c.raised,
      headerForegroundColor: c.text,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

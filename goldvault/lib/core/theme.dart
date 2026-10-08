import 'package:flutter/material.dart';

/// Premium dark navy + gold palette.
class GV {
  GV._();
  static const bg = Color(0xFF070B16);
  static const surface = Color(0xFF0F1626);
  static const surface2 = Color(0xFF162036);
  static const line = Color(0xFF243151);
  static const gold = Color(0xFFE0B04B);
  static const goldLight = Color(0xFFF5D98B);
  static const goldDeep = Color(0xFFB8892B);
  static const silver = Color(0xFFC9D1DE);
  static const text = Color(0xFFF3EEE2);
  static const muted = Color(0xFF9AA5BD);
  static const danger = Color(0xFFEF6C6C);
  static const ok = Color(0xFF7BD88F);

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFF7E0A0), gold, goldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF17213A), Color(0xFF0F1626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const display = 'Playfair';
  static const body = 'Lato';

  static ThemeData theme() {
    const scheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF1A1405),
      secondary: goldLight,
      onSecondary: Color(0xFF1A1405),
      surface: surface,
      onSurface: text,
      error: danger,
      outline: line,
      surfaceContainerHighest: surface2,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: body);
    final tt = base.textTheme.apply(bodyColor: text, displayColor: text);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: tt.copyWith(
        displaySmall: tt.displaySmall?.copyWith(fontFamily: display, fontWeight: FontWeight.w600),
        headlineMedium: tt.headlineMedium?.copyWith(fontFamily: display, fontWeight: FontWeight.w600),
        headlineSmall: tt.headlineSmall?.copyWith(fontFamily: display, fontWeight: FontWeight.w600),
        titleLarge: tt.titleLarge?.copyWith(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 22),
        titleMedium: tt.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: tt.bodyLarge?.copyWith(fontSize: 17),
        bodyMedium: tt.bodyMedium?.copyWith(fontSize: 15.5),
        labelLarge: tt.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: display, fontSize: 24, color: gold, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          backgroundColor: gold,
          foregroundColor: const Color(0xFF1A1405),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: body),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          foregroundColor: gold,
          side: const BorderSide(color: goldDeep),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: body),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: gold,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: body),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Color(0xFF1A1405),
        extendedTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: body),
        extendedPadding: EdgeInsets.symmetric(horizontal: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(color: muted, fontSize: 16),
        floatingLabelStyle: const TextStyle(color: gold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: gold, width: 1.6)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface2,
        selectedColor: gold.withValues(alpha: 0.22),
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(color: text, fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: gold.withValues(alpha: 0.18),
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: s.contains(WidgetState.selected) ? gold : muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(size: 27, color: s.contains(WidgetState.selected) ? gold : muted)),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        iconColor: gold,
        titleTextStyle: TextStyle(fontSize: 17, color: text, fontFamily: body, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(fontSize: 14.5, color: muted, fontFamily: body),
      ),
      dividerTheme: const DividerThemeData(color: line, space: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surface2,
        contentTextStyle: TextStyle(color: text, fontSize: 15.5),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? gold : muted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gold.withValues(alpha: 0.35) : surface2),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(backgroundColor: bg),
      }),
    );
  }
}

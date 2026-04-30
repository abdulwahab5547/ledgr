import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design/ledgr_colors.dart';

/// Global Material theme tuned for the Ledgr design language.
///
/// Light theme is intentionally identical to dark — Ledgr is dark-only by
/// design (cinematic OLED black). Both modes are returned so MaterialApp's
/// system-mode switching never blanks out the UI.
class AppTheme {
  const AppTheme._();

  static SystemUiOverlayStyle get overlay => const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: LedgrColors.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      );

  static ThemeData _build() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: LedgrColors.bg,
      canvasColor: LedgrColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: LedgrColors.bg,
        onSurface: LedgrColors.text,
        primary: LedgrColors.lime,
        onPrimary: LedgrColors.bg,
        secondary: LedgrColors.lime,
        onSecondary: LedgrColors.bg,
        error: LedgrColors.neg,
        onError: LedgrColors.bg,
      ),
      textTheme: GoogleFonts.interTightTextTheme().apply(
        bodyColor: LedgrColors.text,
        displayColor: LedgrColors.text,
      ),
      iconTheme: const IconThemeData(color: LedgrColors.text, size: 22),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      splashColor: const Color(0x14C9FF5E),
      highlightColor: const Color(0x14C9FF5E),
      dividerTheme: const DividerThemeData(
        color: LedgrColors.hairline,
        thickness: 0.5,
        space: 0.5,
      ),
    );
    return base;
  }

  static ThemeData light() => _build();
  static ThemeData dark() => _build();
}

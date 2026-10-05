import 'package:flutter/material.dart';

/// Poppins, the web app's typeface, with Tailwind's type scale
/// (xs 12 · sm 14 · base 16 · lg 18 · xl 20 · 2xl 24 · 3xl 30).
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';

  /// Task codes etc. (`font-mono`). Falls back to the platform monospace font.
  static const String monoFamily = 'monospace';
  static const List<String> monoFallback = ['Menlo', 'Roboto Mono', 'Courier New', 'Courier'];

  static TextTheme textTheme(Color color, Color muted) {
    TextStyle s(double size, FontWeight w, {double? height, double? letterSpacing, Color? c}) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: letterSpacing,
          color: c ?? color,
        );

    return TextTheme(
      displayLarge: s(36, FontWeight.w700, height: 1.2),
      displayMedium: s(30, FontWeight.w700, height: 1.2), // text-3xl
      displaySmall: s(24, FontWeight.w700, height: 1.25), // text-2xl
      headlineLarge: s(24, FontWeight.w600, height: 1.25),
      headlineMedium: s(20, FontWeight.w700, height: 1.3), // page title: text-xl font-bold
      headlineSmall: s(18, FontWeight.w600, height: 1.3), // text-lg
      titleLarge: s(18, FontWeight.w600, height: 1.35),
      titleMedium: s(16, FontWeight.w500, height: 1.4), // card title
      titleSmall: s(14, FontWeight.w600, height: 1.4), // section title
      bodyLarge: s(16, FontWeight.w400, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, height: 1.5), // text-sm
      bodySmall: s(12, FontWeight.w400, height: 1.5, c: muted), // text-xs muted
      labelLarge: s(14, FontWeight.w500, height: 1.2), // buttons
      labelMedium: s(12, FontWeight.w500, height: 1.2), // badges, field labels
      labelSmall: s(10, FontWeight.w600, height: 1.2, letterSpacing: 0.8, c: muted), // OVERLINE
    );
  }
}

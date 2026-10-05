import 'package:flutter/material.dart';

/// The web app's design tokens (src/app/globals.css), converted from oklch to sRGB.
/// Names match the CSS variables so web and mobile stay easy to compare:
/// `--muted-foreground` → [mutedForeground], `--card` → [card], …
///
/// Read them anywhere with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
    required this.isDark,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color input;
  final Color ring;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;
  final bool isDark;

  /// `:root`
  static const light = AppColors(
    isDark: false,
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0C090C),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0C090C),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0C090C),
    primary: Color(0xFF432DD7),
    primaryForeground: Color(0xFFEEF2FF),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0xFFF3F1F3),
    mutedForeground: Color(0xFF79697B),
    accent: Color(0xFFF3F1F3),
    accentForeground: Color(0xFF1D161E),
    destructive: Color(0xFFE7000B),
    border: Color(0xFFE7E4E7),
    input: Color(0xFFE7E4E7),
    ring: Color(0xFFA89EA9),
    chart1: Color(0xFFA3B3FF),
    chart2: Color(0xFF615FFF),
    chart3: Color(0xFF4F39F6),
    chart4: Color(0xFF432DD7),
    chart5: Color(0xFF372AAC),
    sidebar: Color(0xFFFAFAFA),
    sidebarForeground: Color(0xFF0C090C),
    sidebarPrimary: Color(0xFF4F39F6),
    sidebarPrimaryForeground: Color(0xFFEEF2FF),
    sidebarAccent: Color(0xFFF3F1F3),
    sidebarAccentForeground: Color(0xFF1D161E),
    sidebarBorder: Color(0xFFE7E4E7),
    sidebarRing: Color(0xFFA89EA9),
  );

  /// `.dark`
  static const dark = AppColors(
    isDark: true,
    background: Color(0xFF0C090C),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF1D161E),
    cardForeground: Color(0xFFFAFAFA),
    popover: Color(0xFF1D161E),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFF372AAC),
    primaryForeground: Color(0xFFEEF2FF),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF2A212C),
    mutedForeground: Color(0xFFA89EA9),
    accent: Color(0xFF2A212C),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFFFF6467),
    border: Color(0x1AFFFFFF), // white @ 10%
    input: Color(0x26FFFFFF), // white @ 15%
    ring: Color(0xFF79697B),
    chart1: Color(0xFFA3B3FF),
    chart2: Color(0xFF615FFF),
    chart3: Color(0xFF4F39F6),
    chart4: Color(0xFF432DD7),
    chart5: Color(0xFF372AAC),
    sidebar: Color(0xFF1D161E),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF615FFF),
    sidebarPrimaryForeground: Color(0xFFEEF2FF),
    sidebarAccent: Color(0xFF2A212C),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0x1AFFFFFF),
    sidebarRing: Color(0xFF79697B),
  );

  /// Hairline ring used around cards / popups (`ring-1 ring-foreground/10`).
  Color get ringSubtle => foreground.withValues(alpha: 0.10);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: l(background, other.background),
      foreground: l(foreground, other.foreground),
      card: l(card, other.card),
      cardForeground: l(cardForeground, other.cardForeground),
      popover: l(popover, other.popover),
      popoverForeground: l(popoverForeground, other.popoverForeground),
      primary: l(primary, other.primary),
      primaryForeground: l(primaryForeground, other.primaryForeground),
      secondary: l(secondary, other.secondary),
      secondaryForeground: l(secondaryForeground, other.secondaryForeground),
      muted: l(muted, other.muted),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      accent: l(accent, other.accent),
      accentForeground: l(accentForeground, other.accentForeground),
      destructive: l(destructive, other.destructive),
      border: l(border, other.border),
      input: l(input, other.input),
      ring: l(ring, other.ring),
      chart1: l(chart1, other.chart1),
      chart2: l(chart2, other.chart2),
      chart3: l(chart3, other.chart3),
      chart4: l(chart4, other.chart4),
      chart5: l(chart5, other.chart5),
      sidebar: l(sidebar, other.sidebar),
      sidebarForeground: l(sidebarForeground, other.sidebarForeground),
      sidebarPrimary: l(sidebarPrimary, other.sidebarPrimary),
      sidebarPrimaryForeground: l(sidebarPrimaryForeground, other.sidebarPrimaryForeground),
      sidebarAccent: l(sidebarAccent, other.sidebarAccent),
      sidebarAccentForeground: l(sidebarAccentForeground, other.sidebarAccentForeground),
      sidebarBorder: l(sidebarBorder, other.sidebarBorder),
      sidebarRing: l(sidebarRing, other.sidebarRing),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Tailwind v4 palette entries the web screens use directly (task status / priority
/// colours, avatar colours, success / warning accents).
class TwColors {
  TwColors._();
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate400 = Color(0xFF90A1B9);
  static const Color slate500 = Color(0xFF62748E);
  static const Color slate700 = Color(0xFF314158);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red500 = Color(0xFFFB2C36);
  static const Color red600 = Color(0xFFE7000B);
  static const Color red700 = Color(0xFFC10007);
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange500 = Color(0xFFFF6900);
  static const Color orange700 = Color(0xFFCA3500);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber400 = Color(0xFFFFB900);
  static const Color amber500 = Color(0xFFFE9A00);
  static const Color amber700 = Color(0xFFBB4D00);
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green500 = Color(0xFF00C950);
  static const Color green700 = Color(0xFF008236);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald500 = Color(0xFF00BC7D);
  static const Color emerald600 = Color(0xFF009966);
  static const Color emerald700 = Color(0xFF007A55);
  static const Color cyan600 = Color(0xFF0092B8);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue500 = Color(0xFF2B7FFF);
  static const Color blue700 = Color(0xFF1447E6);
  static const Color indigo500 = Color(0xFF615FFF);
  static const Color indigo600 = Color(0xFF4F39F6);
  static const Color indigo700 = Color(0xFF432DD7);
  static const Color violet500 = Color(0xFF8E51FF);
  static const Color violet600 = Color(0xFF7F22FE);
  static const Color rose500 = Color(0xFFFF2056);
  static const Color rose700 = Color(0xFFC70036);
  static const Color pink500 = Color(0xFFF6339A);
}

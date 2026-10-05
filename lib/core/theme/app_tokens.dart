import 'package:flutter/material.dart';

/// Corner radii. The web app derives them all from `--radius: 0.625rem` (10px):
/// sm 0.6×, md 0.8×, lg 1×, xl 1.4×, 2xl 1.8×, 3xl 2.2×, 4xl 2.6×.
class AppRadius {
  AppRadius._();
  static const double base = 10;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 14;
  static const double x2 = 18;
  static const double x3 = 22;
  static const double x4 = 26; // badges, pills
  static const double full = 999;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rFull => BorderRadius.circular(full);
}

/// 4-pt spacing scale (Tailwind `1` = 4px).
class AppSpace {
  AppSpace._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
}

/// Control sizes. The web desktop UI uses 32px controls; on a phone those are too
/// small to tap reliably, so the heights below are the touch-friendly equivalents
/// (same look, same radii, same type sizes). Change them here to retune the whole app.
class AppSizes {
  AppSizes._();
  static const double controlXs = 28; // web h-6
  static const double controlSm = 36; // web h-7
  static const double control = 44; // web h-8 (default)
  static const double controlLg = 48; // web h-9
  static const double iconSm = 14;
  static const double icon = 16;
  static const double iconLg = 20;
  static const double badgeHeight = 22;
}

/// Motion used by the web transitions (`duration-100/150/200`).
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOutCubic;
}

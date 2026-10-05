import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

enum AppBadgeVariant { primary, secondary, destructive, outline, ghost, link }

/// Pill label (web `Badge`). Use [AppBadge.tinted] for status / priority chips that
/// need their own colour.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.variant = AppBadgeVariant.primary, this.icon, this.dotColor})
      : _fg = null,
        _bg = null;

  /// Custom colours: tinted background with matching text, e.g. task status chips.
  const AppBadge.tinted(this.label, {super.key, required Color color, Color? background, this.icon, this.dotColor})
      : variant = AppBadgeVariant.primary,
        _fg = color,
        _bg = background;

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  /// Small leading dot (priority badges).
  final Color? dotColor;
  final Color? _fg;
  final Color? _bg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Color bg;
    Color fg;
    Color? border;
    switch (variant) {
      case AppBadgeVariant.primary:
        bg = c.primary;
        fg = c.primaryForeground;
      case AppBadgeVariant.secondary:
        bg = c.secondary;
        fg = c.secondaryForeground;
      case AppBadgeVariant.destructive:
        bg = c.destructive.withValues(alpha: c.isDark ? 0.20 : 0.10);
        fg = c.destructive;
      case AppBadgeVariant.outline:
        bg = Colors.transparent;
        fg = c.foreground;
        border = c.border;
      case AppBadgeVariant.ghost:
        bg = Colors.transparent;
        fg = c.mutedForeground;
      case AppBadgeVariant.link:
        bg = Colors.transparent;
        fg = c.primary;
    }
    if (_fg != null) {
      fg = _fg;
      bg = _bg ?? _fg.withValues(alpha: c.isDark ? 0.20 : 0.12);
    }

    return Container(
      height: AppSizes.badgeHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
              height: 1.1,
              decoration: variant == AppBadgeVariant.link ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

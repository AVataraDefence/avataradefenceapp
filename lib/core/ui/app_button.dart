import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_spinner.dart';

/// Mirrors the web `Button` variants (default / outline / secondary / ghost /
/// destructive / link). [primary] is the web "default".
enum AppButtonVariant { primary, outline, secondary, ghost, destructive, link }

/// Mirrors the web sizes (xs / sm / default / lg) at touch-friendly heights.
enum AppButtonSize { xs, sm, md, lg }

class _ButtonSpec {
  const _ButtonSpec(this.height, this.hPad, this.font, this.icon, this.gap, this.radius);
  final double height;
  final double hPad;
  final double font;
  final double icon;
  final double gap;
  final double radius;
}

const _specs = <AppButtonSize, _ButtonSpec>{
  AppButtonSize.xs: _ButtonSpec(AppSizes.controlXs, 10, 12, 12, 4, AppRadius.md),
  AppButtonSize.sm: _ButtonSpec(AppSizes.controlSm, 12, 13, 14, 6, AppRadius.md + 2),
  AppButtonSize.md: _ButtonSpec(AppSizes.control, 16, 14, 16, 8, AppRadius.lg),
  AppButtonSize.lg: _ButtonSpec(AppSizes.controlLg, 20, 14, 16, 8, AppRadius.lg),
};

({Color bg, Color fg, Color border, Color pressed}) _palette(AppColors c, AppButtonVariant v) {
  switch (v) {
    case AppButtonVariant.primary:
      return (bg: c.primary, fg: c.primaryForeground, border: Colors.transparent, pressed: c.primaryForeground.withValues(alpha: 0.16));
    case AppButtonVariant.outline:
      return (
        bg: c.isDark ? c.input.withValues(alpha: 0.30) : c.background,
        fg: c.foreground,
        border: c.isDark ? c.input : c.border,
        pressed: c.muted,
      );
    case AppButtonVariant.secondary:
      return (bg: c.secondary, fg: c.secondaryForeground, border: Colors.transparent, pressed: c.foreground.withValues(alpha: 0.06));
    case AppButtonVariant.ghost:
      return (bg: Colors.transparent, fg: c.foreground, border: Colors.transparent, pressed: c.muted);
    case AppButtonVariant.destructive:
      return (
        bg: c.destructive.withValues(alpha: c.isDark ? 0.20 : 0.10),
        fg: c.destructive,
        border: Colors.transparent,
        pressed: c.destructive.withValues(alpha: 0.14),
      );
    case AppButtonVariant.link:
      return (bg: Colors.transparent, fg: c.primary, border: Colors.transparent, pressed: c.primary.withValues(alpha: 0.08));
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
  }) : assert(label != null || child != null, 'Provide a label or a child');

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;

  /// Shows a spinner in place of the leading icon and blocks taps (web `Loader2`).
  final bool loading;

  /// Stretch to the full available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = _specs[size]!;
    final p = _palette(c, variant);
    final enabled = onPressed != null && !loading;
    final isLink = variant == AppButtonVariant.link;

    final textStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: spec.font,
      fontWeight: FontWeight.w500,
      color: p.fg,
      height: 1.2,
      decoration: isLink ? TextDecoration.underline : null,
      decorationColor: p.fg,
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          Padding(
            padding: EdgeInsets.only(right: spec.gap),
            child: AppSpinner(size: spec.icon, color: p.fg),
          )
        else if (icon != null)
          Padding(
            padding: EdgeInsets.only(right: spec.gap),
            child: Icon(icon, size: spec.icon, color: p.fg),
          ),
        Flexible(
          child: DefaultTextStyle(
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            child: child ?? Text(label!),
          ),
        ),
        if (trailingIcon != null)
          Padding(
            padding: EdgeInsets.only(left: spec.gap),
            child: Icon(trailingIcon, size: spec.icon, color: p.fg),
          ),
      ],
    );

    final radius = BorderRadius.circular(spec.radius);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: p.bg,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          splashColor: p.pressed,
          highlightColor: p.pressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isLink ? spec.height - 8 : spec.height, minWidth: spec.height),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isLink ? 4 : spec.hPad),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon-only button (web `size="icon"`); defaults to the ghost look used in
/// toolbars and card actions.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.md,
    this.tooltip,
    this.color,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final String? tooltip;

  /// Overrides the icon colour (defaults to muted for ghost, the variant colour otherwise).
  final Color? color;

  /// Small red count bubble on the corner (notification bell).
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = _specs[size]!;
    final p = _palette(c, variant);
    final fg = color ?? (variant == AppButtonVariant.ghost ? c.mutedForeground : p.fg);
    final dim = spec.height;

    Widget button = Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: p.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spec.radius), side: BorderSide(color: p.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: p.pressed,
          highlightColor: p.pressed,
          child: SizedBox(width: dim, height: dim, child: Icon(icon, size: size == AppButtonSize.xs ? 14 : 20, color: fg)),
        ),
      ),
    );

    if (badge != null && badge! > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: TwColors.red500,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: c.background, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                badge! > 99 ? '99+' : '$badge',
                style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1),
              ),
            ),
          ),
        ],
      );
    }
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

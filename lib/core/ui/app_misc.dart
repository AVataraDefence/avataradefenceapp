import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Hairline divider (web `Separator`). With [label] it draws "──── OR ────".
class AppSeparator extends StatelessWidget {
  const AppSeparator({super.key, this.vertical = false, this.label, this.indent = 0});

  final bool vertical;
  final String? label;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (vertical) return Container(width: 1, color: c.border);
    if (label == null) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: indent), child: Container(height: 1, color: c.border));
    }
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label!, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Container(height: 1, color: c.border)),
      ],
    );
  }
}

/// Slim progress bar (web `Progress`, `h-1 bg-muted` track). Animates when the value
/// changes so progress visibly grows. [value] is 0–100.
class AppProgress extends StatelessWidget {
  const AppProgress({super.key, required this.value, this.height = 4, this.color, this.showLabel = false, this.completeColor});

  final double value;
  final double height;

  /// Bar colour; defaults to primary.
  final Color? color;

  /// Colour used at 100% (web cards turn green when a task is complete).
  final Color? completeColor;

  /// Show "NN%" to the right of the bar.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value.clamp(0, 100).toDouble();
    final fill = v >= 100 ? (completeColor ?? color ?? c.primary) : (color ?? c.primary);
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        height: height,
        color: c.muted,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v),
          duration: AppMotion.slow * 2,
          curve: AppMotion.curve,
          builder: (_, t, _) => FractionallySizedBox(
            widthFactor: t / 100,
            child: Container(color: fill),
          ),
        ),
      ),
    );
    if (!showLabel) return bar;
    return Row(
      children: [
        Expanded(child: bar),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '${v.round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: c.foreground),
          ),
        ),
      ],
    );
  }
}

/// Pulsing placeholder block (web `Skeleton`, `animate-pulse bg-muted`).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.width, this.height = 16, this.radius = AppRadius.md, this.circle = false});

  const AppSkeleton.circle({super.key, double size = 32})
      : width = size,
        height = size,
        radius = AppRadius.full,
        circle = true;

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Opacity(
        opacity: 1 - 0.5 * Curves.easeInOut.transform(_controller.value),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: c.muted,
            borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
      ),
    );
  }
}

/// Placeholder shaped like a typical list card, for loading states.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.rXl,
        border: Border.all(color: c.ringSubtle),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [AppSkeleton.circle(size: 28), SizedBox(width: 10), AppSkeleton(width: 110, height: 12)]),
          SizedBox(height: 14),
          AppSkeleton(height: 14),
          SizedBox(height: 8),
          AppSkeleton(width: 180, height: 12),
          SizedBox(height: 14),
          AppSkeleton(height: 6),
        ],
      ),
    );
  }
}

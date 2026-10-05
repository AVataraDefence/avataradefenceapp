import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Content card (web `Card`): `rounded-xl`, `bg-card`, hairline `ring-foreground/10`.
/// Slots mirror CardHeader / CardTitle / CardDescription / CardAction / CardContent /
/// CardFooter. Everything is optional.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.description,
    this.action,
    this.child,
    this.footer,
    this.padding = const EdgeInsets.all(AppSpace.s4),
    this.headerDivider = false,
    this.onTap,
  });

  final String? title;
  final String? description;

  /// Trailing widget in the header row (a button or menu).
  final Widget? action;
  final Widget? child;

  /// Pinned bottom strip on a muted background (`CardFooter`).
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  /// Draw a rule under the header (`CardHeader.border-b`).
  final bool headerDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final hasHeader = title != null || description != null || action != null;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader)
          Container(
            padding: padding,
            decoration: headerDivider ? BoxDecoration(border: Border(bottom: BorderSide(color: c.border))) : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) Text(title!, style: t.titleMedium),
                      if (description != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(description!, style: t.bodySmall)),
                    ],
                  ),
                ),
                ?action,
              ],
            ),
          ),
        if (child != null)
          Padding(
            padding: hasHeader && !headerDivider
                ? padding.resolve(Directionality.of(context)).copyWith(top: 0)
                : padding,
            child: child,
          ),
        if (footer != null)
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: footer,
          ),
      ],
    );

    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl, side: BorderSide(color: c.ringSubtle)),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

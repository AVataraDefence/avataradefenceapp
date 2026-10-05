import 'package:flutter/material.dart';

import '../core/core.dart';

/// Standard list row for the app (replaces the web's wide tables on a phone): a title with an
/// optional subtitle and trailing controls, then `label : value` lines.
class AppListCard extends StatelessWidget {
  const AppListCard({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.rows = const [], this.onTap, this.badge});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Pill next to the title (status, type…).
  final Widget? badge;

  /// `(label, value widget)` pairs shown under the header.
  final List<(String, Widget)> rows;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl, side: BorderSide(color: c.border.withValues(alpha: 0.8))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                          if (subtitle != null && subtitle!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: t.bodySmall?.copyWith(fontSize: 12))),
                          if (badge != null) Padding(padding: const EdgeInsets.only(top: 6), child: badge),
                        ],
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: c.border.withValues(alpha: 0.6)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      for (final r in rows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 124, child: Text(r.$1, style: t.bodySmall?.copyWith(fontSize: 12))),
                              Expanded(child: Align(alignment: Alignment.centerLeft, child: r.$2)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

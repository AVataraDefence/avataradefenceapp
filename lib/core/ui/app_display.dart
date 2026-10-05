import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_input.dart';
import 'app_overlays.dart';

// ── Tabs ───────────────────────────────────────────────────────────────────────
class AppTabItem {
  const AppTabItem(this.label, {this.count, this.icon});

  final String label;

  /// Small number shown beside the label, e.g. "Overdue (3)".
  final int? count;
  final IconData? icon;
}

enum AppTabsVariant {
  /// Underlined tabs, like the Reports page.
  underline,

  /// Segmented control on a muted track (web `TabsList` default).
  pill,
}

class AppTabs extends StatelessWidget {
  const AppTabs({super.key, required this.tabs, required this.index, required this.onChanged, this.variant = AppTabsVariant.underline});

  final List<AppTabItem> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  final AppTabsVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;

    Widget content(int i, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tabs[i].icon != null) ...[Icon(tabs[i].icon, size: 16, color: color), const SizedBox(width: 6)],
            Text(
              tabs[i].label,
              style: t.labelLarge?.copyWith(color: color, fontWeight: i == index ? FontWeight.w600 : FontWeight.w500),
            ),
            if (tabs[i].count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: i == index ? c.primary.withValues(alpha: 0.12) : c.muted, borderRadius: AppRadius.rFull),
                child: Text('${tabs[i].count}', style: t.labelMedium?.copyWith(color: i == index ? c.primary : c.mutedForeground, fontSize: 11)),
              ),
            ],
          ],
        );

    if (variant == AppTabsVariant.pill) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: c.muted, borderRadius: AppRadius.rLg),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? c.background : Colors.transparent,
                      borderRadius: AppRadius.rMd,
                      boxShadow: i == index ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                    ),
                    child: content(i, i == index ? c.foreground : c.mutedForeground),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  height: 46,
                  margin: const EdgeInsets.only(right: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: i == index ? c.primary : Colors.transparent, width: 2)),
                  ),
                  child: content(i, i == index ? c.foreground : c.mutedForeground),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Alert ──────────────────────────────────────────────────────────────────────
enum AppAlertVariant { info, destructive, success, warning }

/// Inline message box (web `Alert`).
class AppAlert extends StatelessWidget {
  const AppAlert({super.key, required this.title, this.description, this.variant = AppAlertVariant.info, this.icon});

  final String title;
  final String? description;
  final AppAlertVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (Color accent, IconData defaultIcon) = switch (variant) {
      AppAlertVariant.info => (c.primary, LucideIcons.info),
      AppAlertVariant.destructive => (c.destructive, LucideIcons.circleAlert),
      AppAlertVariant.success => (TwColors.emerald600, LucideIcons.circleCheck),
      AppAlertVariant.warning => (TwColors.amber500, LucideIcons.triangleAlert),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: c.isDark ? 0.14 : 0.07),
        borderRadius: AppRadius.rLg,
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon ?? defaultIcon, size: 18, color: accent)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (description != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(description!, style: t.bodySmall?.copyWith(color: c.mutedForeground))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class AppEmpty extends StatelessWidget {
  const AppEmpty({super.key, required this.title, this.description, this.icon = LucideIcons.inbox, this.action});

  final String title;
  final String? description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: c.mutedForeground),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: t.titleSmall),
          if (description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(description!, textAlign: TextAlign.center, style: t.bodySmall)),
          if (action != null) Padding(padding: const EdgeInsets.only(top: 16), child: action),
        ],
      ),
    );
  }
}

// ── Table ──────────────────────────────────────────────────────────────────────
/// Bordered grid like the web data tables: muted header row, hairline cells,
/// horizontal scroll when the columns don't fit a phone screen.
class AppTable extends StatelessWidget {
  const AppTable({super.key, required this.headers, required this.rows, this.columnWidths, this.minWidth = 0});

  final List<String> headers;
  final List<List<Widget>> rows;

  /// Fixed width per column (defaults to 140). Index-aligned with [headers].
  final List<double>? columnWidths;

  /// Minimum table width; below it the table scrolls sideways.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final widths = columnWidths ?? List.filled(headers.length, 140.0);
    final total = widths.fold<double>(0, (a, b) => a + b);

    Widget cell(Widget child, double w, {bool header = false}) => Container(
          width: w,
          constraints: BoxConstraints(minHeight: header ? 40 : 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: header ? c.muted : null,
            border: Border(right: BorderSide(color: c.border.withValues(alpha: 0.6)), bottom: BorderSide(color: c.border.withValues(alpha: 0.6))),
          ),
          child: child,
        );

    return ClipRRect(
      borderRadius: AppRadius.rXl,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: c.border.withValues(alpha: 0.8)), borderRadius: AppRadius.rXl, color: c.background),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: total < minWidth ? minWidth : total,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < headers.length; i++) cell(Text(headers[i], style: t.titleSmall?.copyWith(fontSize: 13)), widths[i], header: true),
                    ],
                  ),
                ),
                for (final r in rows)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [for (var i = 0; i < headers.length; i++) cell(r[i], widths[i])],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pagination ─────────────────────────────────────────────────────────────────
class AppPagination extends StatelessWidget {
  const AppPagination({super.key, required this.page, required this.totalPages, required this.onChanged});

  /// 1-based.
  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final c = context.colors;
    Widget nav(IconData icon, int target, bool enabled) => AppIconButton(
          icon: icon,
          size: AppButtonSize.sm,
          onPressed: enabled ? () => onChanged(target) : null,
        );

    // Window of up to 5 page numbers around the current page.
    final start = (page - 2).clamp(1, (totalPages - 4).clamp(1, totalPages));
    final end = (start + 4).clamp(1, totalPages);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        nav(LucideIcons.chevronLeft, page - 1, page > 1),
        for (var p = start; p <= end; p++)
          GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p == page ? c.primary : Colors.transparent, borderRadius: AppRadius.rMd),
              child: Text(
                '$p',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p == page ? c.primaryForeground : c.mutedForeground,
                ),
              ),
            ),
          ),
        nav(LucideIcons.chevronRight, page + 1, page < totalPages),
      ],
    );
  }
}

// ── Accordion ──────────────────────────────────────────────────────────────────
/// Collapsible section (web `Accordion` / `Collapsible`).
class AppAccordion extends StatefulWidget {
  const AppAccordion({super.key, required this.title, this.subtitle, required this.child, this.initiallyExpanded = false});

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: t.titleSmall),
                        if (widget.subtitle != null) Text(widget.subtitle!, style: t.bodySmall),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppMotion.normal,
                    child: Icon(LucideIcons.chevronDown, size: 18, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: _open ? Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: widget.child)) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Date field ─────────────────────────────────────────────────────────────────
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "04 Oct 2026" (the format the web UI uses).
String formatAppDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

/// Date input that opens the themed Material date picker.
class AppDateField extends StatelessWidget {
  const AppDateField({super.key, this.label, this.value, required this.onChanged, this.hint = 'Select date', this.error, this.required = false, this.firstDate, this.lastDate});

  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final String? error;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return AppField(
      label: label,
      error: error,
      required: required,
      child: Material(
        color: c.isDark ? c.input.withValues(alpha: 0.30) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: error != null ? c.destructive : c.input)),
        child: InkWell(
          borderRadius: AppRadius.rLg,
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: firstDate ?? DateTime(now.year - 5),
              lastDate: lastDate ?? DateTime(now.year + 10),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.control),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? hint : formatAppDate(value!),
                    style: t.bodyMedium?.copyWith(color: value == null ? c.mutedForeground : c.foreground),
                  ),
                ),
                Icon(LucideIcons.calendar, size: 16, color: c.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience: a bottom-sheet list of actions (web `DropdownMenu` / `ContextMenu`).
class AppMenuAction {
  const AppMenuAction({required this.label, required this.icon, required this.onTap, this.destructive = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

Future<void> showAppActionSheet(BuildContext context, {String? title, required List<AppMenuAction> actions}) {
  return showAppSheet<void>(
    context,
    title: title,
    builder: (ctx) {
      final c = ctx.colors;
      final t = Theme.of(ctx).textTheme;
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: [
          for (final a in actions)
            InkWell(
              borderRadius: AppRadius.rMd,
              onTap: () {
                Navigator.pop(ctx);
                a.onTap();
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(a.icon, size: 18, color: a.destructive ? c.destructive : c.mutedForeground),
                    const SizedBox(width: 12),
                    Text(a.label, style: t.bodyMedium?.copyWith(color: a.destructive ? c.destructive : c.foreground)),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

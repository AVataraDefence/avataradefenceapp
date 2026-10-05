import 'package:flutter/material.dart';

import '../../core/core.dart';

/// The standard page heading: title, one-line description, an optional primary action, and a
/// hairline rule. Every module page starts with one so screens look and feel alike.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;

  /// Usually an `AppButton(size: sm)` such as "+ New Task".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: t.bodySmall?.copyWith(color: c.mutedForeground))),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

/// Horizontally scrolling filter chips (All · To Do · In Progress …), each with a count.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({super.key, required this.items, required this.selected, required this.onSelected});

  /// `(value, label, count, colour)`; a null value is the "All" chip.
  final List<({T? value, String label, int count, Color color})> items;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          final on = it.value == selected;
          return GestureDetector(
            onTap: () => onSelected(it.value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: on ? it.color : c.background,
                borderRadius: AppRadius.rFull,
                border: Border.all(color: on ? it.color : c.border),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(it.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: on ? Colors.white : c.foreground)),
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: on ? Colors.white.withValues(alpha: 0.25) : c.muted, borderRadius: AppRadius.rFull),
                    child: Text('${it.count}', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: on ? Colors.white : c.mutedForeground)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// One choice in a select / radio group.
class AppOption<T> {
  const AppOption({required this.value, required this.label, this.subtitle, this.leading});

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
}

/// Checkbox with label (web `Checkbox`): 18px box, 4px radius, primary when checked.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, required this.onChanged, this.label, this.description, this.error = false});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    final box = AnimatedContainer(
      duration: AppMotion.fast,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? c.primary : (c.isDark ? c.input.withValues(alpha: 0.30) : Colors.transparent),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: value ? c.primary : (error ? c.destructive : c.input), width: 1.5),
      ),
      child: value ? Icon(LucideIcons.check, size: 14, color: c.primaryForeground) : null,
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        borderRadius: AppRadius.rMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              box,
              if (label != null || description != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null) Text(label!, style: t.bodyMedium),
                      if (description != null) Text(description!, style: t.bodySmall),
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

/// On / off switch (web `Switch`): pill track, round thumb.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.label, this.description});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    final sw = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      width: 40,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? c.primary : (c.isDark ? c.input.withValues(alpha: 0.80) : c.input),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value && c.isDark ? c.primaryForeground : (c.isDark ? c.foreground : c.background),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
    );
    final control = Opacity(opacity: enabled ? 1 : 0.5, child: sw);
    if (label == null && description == null) {
      return GestureDetector(onTap: enabled ? () => onChanged!(!value) : null, behavior: HitTestBehavior.opaque, child: control);
    }
    return InkWell(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: AppRadius.rMd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) Text(label!, style: t.bodyMedium),
                  if (description != null) Text(description!, style: t.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            control,
          ],
        ),
      ),
    );
  }
}

/// Single-choice list of radio buttons (web `RadioGroup`).
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({super.key, required this.value, required this.options, required this.onChanged, this.direction = Axis.vertical});

  final T? value;
  final List<AppOption<T>> options;
  final ValueChanged<T>? onChanged;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final items = [
      for (final o in options)
        InkWell(
          onTap: onChanged == null ? null : () => onChanged!(o.value),
          borderRadius: AppRadius.rMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: o.value == value ? c.primary : c.input, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: o.value == value ? 10 : 0,
                    height: o.value == value ? 10 : 0,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.label, style: t.bodyMedium),
                    if (o.subtitle != null) Text(o.subtitle!, style: t.bodySmall),
                  ],
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
    ];
    return direction == Axis.vertical
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: items)
        : Wrap(spacing: 8, children: items);
  }
}

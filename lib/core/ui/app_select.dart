import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_controls.dart';
import 'app_input.dart';
import 'app_overlays.dart';

/// Field-shaped trigger shared by the select widgets (looks like [AppInput]).
class _SelectTrigger extends StatelessWidget {
  const _SelectTrigger({required this.child, required this.onTap, required this.error, required this.enabled});

  final Widget child;
  final VoidCallback? onTap;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: c.isDark ? c.input.withValues(alpha: 0.30) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: error ? c.destructive : c.input)),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.rLg,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: AppSizes.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: child),
                  const SizedBox(width: 8),
                  Icon(LucideIcons.chevronDown, size: 16, color: c.mutedForeground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search box + option rows used inside the picker sheets.
class _OptionList<T> extends StatefulWidget {
  const _OptionList({required this.options, required this.isSelected, required this.onPick, required this.searchable, required this.multi});

  final List<AppOption<T>> options;
  final bool Function(T) isSelected;
  final void Function(T) onPick;
  final bool searchable;
  final bool multi;

  @override
  State<_OptionList<T>> createState() => _OptionListState<T>();
}

class _OptionListState<T> extends State<_OptionList<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final needle = _q.trim().toLowerCase();
    final items = needle.isEmpty
        ? widget.options
        : widget.options.where((o) => '${o.label} ${o.subtitle ?? ''}'.toLowerCase().contains(needle)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppInput(hint: 'Search…', prefixIcon: LucideIcons.search, onChanged: (v) => setState(() => _q = v)),
          ),
        Flexible(
          child: items.isEmpty
              ? Padding(padding: const EdgeInsets.all(24), child: Text('No results.', style: t.bodySmall))
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final o = items[i];
                    final selected = widget.isSelected(o.value);
                    return InkWell(
                      onTap: () => widget.onPick(o.value),
                      borderRadius: AppRadius.rMd,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: selected && widget.multi ? c.accent : null, borderRadius: AppRadius.rMd),
                        child: Row(
                          children: [
                            if (widget.multi)
                              AppCheckbox(value: selected, onChanged: null)
                            else
                              SizedBox(width: 20, child: selected ? Icon(LucideIcons.check, size: 16, color: c.primary) : null),
                            const SizedBox(width: 10),
                            if (o.leading != null) ...[o.leading!, const SizedBox(width: 10)],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.label, style: t.bodyMedium),
                                  if (o.subtitle != null) Text(o.subtitle!, style: t.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Single-choice dropdown (web `Select` / `Combobox`). Opens a bottom sheet with an
/// optional search box — easier to use than a tiny popup on a phone.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint = 'Select…',
    this.error,
    this.required = false,
    this.enabled = true,
    this.searchable,
    this.sheetTitle,
  });

  final List<AppOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String hint;
  final String? error;
  final bool required;
  final bool enabled;

  /// Show a search box; defaults to on when there are more than 7 options.
  final bool? searchable;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final selected = options.where((o) => o.value == value).firstOrNull;

    Future<void> open() async {
      final picked = await showAppSheet<T>(
        context,
        title: sheetTitle ?? label ?? hint,
        builder: (ctx) => _OptionList<T>(
          options: options,
          searchable: searchable ?? true,
          multi: false,
          isSelected: (v) => v == value,
          onPick: (v) => Navigator.pop(ctx, v),
        ),
      );
      if (picked != null) onChanged?.call(picked);
    }

    return AppField(
      label: label,
      error: error,
      required: required,
      child: _SelectTrigger(
        onTap: open,
        error: error != null,
        enabled: enabled && onChanged != null,
        child: Row(
          children: [
            if (selected?.leading != null) ...[selected!.leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(
                selected?.label ?? hint,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(color: selected == null ? c.mutedForeground : c.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-choice picker (web "Assign To" multi-select): chips in the field, checkbox
/// list with search in the sheet, Done / Clear footer.
class AppMultiSelect<T> extends StatelessWidget {
  const AppMultiSelect({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.label,
    this.hint = 'Select…',
    this.error,
    this.required = false,
    this.enabled = true,
    this.sheetTitle,
  });

  final List<AppOption<T>> options;
  final List<T> values;
  final ValueChanged<List<T>>? onChanged;
  final String? label;
  final String hint;
  final String? error;
  final bool required;
  final bool enabled;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final chosen = [for (final o in options) if (values.contains(o.value)) o];

    Future<void> open() async {
      var draft = List<T>.of(values);
      final result = await showAppSheet<List<T>>(
        context,
        title: sheetTitle ?? label ?? hint,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => _OptionList<T>(
            options: options,
            searchable: true,
            multi: true,
            isSelected: draft.contains,
            onPick: (v) => setSheet(() => draft.contains(v) ? draft.remove(v) : draft.add(v)),
          ),
        ),
        footer: StatefulBuilder(
          builder: (ctx, _) => Row(
            children: [
              Expanded(child: Text(draft.isEmpty ? 'None selected' : '${draft.length} selected', style: t.bodySmall)),
              AppButton(label: 'Clear', variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: () => Navigator.pop(ctx, <T>[])),
              const SizedBox(width: 8),
              AppButton(label: 'Done', size: AppButtonSize.sm, onPressed: () => Navigator.pop(ctx, draft)),
            ],
          ),
        ),
      );
      if (result != null) onChanged?.call(result);
    }

    return AppField(
      label: label,
      error: error,
      required: required,
      child: _SelectTrigger(
        onTap: open,
        error: error != null,
        enabled: enabled && onChanged != null,
        child: chosen.isEmpty
            ? Text(hint, style: t.bodyMedium?.copyWith(color: c.mutedForeground))
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in chosen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: c.muted, borderRadius: AppRadius.rMd),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (o.leading != null) ...[o.leading!, const SizedBox(width: 6)],
                          Text(o.label, style: t.bodySmall?.copyWith(color: c.foreground)),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

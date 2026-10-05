import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Label above a control, with optional required star, helper text and error line
/// (web `Field` + `Label`). Wrap any custom control in it.
class AppField extends StatelessWidget {
  const AppField({super.key, this.label, this.error, this.helper, this.required = false, required this.child});

  final String? label;
  final String? error;
  final String? helper;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label,
              style: t.labelLarge?.copyWith(height: 1.3),
              children: [if (required) TextSpan(text: ' *', style: TextStyle(color: c.destructive))],
            ),
          ),
          const SizedBox(height: 6),
        ],
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: t.bodySmall?.copyWith(color: c.destructive)),
        ] else if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: t.bodySmall),
        ],
      ],
    );
  }
}

/// Text input (web `Input`): 10px radius, `border-input`, and the soft 3px focus ring.
/// Pass [label]/[error]/[helper] to get the surrounding [AppField] for free.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.required = false,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.initialValue,
  });

  /// Multi-line field (web `Textarea`).
  const AppInput.multiline({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.required = false,
    this.minLines = 3,
    this.maxLines = 6,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.initialValue,
  })  : prefix = null,
        suffix = null,
        prefixIcon = null,
        obscureText = false,
        keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        inputFormatters = null,
        onSubmitted = null,
        onTap = null;

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? error;
  final String? helper;
  final bool required;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  late final TextEditingController? _own =
      widget.controller == null && widget.initialValue != null ? TextEditingController(text: widget.initialValue) : null;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != _focus.hasFocus) setState(() => _focused = _focus.hasFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = widget.error != null;
    final multi = widget.maxLines > 1;
    final ringColor = hasError ? c.destructive.withValues(alpha: c.isDark ? 0.40 : 0.20) : c.ring.withValues(alpha: 0.50);

    OutlineInputBorder border(Color color, [double w = 1]) =>
        OutlineInputBorder(borderRadius: AppRadius.rLg, borderSide: BorderSide(color: color, width: w));
    final base = hasError ? c.destructive : c.input;
    final focusBorder = hasError ? c.destructive : c.ring;

    final field = AnimatedContainer(
      duration: AppMotion.fast,
      decoration: BoxDecoration(
        // Solid fill so the focus ring (a shadow) never shows through the field.
        color: c.background,
        borderRadius: AppRadius.rLg,
        boxShadow: _focused ? [BoxShadow(color: ringColor, spreadRadius: 3)] : const [],
      ),
      child: TextField(
        controller: widget.controller ?? _own,
        focusNode: _focus,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        minLines: widget.minLines,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        style: Theme.of(context).textTheme.bodyMedium,
        cursorColor: c.primary,
        decoration: InputDecoration(
          hintText: widget.hint,
          counterText: '',
          isDense: true,
          filled: c.isDark,
          fillColor: widget.enabled ? c.input.withValues(alpha: 0.30) : c.input.withValues(alpha: 0.50),
          constraints: multi ? null : const BoxConstraints(minHeight: AppSizes.control),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: multi ? 12 : 13),
          prefix: widget.prefix,
          prefixIcon: widget.prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(widget.prefixIcon, size: AppSizes.icon, color: c.mutedForeground),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffix != null ? Padding(padding: const EdgeInsets.only(right: 4), child: widget.suffix) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: border(base),
          enabledBorder: border(base),
          disabledBorder: border(base.withValues(alpha: 0.5)),
          focusedBorder: border(focusBorder),
          errorBorder: border(c.destructive),
          focusedErrorBorder: border(c.destructive),
        ),
      ),
    );

    if (widget.label == null && widget.error == null && widget.helper == null) return field;
    return AppField(label: widget.label, error: widget.error, helper: widget.helper, required: widget.required, child: field);
  }
}

/// Alias with the web name.
typedef AppTextarea = AppInput;

/// Password input with a show / hide eye.
class AppPasswordInput extends StatefulWidget {
  const AppPasswordInput({super.key, this.controller, this.label, this.hint, this.error, this.required = false, this.onChanged, this.onSubmitted});

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final bool required;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppInput(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      required: widget.required,
      obscureText: _hidden,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: c.mutedForeground),
        visualDensity: VisualDensity.compact,
        tooltip: _hidden ? 'Show password' : 'Hide password',
      ),
    );
  }
}

/// Search box with a leading magnifier and a clear button (web header search).
class AppSearchField extends StatefulWidget {
  const AppSearchField({super.key, this.controller, this.hint = 'Search', this.onChanged, this.onSubmitted});

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppInput(
      controller: _controller,
      hint: widget.hint,
      prefixIcon: LucideIcons.search,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: _controller.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
              },
              icon: Icon(LucideIcons.x, size: 16, color: c.mutedForeground),
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear',
            ),
    );
  }
}

/// Small monospace text for codes (`TSK-017`).
class AppMono extends StatelessWidget {
  const AppMono(this.text, {super.key, this.size = 11, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.monoFamily,
        fontFamilyFallback: AppTypography.monoFallback,
        fontSize: size,
        color: color ?? context.colors.mutedForeground,
      ),
    );
  }
}

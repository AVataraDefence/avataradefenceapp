import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';

// ── Bottom sheet (web `Sheet` / `Drawer`) ──────────────────────────────────────
/// Opens a rounded bottom sheet with an optional title / description header and a
/// pinned [footer]. The body scrolls; the sheet lifts above the keyboard.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  String? title,
  String? description,
  required WidgetBuilder builder,
  Widget? footer,
  double maxHeightFactor = 0.9,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor),
    builder: (ctx) {
      final c = ctx.colors;
      final t = Theme.of(ctx).textTheme;
      // Above the keyboard when it is open, otherwise above the system navigation bar / home
      // indicator (useSafeArea does not cover the bottom edge).
      final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : MediaQuery.viewPaddingOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (description != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(description, style: t.bodySmall)),
                  ],
                ),
              ),
            Flexible(child: builder(ctx)),
            if (footer != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.muted.withValues(alpha: 0.5), border: Border(top: BorderSide(color: c.border))),
                child: footer,
              ),
          ],
        ),
      );
    },
  );
}

// ── Dialog (web `Dialog` / `AlertDialog`) ──────────────────────────────────────
class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, this.description, this.child, this.actions = const [], this.onClose});

  final String title;
  final String? description;
  final Widget? child;

  /// Buttons shown in a muted footer strip; the last one is the primary action.
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        if (description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(description!, style: t.bodyMedium?.copyWith(color: c.mutedForeground))),
                      ],
                    ),
                  ),
                  if (onClose != null) AppIconButton(icon: LucideIcons.x, onPressed: onClose, size: AppButtonSize.sm, tooltip: 'Close'),
                ],
              ),
            ),
            if (child != null) Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: child)),
            const SizedBox(height: 16),
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.muted.withValues(alpha: 0.5),
                  border: Border(top: BorderSide(color: c.border)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
                ),
                child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>(BuildContext context, {required WidgetBuilder builder, bool barrierDismissible = true}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: builder,
  );
}

/// Yes / no confirmation (web `AlertDialog`). Resolves to `true` when confirmed.
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  String? description,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      title: title,
      description: description,
      actions: [
        AppButton(label: cancelLabel, variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false)),
        AppButton(
          label: confirmLabel,
          variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── Toast (web `sonner`) ───────────────────────────────────────────────────────
enum AppToastType { info, success, error }

class AppToast {
  AppToast._();

  /// Floating message at the bottom, themed like the web toasts.
  static void show(BuildContext context, String message, {String? description, AppToastType type = AppToastType.info}) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (icon, color) = switch (type) {
      AppToastType.success => (LucideIcons.circleCheck, TwColors.emerald600),
      AppToastType.error => (LucideIcons.circleAlert, c.destructive),
      AppToastType.info => (LucideIcons.info, c.mutedForeground),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  if (description != null) Text(description, style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message, {String? description}) =>
      show(context, message, description: description, type: AppToastType.success);

  static void error(BuildContext context, String message, {String? description}) =>
      show(context, message, description: description, type: AppToastType.error);
}

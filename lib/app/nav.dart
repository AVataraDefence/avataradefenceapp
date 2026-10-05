import 'package:flutter/material.dart';

/// Navigation helpers. Paths are the same URLs the web app uses (`/module/employee/bank`, …),
/// so a screen in `lib/app/...` sits at the same place as `src/app/...` on the web.
class AppNav {
  AppNav._();

  /// Opens a page on top of the current one.
  static Future<T?> push<T>(BuildContext context, String path) => Navigator.of(context).pushNamed<T>(path);

  /// Switches page without growing the back stack (sidebar items).
  static Future<T?> replace<T>(BuildContext context, String path) => Navigator.of(context).pushReplacementNamed<T, Object?>(path);

  /// Header back button: pop, or go to [fallback] when this is the first page.
  static void back(BuildContext context, String fallback) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(fallback);
    }
  }

  /// Clears everything and shows [path] (sign in / sign out).
  static void reset(BuildContext context, String path) => Navigator.of(context).pushNamedAndRemoveUntil(path, (_) => false);
}

/// Opens a notification's deep link (`/module/task-management/my-tasks?task=17&comment=96`):
/// the path is the route, the query becomes the route arguments.
void openNotificationUrl(BuildContext context, String? url) => pushNotificationUrl(Navigator.of(context), url);

/// Same, for code without a [BuildContext] (a tapped system popup).
void pushNotificationUrl(NavigatorState nav, String? url) {
  final u = Uri.tryParse(url ?? '');
  final path = (u == null || u.path.isEmpty) ? '/module/notifications' : u.path;
  nav.pushNamed(path, arguments: u?.queryParameters.isEmpty ?? true ? null : u!.queryParameters);
}

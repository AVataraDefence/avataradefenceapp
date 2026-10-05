import 'package:flutter/material.dart';

/// Holds the light / dark / system choice. Wrap the app in [ThemeScope] and read it
/// with `ThemeScope.of(context)`; call [setMode] from a settings switch.
class ThemeController extends ChangeNotifier {
  ThemeController([ThemeMode initial = ThemeMode.system]) : _mode = initial;

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Flips between light and dark based on what is currently on screen.
  void toggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({super.key, required ThemeController controller, required super.child}) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope missing above this widget');
    return scope!.notifier!;
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Thin circular spinner (web `Spinner` / `Loader2 animate-spin`).
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 16, this.color, this.strokeWidth = 2});

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(color ?? context.colors.mutedForeground),
      ),
    );
  }
}

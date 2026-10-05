import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Builds the Material [ThemeData] from the web design tokens, so even plain
/// Material widgets (TextField, Dialog, AppBar…) look like the web app. The custom
/// components in `core/ui` read the same tokens through `context.colors`.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light);
  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    final brightness = c.isDark ? Brightness.dark : Brightness.light;
    final text = AppTypography.textTheme(c.foreground, c.mutedForeground);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      primaryContainer: c.primary.withValues(alpha: 0.10),
      onPrimaryContainer: c.primary,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      secondaryContainer: c.secondary,
      onSecondaryContainer: c.secondaryForeground,
      tertiary: c.accent,
      onTertiary: c.accentForeground,
      error: c.destructive,
      onError: Colors.white,
      errorContainer: c.destructive.withValues(alpha: c.isDark ? 0.20 : 0.10),
      onErrorContainer: c.destructive,
      surface: c.background,
      onSurface: c.foreground,
      onSurfaceVariant: c.mutedForeground,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.popover,
      surfaceContainerHighest: c.muted,
      outline: c.border,
      outlineVariant: c.border,
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Colors.transparent,
      inverseSurface: c.foreground,
      onInverseSurface: c.background,
      inversePrimary: c.primaryForeground,
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.rLg,
      borderSide: BorderSide(color: c.input),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.card,
      dividerColor: c.border,
      disabledColor: c.mutedForeground.withValues(alpha: 0.5),
      splashFactory: InkRipple.splashFactory,
      splashColor: c.primary.withValues(alpha: 0.08),
      highlightColor: c.muted.withValues(alpha: 0.6),
      hoverColor: c.muted,
      focusColor: c.ring.withValues(alpha: 0.2),
      visualDensity: VisualDensity.standard,
      extensions: [c],

      // ── Layout ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: c.mutedForeground, size: 20),
        actionsIconTheme: IconThemeData(color: c.mutedForeground, size: 20),
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: c.primary.withValues(alpha: c.isDark ? 0.25 : 0.10),
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 22,
              color: s.contains(WidgetState.selected) ? (c.isDark ? c.primaryForeground : c.primary) : c.mutedForeground,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelMedium?.copyWith(
              color: s.contains(WidgetState.selected) ? (c.isDark ? c.primaryForeground : c.primary) : c.mutedForeground,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            )),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.sidebar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(right: BorderSide(color: c.sidebarBorder)),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl, side: BorderSide(color: c.ringSubtle)),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.mutedForeground,
        textColor: c.foreground,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
      ),

      // ── Buttons (the custom AppButton is preferred; these keep stock ones on-brand)
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(c, bg: c.primary, fg: c.primaryForeground)),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle(c, bg: c.primary, fg: c.primaryForeground)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _buttonStyle(c, bg: Colors.transparent, fg: c.foreground).copyWith(
          side: WidgetStatePropertyAll(BorderSide(color: c.isDark ? c.input : c.border)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle(c, bg: Colors.transparent, fg: c.primary)),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.mutedForeground,
          minimumSize: const Size(AppSizes.control, AppSizes.control),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.primaryForeground,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        isDense: false,
        filled: c.isDark,
        fillColor: c.input.withValues(alpha: 0.30),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: text.bodyMedium?.copyWith(color: c.mutedForeground),
        labelStyle: text.bodyMedium?.copyWith(color: c.mutedForeground),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.destructive),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.ring, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.destructive)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.destructive, width: 1.5)),
        disabledBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.input.withValues(alpha: 0.5))),
        prefixIconColor: c.mutedForeground,
        suffixIconColor: c.mutedForeground,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.25),
        selectionHandleColor: c.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: c.input, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(c.primaryForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.input),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primaryForeground : c.background),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.input),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.muted,
        thumbColor: c.primary,
        overlayColor: c.primary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.muted,
        linearMinHeight: 4,
        circularTrackColor: Colors.transparent,
      ),

      // ── Overlays ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: c.popover,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl, side: BorderSide(color: c.ringSubtle)),
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        contentTextStyle: text.bodyMedium?.copyWith(color: c.mutedForeground),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.popover,
        modalBackgroundColor: c.popover,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: c.border,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          side: BorderSide(color: c.ringSubtle),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.popover,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: c.ringSubtle)),
        textStyle: text.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.popover),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: c.ringSubtle))),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.foreground, borderRadius: AppRadius.rMd),
        textStyle: text.bodySmall?.copyWith(color: c.background),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.popover,
        contentTextStyle: text.bodyMedium,
        actionTextColor: c.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: c.ringSubtle)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        headerBackgroundColor: c.primary,
        headerForegroundColor: c.primaryForeground,
        todayBorder: BorderSide(color: c.primary),
        todayForegroundColor: WidgetStatePropertyAll(c.primary),
        dayStyle: text.bodyMedium,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.popover,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
      ),

      // ── Tabs / chips / scroll ─────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: c.foreground,
        unselectedLabelColor: c.mutedForeground,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: c.primary,
        dividerColor: c.border,
        indicatorSize: TabBarIndicatorSize.label,
        overlayColor: WidgetStatePropertyAll(c.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.secondary,
        selectedColor: c.primary.withValues(alpha: 0.12),
        side: BorderSide(color: c.border),
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(AppRadius.full),
        thumbColor: WidgetStatePropertyAll(c.mutedForeground.withValues(alpha: 0.4)),
      ),
    );
  }

  static ButtonStyle _buttonStyle(AppColors c, {required Color bg, required Color fg}) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.control)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? bg.withValues(alpha: bg == Colors.transparent ? 0 : 0.5) : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? fg.withValues(alpha: 0.5) : fg,
      ),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.rLg)),
      textStyle: WidgetStatePropertyAll(
        const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

extension AppTextContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}

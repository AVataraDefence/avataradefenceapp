import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_avatar.dart';
import 'app_button.dart';

/// Top bar (web `Header`): back / menu, title, search, notification bell with unread
/// count, profile avatar. Hairline bottom border.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onMenu,
    this.onSearch,
    this.onNotifications,
    this.unread = 0,
    this.userName,
    this.avatarUrl,
    this.userId,
    this.onProfile,
    this.actions = const [],
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final int unread;
  final String? userName;
  final String? avatarUrl;
  final int? userId;
  final VoidCallback? onProfile;
  final List<Widget> actions;

  /// Brand-coloured bar: pass the primary colour and white to match the web's accent.
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = foregroundColor;
    return Material(
      color: backgroundColor ?? c.background,
      child: Container(
        height: preferredSize.height + MediaQuery.paddingOf(context).top,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, left: 4, right: 8),
        decoration: backgroundColor != null ? null : BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
        child: Row(
          children: [
            if (onBack != null)
              AppIconButton(icon: LucideIcons.arrowLeft, onPressed: onBack, tooltip: 'Back', color: fg)
            else if (onMenu != null)
              AppIconButton(icon: LucideIcons.menu, onPressed: onMenu, tooltip: 'Menu', color: fg)
            else
              const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: fg),
              ),
            ),
            ...actions,
            if (onSearch != null) AppIconButton(icon: LucideIcons.search, onPressed: onSearch, tooltip: 'Search'),
            if (onNotifications != null) AppIconButton(icon: LucideIcons.bell, onPressed: onNotifications, badge: unread, tooltip: 'Notifications'),
            if (userName != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4),
                child: GestureDetector(
                  onTap: onProfile,
                  child: AppAvatar(name: userName, imageUrl: avatarUrl, colorSeed: userId, size: AppAvatarSize.sm),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One destination in the bottom bar.
class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.selectedIcon});

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// Bottom navigation (the mobile counterpart of the web sidebar).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.index, required this.onChanged});

  final List<AppNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onChanged,
        destinations: [
          for (final i in items)
            NavigationDestination(icon: Icon(i.icon), selectedIcon: Icon(i.selectedIcon ?? i.icon), label: i.label),
        ],
      ),
    );
  }
}

/// Small caps section label inside menus (`OVERVIEW`, `TASKS`).
class AppMenuSection extends StatelessWidget {
  const AppMenuSection(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// Drawer / sidebar row. Selected = soft primary tint (web `ModuleSidebar` active item).
class AppMenuItem extends StatelessWidget {
  const AppMenuItem({super.key, required this.icon, required this.label, this.selected = false, this.onTap, this.count});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? (c.isDark ? c.primaryForeground : c.primary) : c.mutedForeground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? c.primary.withValues(alpha: c.isDark ? 0.25 : 0.10) : Colors.transparent,
        borderRadius: AppRadius.rLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? fg : c.foreground),
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: c.primary, borderRadius: AppRadius.rFull),
                    child: Text('$count', style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 11, fontWeight: FontWeight.w700, color: c.primaryForeground)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon tile of the module grid (web `/module` page): white rounded tile with
/// a coloured icon box inside.
class AppModuleTile extends StatelessWidget {
  const AppModuleTile({super.key, required this.icon, required this.label, required this.color, this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: c.isDark ? c.card : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.isDark ? c.border : const Color(0xFFE5E7EB)),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/nav.dart';
import '../../core/core.dart';
import '../../data/notifications_store.dart';
import '../../data/session.dart';
import 'sidebar_menu.dart';

/// Top bar (web `components/layout/Header.tsx`): back + title or brand, global search,
/// notifications and the profile menu.
class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key, this.title, this.backHref, this.hasSidebar = false});

  final String? title;
  final String? backHref;

  /// Shows the menu button that opens the module's side menu (the web sidebar).
  final bool hasSidebar;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Primary-coloured bar with white text and icons; the status bar icons go white too.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: AppHeader(
        title: title != null && backHref != null ? title! : 'Avatara Defence',
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        onBack: title != null && backHref != null ? () => AppNav.back(context, backHref!) : null,
        actions: [
          if (hasSidebar) AppIconButton(icon: LucideIcons.menu, tooltip: 'Menu', color: Colors.white, onPressed: () => Scaffold.of(context).openDrawer()),
          // Notifications live in the header; the unread count updates with every push.
          ListenableBuilder(
            listenable: NotificationsStore.instance,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AppIconButton(
                icon: LucideIcons.bell,
                tooltip: 'Notifications',
                color: Colors.white,
                badge: NotificationsStore.instance.unread,
                onPressed: () => openNotificationsSheet(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Global search (web: index built from menu-data) ──────────────────────────────
class _SearchResult {
  const _SearchResult(this.label, this.href, this.moduleLabel, this.isModule);
  final String label;
  final String href;
  final String moduleLabel;
  final bool isModule;
}

final _searchIndex = <_SearchResult>[
  for (final m in const [
    ('Employee', '/module/employee', employeeMenu),
    ('Master Data', '/module/master-data', masterDataMenu),
    ('Settings', '/module/settings', settingsMenu),
    ('Task Management', '/module/task-management', taskMenu),
    ('Organization', '/module/organization', organizationMenu),
    ('Projects', '/module/projects', projectsMenu),
  ]) ...[
    _SearchResult(m.$1, m.$2, m.$1, true),
    for (final g in m.$3)
      for (final i in g.items)
        if (i.href != null) _SearchResult(i.label, i.href!, m.$1, false),
  ],
  const _SearchResult('Calendar', '/module/calendar', 'Calendar', true),
  const _SearchResult('Notifications', '/module/notifications', 'Notifications', true),
];

void openSearchSheet(BuildContext context) {
  showAppSheet<void>(
    context,
    title: 'Search',
    maxHeightFactor: 0.85,
    builder: (ctx) => _SearchBody(onPick: (href) {
      Navigator.pop(ctx);
      AppNav.push(context, href);
    }),
  );
}

class _SearchBody extends StatefulWidget {
  const _SearchBody({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final q = _q.trim().toLowerCase();
    final results = q.isEmpty ? <_SearchResult>[] : _searchIndex.where((r) => r.label.toLowerCase().contains(q) || r.moduleLabel.toLowerCase().contains(q)).take(8).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: AppSearchField(hint: 'Search modules and pages', onChanged: (v) => setState(() => _q = v)),
        ),
        Flexible(
          child: q.isEmpty
              ? Padding(padding: const EdgeInsets.all(24), child: Text('Type to search pages', style: t.bodySmall))
              : results.isEmpty
                  ? Padding(padding: const EdgeInsets.all(24), child: Text('No results for "$_q"', style: t.bodySmall))
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      children: [
                        for (final r in results)
                          InkWell(
                            borderRadius: AppRadius.rMd,
                            onTap: () => widget.onPick(r.href),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Expanded(child: Text(r.label, style: t.bodyMedium)),
                                  if (!r.isModule) Text(r.moduleLabel, style: t.bodySmall?.copyWith(color: c.mutedForeground)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ── Notifications dropdown ───────────────────────────────────────────────────────
void openNotificationsSheet(BuildContext context) {
  final store = NotificationsStore.instance;
  showAppSheet<void>(
    context,
    maxHeightFactor: 0.85,
    builder: (ctx) => ListenableBuilder(
      listenable: store,
      builder: (ctx, _) {
        final c = ctx.colors;
        final t = Theme.of(ctx).textTheme;
        final items = store.items.take(6).toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text('Notifications', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: TwColors.emerald500, shape: BoxShape.circle)),
                  const Spacer(),
                  if (store.unread > 0)
                    AppButton(label: 'Mark all read', icon: LucideIcons.checkCheck, variant: AppButtonVariant.ghost, size: AppButtonSize.xs, onPressed: store.markAllRead),
                  const SizedBox(width: 6),
                  AppBadge.tinted('${store.unread} unread', color: c.primary, background: c.primary.withValues(alpha: 0.10)),
                ],
              ),
            ),
            const AppSeparator(),
            Flexible(
              child: items.isEmpty
                  ? Padding(padding: const EdgeInsets.all(32), child: Center(child: Text("You're all caught up.", style: t.bodySmall)))
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final n in items)
                          NotificationTile(
                            n: n,
                            onTap: () {
                              store.markRead(n.id);
                              Navigator.pop(ctx);
                              openNotificationUrl(context, n.url);
                            },
                          ),
                      ],
                    ),
            ),
            const AppSeparator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: AppButton(
                label: 'View all notifications',
                trailingIcon: LucideIcons.chevronRight,
                variant: AppButtonVariant.ghost,
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  AppNav.push(context, '/module/notifications');
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Row used by the bell sheet and the Notifications page.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.n, required this.onTap, this.trailing});

  final AppNotification n;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final style = notificationStyle(n.type);
    return InkWell(
      borderRadius: AppRadius.rLg,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: style.color.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(style.icon, size: 17, color: style.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(n.title, style: t.bodyMedium?.copyWith(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600, color: n.isRead ? c.mutedForeground : c.foreground))),
                      if (!n.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                  const SizedBox(height: 2),
                  Text(timeAgo(n.createdAt), style: t.bodySmall?.copyWith(fontSize: 11, color: c.mutedForeground.withValues(alpha: 0.8))),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ── Profile menu ─────────────────────────────────────────────────────────────────
void openProfileSheet(BuildContext context) {
  final session = AppSession.instance;
  showAppSheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      final t = Theme.of(ctx).textTheme;

      Widget row(IconData icon, String label, VoidCallback onTap, {bool destructive = false}) => InkWell(
            borderRadius: AppRadius.rMd,
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: destructive ? c.destructive : c.mutedForeground),
                  const SizedBox(width: 12),
                  Text(label, style: t.bodyMedium?.copyWith(color: destructive ? c.destructive : c.foreground)),
                ],
              ),
            ),
          );

      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                AppAvatar(name: session.userName, imageUrl: session.imageUrl, colorSeed: session.userId, size: AppAvatarSize.lg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.userName, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(session.email, style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AppSeparator(),
          const SizedBox(height: 4),
          row(LucideIcons.user, 'Profile', () => AppNav.push(context, '/module/settings/profile')),
          row(LucideIcons.settings, 'Account Settings', () => AppNav.push(context, '/module/settings')),
          row(
            c.isDark ? LucideIcons.sun : LucideIcons.moon,
            c.isDark ? 'Light mode' : 'Dark mode',
            () => ThemeScope.of(context).toggle(context),
          ),
          const AppSeparator(),
          const SizedBox(height: 4),
          row(LucideIcons.logOut, 'Logout', () {
            () async {
              await AppSession.instance.signOut();
              if (context.mounted) AppNav.reset(context, '/auth/signin');
            }();
          }, destructive: true),
        ],
      );
    },
  );
}

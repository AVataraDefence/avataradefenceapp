import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/layout/header.dart';
import '../../../components/layout/main_content.dart';
import '../../../core/core.dart';
import '../../../data/notifications_store.dart';
import '../../nav.dart';

const _pageSize = 8;

/// `/module/notifications` (web `notifications/page.tsx`).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final store = NotificationsStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;
        final totalPages = (items.length / _pageSize).ceil().clamp(1, 999);
        final page = _page.clamp(1, totalPages);
        final visible = items.skip((page - 1) * _pageSize).take(_pageSize).toList();
        return MainContent(
          title: 'Notifications',
          backHref: '/module',
          onRefresh: store.load,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                child: Row(
                  children: [
                    Text('Notifications', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    if (store.unread > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: c.primary, borderRadius: AppRadius.rFull),
                        alignment: Alignment.center,
                        child: Text('${store.unread}', style: TextStyle(color: c.primaryForeground, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const Spacer(),
                    AppButton(label: 'Mark all', icon: LucideIcons.checkCheck, variant: AppButtonVariant.outline, size: AppButtonSize.sm, onPressed: store.unread == 0 ? null : store.markAllRead),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: EdgeInsets.zero,
                child: store.loading && items.isEmpty
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: AppSpinner(size: 22)))
                    : items.isEmpty
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: AppEmpty(title: 'No notifications yet', icon: LucideIcons.bell))
                    : Column(
                        children: [
                          for (var i = 0; i < visible.length; i++) ...[
                            Container(
                              color: visible[i].isRead ? null : c.primary.withValues(alpha: 0.03),
                              child: NotificationTile(
                                n: visible[i],
                                onTap: () {
                                  store.markRead(visible[i].id);
                                  openNotificationUrl(context, visible[i].url);
                                },
                                trailing: visible[i].isRead ? null : AppIconButton(icon: LucideIcons.check, size: AppButtonSize.sm, tooltip: 'Mark as read', onPressed: () => store.markRead(visible[i].id)),
                              ),
                            ),
                            if (i < visible.length - 1) const AppSeparator(),
                          ],
                        ],
                      ),
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 16),
                AppPagination(page: page, totalPages: totalPages, onChanged: (p) => setState(() => _page = p)),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../components/list_card.dart';
import '../../../../core/core.dart';
import '../../../../data/app_api.dart';
import '../../../../data/directory.dart';

/// `/module/organization/org-hierarchy` — who reports to whom (web `org-hierarchy/page.tsx`).
class OrgHierarchyPage extends StatefulWidget {
  const OrgHierarchyPage({super.key});

  @override
  State<OrgHierarchyPage> createState() => _OrgHierarchyPageState();
}

class _OrgHierarchyPageState extends State<OrgHierarchyPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Directory.instance.addListener(_changed);
    _reload();
  }

  @override
  void dispose() {
    Directory.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    await Directory.instance.refresh('users');
    if (mounted) setState(() => _loading = false);
  }

  void _edit(Rec user) {
    String? value = user['reportsToUserId'] == null ? null : '${user['reportsToUserId']}';
    showAppSheet<void>(
      context,
      title: userFullName(user),
      description: '${user['roleName'] ?? ''}',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AppSelect<String>(
            label: 'Reports To',
            hint: 'No manager',
            options: [for (final o in userOptions()) if (o.value != '${user['userId']}') o],
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
      ),
      footer: Builder(
        builder: (ctx) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
            const SizedBox(width: 12),
            AppButton(
              label: 'Save',
              onPressed: () async {
                Navigator.pop(ctx);
                final r = await AppApi.client.put('/api/settings/users/${user['userId']}/reports-to', body: {'managerId': value == null ? null : int.parse(value!)});
                if (!mounted) return;
                if (r.ok) {
                  await Directory.instance.refresh('users');
                } else {
                  AppToast.error(context, r.message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final users = Directory.instance.users.where((u) => u['isActive'] == true).toList();
    return MainContent(
      title: 'Organization',
      backHref: '/module/organization',
      sidebarMenu: organizationMenu,
      onRefresh: _reload,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Org Hierarchy', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text("Assign each employee's reporting manager", style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading && users.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: AppSpinner(size: 24))),
          for (final u in users) ...[
            AppListCard(
              title: userFullName(u),
              subtitle: '@${u['username']}',
              leading: AppAvatar(name: userFullName(u), imageUrl: u['imageUrl'] as String?, colorSeed: u['userId'] as int, size: AppAvatarSize.md),
              badge: u['roleName'] == null ? null : AppBadge('${u['roleName']}', variant: AppBadgeVariant.secondary),
              onTap: () => _edit(u),
              trailing: AppIconButton(icon: LucideIcons.pencil, size: AppButtonSize.sm, tooltip: 'Edit', onPressed: () => _edit(u)),
              rows: [('Reports To', Text(u['reportsToUserId'] == null ? '—' : userNameById(u['reportsToUserId']), style: t.bodyMedium?.copyWith(fontSize: 13)))],
            ),
            const SizedBox(height: 10),
          ],
          Padding(padding: const EdgeInsets.fromLTRB(4, 2, 4, 0), child: Text('Showing ${users.length} employee${users.length == 1 ? '' : 's'}', style: t.bodySmall)),
        ],
      ),
    );
  }
}

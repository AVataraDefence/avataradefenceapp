import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/app_api.dart';
import '../../../../data/directory.dart';
import '../../modules_config.dart';

const _permissionTypes = <(String, String, String)>[
  ('view', 'View', 'Can view records.'),
  ('viewAll', 'View All', 'Can view all records.'),
  ('create', 'Create', 'Can create new records.'),
  ('update', 'Update', 'Can edit existing records.'),
  ('delete', 'Delete', 'Can delete records.'),
  ('approve', 'Approve', 'Can approve records or requests.'),
  ('reject', 'Reject', 'Can reject records or requests.'),
  ('assign', 'Assign', 'Can assign users, tasks, or records.'),
  ('import', 'Import', 'Can import data from Excel, CSV, or other supported formats.'),
  ('export', 'Export', 'Can export data to Excel, PDF, CSV, or other supported formats.'),
];

/// Menu items per module (web: `menu-data.json`).
final _moduleItems = <String, List<(String, String)>>{
  'employee': [for (final g in employeeMenu) for (final i in g.items) (i.id, i.label)],
  'masterData': [for (final g in masterDataMenu) for (final i in g.items) (i.id, i.label)],
  'settings': [for (final g in settingsMenu) for (final i in g.items) (i.id, i.label)],
  'taskManagement': [for (final g in taskMenu) for (final i in g.items) (i.id, i.label)],
  'organization': [for (final g in organizationMenu) for (final i in g.items) (i.id, i.label)],
  'projects': [for (final g in projectsMenu) for (final i in g.items) (i.id, i.label)],
  'notifications': const [('alerts', 'Alerts'), ('reminders', 'Reminders'), ('preferences', 'Preferences')],
  'calendar': const [('month', 'Month'), ('week', 'Week'), ('day', 'Day'), ('events', 'Events'), ('meetings', 'Meetings'), ('holidays', 'Holidays')],
};

/// `/module/settings/permissions` (web `settings/permissions/page.tsx`).
class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  String? _roleId;
  bool _loading = true;
  String _error = '';
  // moduleId → itemId → allowed (for the selected role)
  Map<String, Map<String, bool>> _access = {};
  Map<String, bool> _perms = {for (final p in _permissionTypes) p.$1: false};

  @override
  void initState() {
    super.initState();
    Directory.instance.addListener(_changed);
    _init();
  }

  @override
  void dispose() {
    Directory.instance.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    await Directory.instance.refresh('roles');
    final roles = roleOptions();
    if (!mounted) return;
    if (roles.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No roles found.';
      });
      return;
    }
    _roleId = roles.first.value;
    await _loadRole();
  }

  Future<void> _loadRole() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final r = await AppApi.client.get(ApiEndpoints.settingsPermissions, query: {'roleId': _roleId!});
    if (!mounted) return;
    final rows = asRows(r);
    final access = <String, Map<String, bool>>{
      for (final e in _moduleItems.entries) e.key: {for (final i in e.value) i.$1: false},
    };
    Map<String, dynamic>? representative;
    for (final row in rows) {
      final m = row['modulename'] as String?;
      if (m == null) continue;
      for (final it in (row['menuitemaccess'] as List? ?? const [])) {
        if (it is Map) access.putIfAbsent(m, () => {})['${it['id']}'] = it['access'] == 'Y';
      }
      representative ??= row['permissiontype'] is Map ? Map<String, dynamic>.from(row['permissiontype'] as Map) : null;
    }
    setState(() {
      _loading = false;
      if (!r.ok) _error = r.message;
      _access = access;
      _perms = {for (final p in _permissionTypes) p.$1: representative?[p.$1] == true};
    });
  }

  Future<void> _persistModule(String moduleId) async {
    final items = _moduleItems[moduleId] ?? const [];
    final map = _access[moduleId] ?? {};
    final r = await AppApi.client.put(ApiEndpoints.settingsPermissions, body: {
      'roleId': int.parse(_roleId!),
      'modulename': moduleId,
      'modulenameaccess': items.any((i) => map[i.$1] == true) ? 'Y' : 'N',
      'menuitemaccess': [for (final i in items) {'id': i.$1, 'label': i.$2, 'access': map[i.$1] == true ? 'Y' : 'N'}],
    });
    if (!r.ok && mounted) AppToast.error(context, r.message);
  }

  void _openModule(ModuleConfig m) {
    final items = _moduleItems[m.id] ?? const <(String, String)>[];
    showAppSheet<void>(
      context,
      title: m.label,
      description: 'Set permissions for each menu item',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final map = _access.putIfAbsent(m.id, () => {});
          final all = items.isNotEmpty && items.every((i) => map[i.$1] == true);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (items.isEmpty) const AppEmpty(title: 'No menu items', description: 'This module has no pages yet.'),
              if (items.isNotEmpty)
                AppCheckbox(
                  value: all,
                  label: 'Select All',
                  onChanged: (v) {
                    for (final i in items) {
                      map[i.$1] = v;
                    }
                    set(() {});
                    setState(() {});
                    _persistModule(m.id);
                  },
                ),
              for (final i in items) ...[
                const SizedBox(height: 4),
                AppCheckbox(
                  value: map[i.$1] == true,
                  label: i.$2,
                  onChanged: (v) {
                    map[i.$1] = v;
                    set(() {});
                    setState(() {});
                    _persistModule(m.id);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openSettings() {
    final role = Directory.instance.roles.firstWhere((r) => '${r['roleId']}' == _roleId);
    final draft = Map<String, bool>.of(_perms);
    showAppSheet<void>(
      context,
      title: '${role['name']}',
      description: 'Configure permission types for this role, applied across every module',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            AppCheckbox(
              value: draft.values.every((v) => v),
              label: 'Select All',
              onChanged: (v) => set(() {
                for (final p in _permissionTypes) {
                  draft[p.$1] = v;
                }
              }),
            ),
            for (final p in _permissionTypes) ...[
              const SizedBox(height: 4),
              AppCheckbox(value: draft[p.$1] == true, label: p.$2, description: p.$3, onChanged: (v) => set(() => draft[p.$1] = v)),
            ],
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Builder(builder: (ctx) => AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx))),
          const SizedBox(width: 12),
          Builder(
            builder: (ctx) => AppButton(
              label: 'Save Settings',
              onPressed: () async {
                Navigator.pop(ctx);
                // The schema stores permission types per module, so apply them to every module row.
                final results = await Future.wait([
                  for (final m in activeModulesConfig)
                    AppApi.client.put(ApiEndpoints.settingsPermissions, body: {'roleId': int.parse(_roleId!), 'modulename': m.id, 'permissiontype': draft}),
                ]);
                if (!mounted) return;
                final failed = results.where((r) => !r.ok).firstOrNull;
                if (failed != null) {
                  AppToast.error(context, failed.message);
                } else {
                  setState(() => _perms = draft);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final granted = _perms.values.where((v) => v).length;
    return MainContent(
      title: 'Settings',
      backHref: '/module',
      sidebarMenu: settingsMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Permissions', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Configure module access for each role', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppSelect<String>(
            options: roleOptions(),
            value: _roleId,
            hint: Directory.instance.roles.isEmpty ? 'Loading roles…' : 'Select role',
            sheetTitle: 'Select role',
            onChanged: (v) {
              setState(() => _roleId = v);
              _loadRole();
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            label: granted > 0 ? 'Permission Setting  ·  $granted' : 'Permission Setting',
            icon: LucideIcons.settings,
            expand: true,
            onPressed: _roleId == null || _loading ? null : _openSettings,
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[AppAlert(title: _error, variant: AppAlertVariant.destructive), const SizedBox(height: 16)],
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: AppSpinner(size: 24)))
          else
            LayoutBuilder(
              builder: (context, box) {
                final cols = box.maxWidth >= 600 ? 6 : (box.maxWidth >= 330 ? 4 : 3);
                final w = (box.maxWidth - (cols - 1) * 12) / cols;
                return Wrap(
                  spacing: 12,
                  runSpacing: 18,
                  children: [
                    for (final m in activeModulesConfig)
                      SizedBox(
                        width: w,
                        child: Builder(builder: (context) {
                          final count = (_access[m.id] ?? const {}).values.where((v) => v).length;
                          return Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              AppModuleTile(icon: m.icon, label: m.label, color: m.color, onTap: () => _openModule(m)),
                              if (count > 0)
                                Positioned(
                                  top: -6,
                                  right: w / 2 - 36,
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(color: c.primary, borderRadius: AppRadius.rFull),
                                    alignment: Alignment.center,
                                    child: Text('$count', style: TextStyle(color: c.primaryForeground, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../core/core.dart';
import 'sidebar_menu.dart';

/// Module side menu (web `ModuleSidebar`). On a phone it slides in as a drawer from the
/// header's menu button; the active page is tinted like the web's active item.
class ModuleSidebar extends StatelessWidget {
  const ModuleSidebar({super.key, required this.menu, required this.title});

  final List<SidebarGroup> menu;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final current = ModalRoute.of(context)?.settings.name;
    return Drawer(
      backgroundColor: c.background,
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
              child: Text('Menu', style: Theme.of(context).textTheme.titleSmall),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final section in menu) ...[
                    if (section.group != null) AppMenuSection(section.group!),
                    for (final item in section.items)
                      AppMenuItem(
                        icon: item.icon,
                        label: item.label,
                        selected: item.href == current,
                        onTap: item.disabled || item.href == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                if (item.href != current) AppNav.replace(context, item.href!);
                              },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../core/core.dart';
import '../../data/session.dart';
import 'main_content.dart';
import 'sidebar_menu.dart';

/// Icon-tile grid every module landing page shows (web: the `COLOR_MAP` + `Link` grid on
/// `/module`, `/module/employee`, `/module/task-management`, …).
class ModuleTileGrid extends StatelessWidget {
  const ModuleTileGrid({super.key, required this.tiles});

  final List<({IconData icon, String label, Color color, String? href, bool disabled})> tiles;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 600 ? 6 : (box.maxWidth >= 330 ? 4 : 3);
              final tileW = (box.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 18,
                children: [
                  for (final t in tiles)
                    SizedBox(
                      width: tileW,
                      child: Opacity(
                        opacity: t.disabled ? 0.5 : 1,
                        child: AppModuleTile(
                          icon: t.icon,
                          label: t.label,
                          color: t.color,
                          onTap: t.disabled || t.href == null ? null : () => AppNav.push(context, t.href!),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A module's landing page: every item of its menu as a tile.
class ModuleLandingPage extends StatelessWidget {
  const ModuleLandingPage({super.key, required this.title, required this.menu});

  final String title;
  final List<SidebarGroup> menu;

  @override
  Widget build(BuildContext context) {
    return MainContent(
      title: title,
      backHref: '/module',
      sidebarMenu: menu,
      onRefresh: AppSession.instance.reloadAll,
      child: ModuleTileGrid(
        tiles: [
          for (final g in visibleMenu(menu))
            for (final i in g.items) (icon: i.icon, label: i.label, color: i.color, href: i.href, disabled: i.disabled),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/nav.dart';
import '../../core/core.dart';
import 'header.dart';
import '../../data/session.dart';
import 'module_sidebar.dart';
import 'sidebar_menu.dart';

/// Page shell (web `components/layout/MainContent.tsx`): header, optional module sidebar
/// (a drawer on phones), scrolling content and the footer line.
class MainContent extends StatelessWidget {
  const MainContent({
    super.key,
    required this.child,
    this.title,
    this.backHref,
    this.sidebarMenu,
    this.scroll = true,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
    this.floatingActionButton,
    this.onRefresh,
    this.backgroundImage,
  });

  final Widget child;
  final String? title;
  final String? backHref;
  final List<SidebarGroup>? sidebarMenu;

  /// Wrap [child] in a vertical scroll view. Turn off when the child scrolls itself.
  final bool scroll;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;

  /// Pull-to-refresh handler (scrolling pages only).
  final Future<void> Function()? onRefresh;

  /// Asset shown behind the content (light mode only; dark mode keeps the plain background).
  final String? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final menu = sidebarMenu == null ? null : visibleMenu(sidebarMenu!);
    return Scaffold(
      backgroundColor: c.isDark ? const Color(0xFF18181B) : Color.alphaBlend(c.muted.withValues(alpha: 0.30), Colors.white),
      appBar: Header(title: title, backHref: backHref, hasSidebar: sidebarMenu != null),
      drawer: menu == null ? null : ModuleSidebar(menu: menu, title: title ?? ''),
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: backgroundImage == null || c.isDark ? null : DecorationImage(image: AssetImage(backgroundImage!), fit: BoxFit.cover, alignment: Alignment.topCenter, colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: 0.45), BlendMode.srcATop)),
              ),
              child: scroll
                ? (onRefresh == null
                    ? SingleChildScrollView(padding: padding, child: child)
                    : RefreshIndicator(onRefresh: onRefresh!, child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: padding, child: child)))
                : Padding(padding: padding, child: child),
            ),
          ),
          const _BottomBar(),
        ],
      ),
    );
  }
}

/// Bottom bar (replaces the web footer text): home, search, chat and profile.
class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = AppSession.instance;
    final onHome = ModalRoute.of(context)?.settings.name == '/module';

    Widget item(Widget child, String label, VoidCallback onTap) => Expanded(
          child: Semantics(
            button: true,
            label: label,
            child: InkWell(onTap: onTap, child: SizedBox(height: 52, child: Center(child: child))),
          ),
        );

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(color: c.isDark ? const Color(0xFF18181B) : Colors.white, border: Border(top: BorderSide(color: c.border))),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Row(
          children: [
            item(Icon(LucideIcons.house, size: 24, color: onHome ? c.primary : c.mutedForeground), 'Home', () {
              if (!onHome) AppNav.reset(context, '/module');
            }),
            item(Icon(LucideIcons.search, size: 24, color: c.mutedForeground), 'Search', () => openSearchSheet(context)),
            item(Icon(LucideIcons.messageCircle, size: 24, color: c.mutedForeground), 'Chat', () => _openChat(context)),
            item(AppAvatar(name: session.userName, imageUrl: session.imageUrl, colorSeed: session.userId, size: AppAvatarSize.sm), 'Profile', () => openProfileSheet(context)),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    showAppSheet<void>(
      context,
      title: 'Chat',
      builder: (ctx) => const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 32), child: AppEmpty(title: 'Chat is coming soon', description: 'Team messaging will appear here.', icon: LucideIcons.messageCircle)),
    );
  }
}

/// A module menu limited to the pages the signed-in role may open.
List<SidebarGroup> visibleMenu(List<SidebarGroup> menu) {
  final key = moduleKeyForMenu(menu);
  if (key == null) return menu;
  final session = AppSession.instance;
  return [
    for (final g in menu)
      if (g.items.any((i) => session.canViewMenuItem(key, i.id)))
        SidebarGroup(group: g.group, items: [for (final i in g.items) if (session.canViewMenuItem(key, i.id)) i]),
  ];
}

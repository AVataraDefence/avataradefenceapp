import 'package:flutter/material.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/directory.dart';

/// `/module/organization/org-chart` — reporting tree (web `org-chart/page.tsx`).
class OrgChartPage extends StatelessWidget {
  const OrgChartPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: Directory.instance, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final users = Directory.instance.users.where((u) => u['isActive'] == true).toList();
    final ids = users.map((u) => u['userId']).toSet();
    final roots = users.where((u) => u['reportsToUserId'] == null || !ids.contains(u['reportsToUserId'])).toList();
    return MainContent(
      title: 'Organization',
      backHref: '/module/organization',
      sidebarMenu: organizationMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Org Chart', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Visual reporting structure across the organization', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (users.isEmpty)
            Center(child: Text('No employees found.', style: t.bodyMedium))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final r in roots) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _OrgNode(user: r, users: users))],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrgNode extends StatelessWidget {
  const _OrgNode({required this.user, required this.users});

  final Rec user;
  final List<Rec> users;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final children = users.where((u) => u['reportsToUserId'] == user['userId']).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 144,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                AppAvatar(name: userFullName(user), imageUrl: user['imageUrl'] as String?, colorSeed: user['userId'] as int, size: AppAvatarSize.lg),
                const SizedBox(height: 8),
                Text(userFullName(user), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.foreground, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (children.isNotEmpty) ...[
          Container(width: 1, height: 24, color: c.border),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++)
                  CustomPaint(
                    painter: _Connector(color: c.border, first: i == 0, last: i == children.length - 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 1, height: 24, color: c.border),
                          _OrgNode(user: children[i], users: users),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The horizontal bar joining sibling nodes (starts/ends at the centre for the outer two).
class _Connector extends CustomPainter {
  _Connector({required this.color, required this.first, required this.last});

  final Color color;
  final bool first;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1;
    canvas.drawLine(Offset(first ? size.width / 2 : 0, 0), Offset(last ? size.width / 2 : size.width, 0), p);
  }

  @override
  bool shouldRepaint(covariant _Connector old) => old.color != color || old.first != first || old.last != last;
}

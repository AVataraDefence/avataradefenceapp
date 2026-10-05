import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';

/// `/module/task-management/reports` — "Coming soon" placeholder, like the web.
class TaskReportsPage extends StatelessWidget {
  const TaskReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainContent(
      title: 'Task Management',
      backHref: '/module/task-management',
      sidebarMenu: taskMenu,
      scroll: false,
      child: Center(child: AppEmpty(title: 'Task Reports', description: 'Coming soon', icon: LucideIcons.chartColumn)),
    );
  }
}

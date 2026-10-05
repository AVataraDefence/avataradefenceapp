import 'package:flutter/material.dart';

import '../task_board.dart';

/// `/module/task-management/all` — view-only overview with status / priority filters.
class AllTasksPage extends StatelessWidget {
  const AllTasksPage({super.key});

  @override
  Widget build(BuildContext context) => const TaskBoard(scope: TaskScope.all);
}

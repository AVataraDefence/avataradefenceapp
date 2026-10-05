import 'package:flutter/material.dart';

import '../task_board.dart';

/// `/module/task-management/assigned` — tasks I created, with approve / reject.
class AssignedTasksPage extends StatelessWidget {
  const AssignedTasksPage({super.key});

  @override
  Widget build(BuildContext context) => const TaskBoard(scope: TaskScope.assigned);
}

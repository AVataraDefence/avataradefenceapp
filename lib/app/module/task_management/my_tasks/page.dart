import 'package:flutter/material.dart';

import '../task_board.dart';

/// `/module/task-management/my-tasks`.
class MyTasksPage extends StatelessWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context) => const TaskBoard(scope: TaskScope.mine);
}

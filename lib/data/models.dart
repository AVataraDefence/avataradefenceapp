import '../core/core.dart';
import 'directory.dart';

// ── API ⇄ enum values ────────────────────────────────────────────────────────────
extension TaskStatusApi on TaskStatus {
  String get api => switch (this) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'inprogress',
        TaskStatus.onHold => 'onhold',
        TaskStatus.review => 'review',
        TaskStatus.done => 'done',
        TaskStatus.cancelled => 'cancelled',
      };

  static TaskStatus parse(Object? v) => TaskStatus.values.firstWhere((s) => s.api == v, orElse: () => TaskStatus.todo);
}

extension TaskPriorityApi on TaskPriority {
  static TaskPriority parse(Object? v) => TaskPriority.values.firstWhere((p) => p.label == v, orElse: () => TaskPriority.low);
}

extension ProjectStatusApi on ProjectStatus {
  String get api => switch (this) {
        ProjectStatus.planning => 'planning',
        ProjectStatus.active => 'active',
        ProjectStatus.onHold => 'onhold',
        ProjectStatus.completed => 'completed',
        ProjectStatus.cancelled => 'cancelled',
      };

  static ProjectStatus parse(Object? v) => ProjectStatus.values.firstWhere((s) => s.api == v, orElse: () => ProjectStatus.planning);
}

DateTime? parseDate(Object? v) {
  if (v == null || '$v'.isEmpty) return null;
  final d = DateTime.tryParse('$v');
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A task as returned by `/api/tasks` (web `ApiTask`).
class TaskItem {
  TaskItem.fromJson(Map<String, dynamic> j)
      : id = (j['taskId'] as num).toInt(),
        code = '${j['taskCode'] ?? ''}',
        title = '${j['title'] ?? ''}',
        description = '${j['description'] ?? ''}',
        projectId = (j['projectId'] as num?)?.toInt(),
        projectName = j['projectName'] as String?,
        priority = TaskPriorityApi.parse(j['priority']),
        status = TaskStatusApi.parse(j['status']),
        start = parseDate(j['startDate']),
        due = parseDate(j['dueDate']),
        createdBy = (j['createdBy'] as num?)?.toInt(),
        createdByName = j['createdByName'] as String?,
        assignees = [for (final a in (j['assignees'] as List? ?? const [])) (id: (a['userId'] as num).toInt(), name: '${a['name']}')],
        checklistDone = (j['checklistDone'] as num?)?.toInt() ?? 0,
        checklistTotal = (j['checklistTotal'] as num?)?.toInt() ?? 0,
        commentCount = (j['commentCount'] as num?)?.toInt() ?? 0,
        docCount = (j['docCount'] as num?)?.toInt() ?? 0,
        canApprove = j['canApprove'] == true,
        canEdit = j['canEdit'] == true,
        canDelete = j['canDelete'] == true;

  final int id;
  final String code;
  String title;
  String description;
  int? projectId;
  String? projectName;
  TaskPriority priority;
  TaskStatus status;
  DateTime? start;
  DateTime? due;
  int? createdBy;
  String? createdByName;
  List<({int id, String name})> assignees;
  int checklistDone;
  int checklistTotal;
  int commentCount;
  int docCount;
  bool canApprove;
  bool canEdit;
  bool canDelete;

  /// 0–100, same roll-up rule as the web `taskProgress()`.
  double get progress {
    if (status == TaskStatus.done) return 100;
    if (status == TaskStatus.review) return 80;
    final stage = (status == TaskStatus.inProgress || status == TaskStatus.onHold) ? 0.3 : 0.0;
    final checklist = checklistTotal > 0 ? 0.8 * (checklistDone / checklistTotal) : 0.0;
    return ((stage > checklist ? stage : checklist) * 100).roundToDouble();
  }

  bool get overdue => toCard().overdue;

  void copyFrom(TaskItem o) {
    title = o.title;
    description = o.description;
    projectId = o.projectId;
    projectName = o.projectName;
    priority = o.priority;
    status = o.status;
    start = o.start;
    due = o.due;
    assignees = o.assignees;
    checklistDone = o.checklistDone;
    checklistTotal = o.checklistTotal;
    commentCount = o.commentCount;
    docCount = o.docCount;
    canApprove = o.canApprove;
    canEdit = o.canEdit;
    canDelete = o.canDelete;
  }

  TaskCardData toCard() => TaskCardData(
        code: code,
        title: title,
        description: description,
        projectName: projectName ?? projectNameById(projectId),
        priority: priority,
        status: status,
        assignees: [for (final a in assignees) (name: a.name, id: a.id)],
        dueDate: due,
        progress: progress,
      );
}

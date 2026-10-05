import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/page_heading.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../components/list_card.dart';
import '../../../../core/core.dart';
import '../../../../data/app_api.dart';
import '../../../../data/directory.dart';
import '../../../../data/models.dart';

const _critical = Color(0xFFD03B3B);
const _statusColor = <TaskStatus, Color>{
  TaskStatus.todo: Color(0xFF432DD7),
  TaskStatus.inProgress: Color(0xFFEB6834),
  TaskStatus.onHold: Color(0xFF1BAF7A),
  TaskStatus.review: Color(0xFFEDA100),
  TaskStatus.cancelled: Color(0xFFE87BA4),
  TaskStatus.done: Color(0xFF008300),
};

/// `/module/task-management/dashboard` — flat, Power BI style: slicers on top, KPI strip,
/// then charts separated by rules instead of cards (web `dashboard/page.tsx`).
class TaskDashboardPage extends StatefulWidget {
  const TaskDashboardPage({super.key});

  @override
  State<TaskDashboardPage> createState() => _TaskDashboardPageState();
}

class _TaskDashboardPageState extends State<TaskDashboardPage> {
  List<TaskItem> _tasks = [];
  List<({int id, String name})> _team = [];
  bool _loading = true;
  String _error = '';
  int? _project;
  int? _assignee;
  TaskStatus? _status;
  TaskPriority? _priority;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Future.wait([AppApi.client.get(ApiEndpoints.tasks, query: {'scope': 'all'}), AppApi.client.get(ApiEndpoints.taskTeam)]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res[0].ok ? '' : res[0].message;
      _tasks = [for (final x in asRows(res[0])) TaskItem.fromJson(x)];
      _team = [for (final u in asRows(res[1])) (id: (u['userId'] as num).toInt(), name: '${u['name']}')];
    });
  }

  bool _closed(TaskItem t) => t.status.isClosed;
  int _daysUntil(DateTime d) => d.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
  bool _overdue(TaskItem t) => t.due != null && !_closed(t) && _daysUntil(t.due!) < 0;

  List<TaskItem> get _filtered => _tasks.where((t) {
        if (_project != null && t.projectId != _project) return false;
        if (_assignee != null && !t.assignees.any((a) => a.id == _assignee)) return false;
        if (_status != null && t.status != _status) return false;
        if (_priority != null && t.priority != _priority) return false;
        return true;
      }).toList();

  /// The four slicers (project, assignee, status, priority) in one bottom sheet.
  void _openFilters() {
    Widget slicer<T>(String label, List<AppOption<T>> options, T? value, ValueChanged<T?> onChanged) {
      const all = 'all';
      return AppSelect<Object>(
        label: label,
        hint: 'All',
        options: [const AppOption(value: all, label: 'All'), for (final o in options) AppOption(value: o.value as Object, label: o.label)],
        value: value ?? all,
        onChanged: (v) => onChanged(v == all ? null : v as T),
      );
    }

    showAppSheet<void>(
      context,
      title: 'Filters',
      description: 'Narrow every chart and number below.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          void update(VoidCallback f) {
            setState(f);
            set(() {});
          }

          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              slicer<int>('Project', [for (final p in {for (final x in _tasks) if (x.projectId != null) x.projectId!: x.projectName ?? ''}.entries) AppOption(value: p.key, label: p.value)], _project, (v) => update(() => _project = v)),
              const SizedBox(height: 14),
              slicer<int>('Assignee', [for (final u in _team) AppOption(value: u.id, label: u.name)], _assignee, (v) => update(() => _assignee = v)),
              const SizedBox(height: 14),
              slicer<TaskStatus>('Status', [for (final s in TaskStatus.values) AppOption(value: s, label: s.label)], _status, (v) => update(() => _status = v)),
              const SizedBox(height: 14),
              slicer<TaskPriority>('Priority', [for (final p in TaskPriority.values) AppOption(value: p, label: p.label)], _priority, (v) => update(() => _priority = v)),
            ],
          );
        },
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Reset',
              variant: AppButtonVariant.outline,
              onPressed: () => setState(() {
                _project = _assignee = null;
                _status = null;
                _priority = null;
                Navigator.pop(context);
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Builder(builder: (ctx) => AppButton(label: 'Apply', onPressed: () => Navigator.pop(ctx)))),
        ],
      ),
    );
  }

  Widget _visual(BuildContext context, String title, String sub, Widget child) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          Text(sub, style: t.bodySmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    if (_loading) return const MainContent(title: 'Task Management', backHref: '/module/task-management', sidebarMenu: taskMenu, child: Padding(padding: EdgeInsets.symmetric(vertical: 80), child: Center(child: AppSpinner(size: 24))));
    final tasks = _filtered;
    final total = tasks.length;
    final open = tasks.where((x) => !_closed(x)).length;
    final inProgress = tasks.where((x) => x.status == TaskStatus.inProgress).length;
    final overdue = tasks.where(_overdue).length;
    final done = tasks.where((x) => x.status == TaskStatus.done).length;
    final nonCancelled = tasks.where((x) => x.status != TaskStatus.cancelled).length;
    final pct = nonCancelled == 0 ? 0 : (done / nonCancelled * 100).round();
    final primary = c.primary;

    // due-date buckets for open work
    final buckets = <String, int>{'Overdue': 0, 'This week': 0, 'Next week': 0, 'Week 3': 0, 'Week 4': 0, 'Later': 0};
    for (final x in tasks.where((x) => !_closed(x) && x.due != null)) {
      final d = _daysUntil(x.due!);
      final key = d < 0 ? 'Overdue' : d < 7 ? 'This week' : d < 14 ? 'Next week' : d < 21 ? 'Week 3' : d < 28 ? 'Week 4' : 'Later';
      buckets[key] = buckets[key]! + 1;
    }
    final byAssignee = <int, ({int open, int done})>{};
    for (final x in tasks) {
      for (final a in x.assignees.map((a) => a.id)) {
        final cur = byAssignee[a] ?? (open: 0, done: 0);
        byAssignee[a] = x.status == TaskStatus.done ? (open: cur.open, done: cur.done + 1) : (open: cur.open + 1, done: cur.done);
      }
    }
    final byProject = <String, int>{};
    for (final x in tasks) {
      final k = (x.projectName ?? '').isEmpty ? 'No project' : x.projectName!;
      byProject[k] = (byProject[k] ?? 0) + 1;
    }
    final attention = (tasks.where((x) => !_closed(x) && x.due != null).toList()..sort((a, b) => a.due!.compareTo(b.due!))).take(8).toList();

    Widget kpi(String label, String value, {String? sub, bool critical = false, IconData? icon, Color? accent}) {
      final tone = critical ? _critical : (accent ?? c.primary);
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.rXl, border: Border.all(color: critical ? _critical.withValues(alpha: 0.4) : c.border.withValues(alpha: 0.8))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 30, height: 30, decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: AppRadius.rMd), child: Icon(icon ?? LucideIcons.chartColumn, size: 16, color: tone)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: critical ? _critical : c.foreground, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
            if (sub != null) Text(sub, style: t.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      );
    }

    final activeFilters = [_project, _assignee, _status, _priority].where((x) => x != null).length;

    return MainContent(
      title: 'Task Management',
      backHref: '/module/task-management',
      sidebarMenu: taskMenu,
      onRefresh: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error.isNotEmpty) ...[AppAlert(title: _error, variant: AppAlertVariant.destructive), const SizedBox(height: 12)],
          PageHeading(
            title: 'Task Dashboard',
            subtitle: 'Overview of tasks across your team',
            action: Stack(
              clipBehavior: Clip.none,
              children: [
                AppButton(label: 'Filters', icon: LucideIcons.slidersHorizontal, variant: AppButtonVariant.outline, size: AppButtonSize.sm, onPressed: _openFilters),
                if (activeFilters > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.background, width: 2)),
                      child: Text('$activeFilters', style: TextStyle(color: c.primaryForeground, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: [
              kpi('Total tasks', '$total', sub: '$open still open', icon: LucideIcons.listTodo),
              kpi('In progress', '$inProgress', icon: LucideIcons.loader, accent: _statusColor[TaskStatus.inProgress]),
              kpi('Overdue', '$overdue', sub: overdue > 0 ? 'needs attention' : 'all on track', critical: overdue > 0, icon: LucideIcons.triangleAlert),
              kpi('Completed', '$done', icon: LucideIcons.circleCheck, accent: _statusColor[TaskStatus.done]),
            ],
          ),
          const SizedBox(height: 10),
          kpi('Completion', '$pct%', sub: 'of non-cancelled tasks', icon: LucideIcons.chartPie),
          const SizedBox(height: 20),
          _visual(
            context,
            'Tasks by status',
            'Share of all tasks',
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CustomPaint(
                    painter: _DonutPainter([for (final s in TaskStatus.values) (tasks.where((x) => x.status == s).length.toDouble(), _statusColor[s]!)], c.card),
                    child: Center(child: Text('$total', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600))),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final s in TaskStatus.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(width: 9, height: 9, decoration: BoxDecoration(color: _statusColor[s], borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s.label, style: t.bodyMedium?.copyWith(fontSize: 13))),
                            Text('${tasks.where((x) => x.status == s).length}', style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _visual(
            context,
            'Tasks by priority',
            'Darker = more urgent',
            _VBars(
              height: 150,
              bars: [
                for (var i = 0; i < TaskPriority.values.length; i++)
                  (TaskPriority.values[i].label, tasks.where((x) => x.priority == TaskPriority.values[i]).length.toDouble(), Color.lerp(primary.withValues(alpha: 0.35), primary, (i + 1) / 4)!),
              ],
            ),
          ),
          _visual(
            context,
            'Open work by due date',
            'Tasks not yet done',
            _VBars(height: 150, bars: [for (final e in buckets.entries) (e.key, e.value.toDouble(), e.key == 'Overdue' ? _critical : primary)]),
          ),
          _visual(
            context,
            'Workload by person',
            'Open vs completed tasks per assignee',
            Column(
              children: [
                for (final e in byAssignee.entries)
                  _HBar(label: _teamName(e.key, _tasks), segments: [(e.value.open.toDouble(), primary), (e.value.done.toDouble(), const Color(0xFF008300))], max: byAssignee.values.fold<int>(1, (m, v) => math.max(m, v.open + v.done)).toDouble()),
                if (byAssignee.isEmpty) Text('No assigned tasks.', style: t.bodySmall),
              ],
            ),
          ),
          _visual(
            context,
            'Tasks by project',
            'Top projects by task count',
            Column(
              children: [
                for (final e in byProject.entries) _HBar(label: e.key, segments: [(e.value.toDouble(), primary)], max: byProject.values.fold<int>(1, math.max).toDouble()),
                if (byProject.isEmpty) Text('No tasks.', style: t.bodySmall),
              ],
            ),
          ),
          _visual(
            context,
            'Needs attention',
            'Open tasks, soonest due date first',
            attention.isEmpty
                ? Text('Nothing open with a due date.', style: t.bodyMedium)
                : Column(
                    children: [
                      for (final x in attention) ...[
                        AppListCard(
                          title: x.title,
                          subtitle: x.code,
                          trailing: Padding(padding: const EdgeInsets.only(right: 8, top: 2), child: TaskPriorityBadge(x.priority)),
                          rows: [
                            ('Assignee', Text(x.assignees.isEmpty ? '—' : x.assignees.first.name + (x.assignees.length > 1 ? ' +${x.assignees.length - 1}' : ''), style: t.bodyMedium?.copyWith(fontSize: 13))),
                            ('Project', Text((x.projectName ?? '').isEmpty ? '—' : x.projectName!, style: t.bodyMedium?.copyWith(fontSize: 13))),
                            ('Status', TaskStatusBadge(x.status)),
                            (
                              'Due',
                              _overdue(x)
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(LucideIcons.triangleAlert, size: 13, color: _critical),
                                      const SizedBox(width: 4),
                                      Text('Overdue · ${formatAppDate(x.due!)}', style: t.bodyMedium?.copyWith(fontSize: 13, color: _critical, fontWeight: FontWeight.w500)),
                                    ])
                                  : Text(formatAppDate(x.due!), style: t.bodyMedium?.copyWith(fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.gap);

  final List<(double, Color)> slices;
  final Color gap;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (a, s) => a + s.$1);
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - 10);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;
    if (total == 0) {
      paint.color = gap.withValues(alpha: 0.4);
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
      return;
    }
    var start = -math.pi / 2;
    for (final s in slices) {
      if (s.$1 == 0) continue;
      final sweep = s.$1 / total * math.pi * 2;
      paint.color = s.$2;
      canvas.drawArc(rect, start, math.max(0, sweep - 0.03), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

/// Vertical bar chart with the value above each bar and the label below.
class _VBars extends StatelessWidget {
  const _VBars({required this.bars, required this.height});

  final List<(String, double, Color)> bars;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final max = bars.fold<double>(1, (m, b) => math.max(m, b.$2));
    return SizedBox(
      height: height + 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in bars)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(b.$2.round().toString(), style: t.bodySmall?.copyWith(fontSize: 11)),
                  const SizedBox(height: 3),
                  Container(
                    width: 28,
                    height: math.max(2, b.$2 / max * height),
                    decoration: BoxDecoration(color: b.$3, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ),
                  const SizedBox(height: 6),
                  Text(b.$1, textAlign: TextAlign.center, maxLines: 2, style: t.bodySmall?.copyWith(fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One horizontal (optionally stacked) bar with its label above.
class _HBar extends StatelessWidget {
  const _HBar({required this.label, required this.segments, required this.max});

  final String label;
  final List<(double, Color)> segments;
  final double max;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final sum = segments.fold<double>(0, (a, s) => a + s.$1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontSize: 13))),
            Text(sum.round().toString(), style: t.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, box) => Container(
              height: 10,
              decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(3)),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in segments)
                    if (s.$1 > 0) Container(width: s.$1 / max * box.maxWidth, height: 10, color: s.$2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _teamName(int id, List<TaskItem> tasks) {
  for (final t in tasks) {
    for (final a in t.assignees) {
      if (a.id == id) return a.name;
    }
  }
  return userNameById(id);
}

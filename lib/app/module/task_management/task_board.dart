import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/layout/main_content.dart';
import '../../../components/layout/page_heading.dart';
import '../../../components/layout/sidebar_menu.dart';
import '../../../core/core.dart';
import '../../../data/app_api.dart';
import '../../../data/models.dart';
import '../../../data/notifications_store.dart';
import 'task_detail_view.dart';
import 'task_form.dart';

enum TaskScope { mine, assigned, all }

/// The Kanban board behind My Tasks / Assigned Tasks / All Tasks (web `TaskBoard.tsx` and
/// `assigned/page.tsx`). On a phone the six status columns scroll sideways.
class TaskBoard extends StatefulWidget {
  const TaskBoard({super.key, required this.scope});

  final TaskScope scope;

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  List<TaskItem> _tasks = [];
  bool _loading = true;
  String _loadError = '';
  int? _openId;
  int? _highlightComment;
  bool _showForm = false;
  TaskItem? _editTask;
  final _search = TextEditingController();
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  bool _deepLinkHandled = false;
  int _seenNotification = 0;

  bool get _readOnly => widget.scope == TaskScope.all;
  String get _scope => switch (widget.scope) {
        TaskScope.mine => 'mine',
        TaskScope.assigned => 'assigned',
        TaskScope.all => 'all',
      };

  @override
  void initState() {
    super.initState();
    _seenNotification = NotificationsStore.instance.latest?.id ?? 0;
    NotificationsStore.instance.addListener(_onLive);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    NotificationsStore.instance.removeListener(_onLive);
    super.dispose();
  }

  /// A task notification just arrived (new assignment, status change, comment…): quietly reload the board.
  void _onLive() {
    final n = NotificationsStore.instance.latest;
    if (n == null || n.id == _seenNotification) return;
    _seenNotification = n.id;
    if (n.moduleName == 'taskManagement') _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    final r = await AppApi.client.get(ApiEndpoints.tasks, query: {'scope': _scope});
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _tasks = [for (final x in asRows(r)) TaskItem.fromJson(x)];
        _loadError = '';
      } else if (!quiet) {
        _loadError = r.message;
      }
    });
    _openDeepLink();
  }

  /// `?task=17&comment=96` from a notification opens that task.
  void _openDeepLink() {
    if (_deepLinkHandled) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) {
      _deepLinkHandled = true;
      return;
    }
    final id = int.tryParse('${args['task']}');
    if (id == null || !_tasks.any((t) => t.id == id)) return;
    _deepLinkHandled = true;
    setState(() {
      _openId = id;
      _highlightComment = int.tryParse('${args['comment']}');
    });
  }

  /// Moves a task; returns an error message or null.
  Future<String?> _changeStatus(TaskItem task, TaskStatus status) async {
    if (task.status == status) return null;
    final before = task.status;
    setState(() => task.status = status);
    final r = await AppApi.client.put(ApiEndpoints.task(task.id), body: {'status': status.api});
    if (!mounted) return null;
    if (!r.ok) {
      setState(() => task.status = before);
      return r.message;
    }
    if (r.data is Map) setState(() => task.copyFrom(TaskItem.fromJson(Map<String, dynamic>.from(r.data as Map))));
    return null;
  }

  Future<void> _approve(TaskItem task) async {
    final err = await _changeStatus(task, TaskStatus.done);
    if (err != null && mounted) AppToast.error(context, err);
  }

  Future<void> _reject(TaskItem task) async {
    final note = TextEditingController();
    final ok = await showAppDialog<bool>(
      context,
      builder: (ctx) => AppDialog(
        title: 'Reject & Send Back',
        description: "${task.assignees.map((a) => a.name.split(' ').first).join(', ')}'s task will move back to In Progress.",
        child: AppInput.multiline(controller: note, label: 'Reason (optional)', hint: 'e.g. Missing data on section 3…', minLines: 3),
        actions: [
          AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx, false)),
          AppButton(label: 'Reject & Send Back', variant: AppButtonVariant.destructive, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (ok != true || !mounted) return;
    final err = await _changeStatus(task, TaskStatus.inProgress);
    if (!mounted) return;
    if (err != null) return AppToast.error(context, err);
    if (text.isNotEmpty) await AppApi.client.post(ApiEndpoints.taskComments(task.id), body: {'comment': 'Rejected: $text'});
  }

  Future<void> _deleteTask(TaskItem task) async {
    final ok = await showAppConfirm(context, title: 'Delete Task', description: 'Delete task ${task.code} "${task.title}"? This cannot be undone.', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    final r = await AppApi.client.delete(ApiEndpoints.task(task.id));
    if (!mounted) return;
    if (!r.ok) return AppToast.error(context, r.message);
    setState(() {
      _tasks.remove(task);
      _showForm = false;
      _editTask = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned = widget.scope == TaskScope.assigned;
    final open = _openId == null ? null : _tasks.where((t) => t.id == _openId).firstOrNull;

    final Widget body;
    if (_showForm) {
      body = ListView(
        children: [
          TaskForm(
            task: _editTask,
            onCancel: () => setState(() {
              _showForm = false;
              _editTask = null;
            }),
            onSaved: (t, isNew) => setState(() {
              if (isNew) {
                _tasks = [..._tasks, t];
              } else {
                _editTask?.copyFrom(t);
              }
              _showForm = false;
              _editTask = null;
            }),
            onDelete: _editTask != null && _editTask!.canDelete ? () => _deleteTask(_editTask!) : null,
          ),
        ],
      );
    } else if (open != null) {
      body = TaskDetailView(
        key: ValueKey(open.id),
        task: open,
        canChangeStatus: !_readOnly,
        highlightCommentId: _highlightComment,
        onBack: () => setState(() {
          _openId = null;
          _highlightComment = null;
        }),
        onEdit: isAssigned && open.canEdit
            ? () => setState(() {
                  _editTask = open;
                  _showForm = true;
                  _openId = null;
                })
            : null,
        onStatusChange: (s) => _changeStatus(open, s),
        onChanged: () => setState(() {}),
      );
    } else if (_loading) {
      body = const Center(child: AppSpinner(size: 24));
    } else if (_loadError.isNotEmpty) {
      body = ListView(children: [AppAlert(title: _loadError, variant: AppAlertVariant.destructive), const SizedBox(height: 12), AppButton(label: 'Try again', icon: LucideIcons.refreshCw, variant: AppButtonVariant.outline, onPressed: _load)]);
    } else {
      body = _board(context, isAssigned);
    }

    return PopScope(
      canPop: _openId == null && !_showForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _openId = null;
            _showForm = false;
            _editTask = null;
          });
        }
      },
      child: MainContent(
        title: 'Task Management',
        backHref: '/module/task-management',
        sidebarMenu: taskMenu,
        scroll: false,
        child: body,
      ),
    );
  }

  ({String title, String subtitle}) get _heading => switch (widget.scope) {
        TaskScope.mine => (title: 'My Tasks', subtitle: 'Tasks assigned to you'),
        TaskScope.assigned => (title: 'Assigned Tasks', subtitle: 'Tasks you assigned — approve or send back'),
        TaskScope.all => (title: 'All Tasks', subtitle: 'Every task in your view · read only'),
      };

  List<TaskItem> get _visible {
    final q = _search.text.trim().toLowerCase();
    final list = _tasks.where((x) {
      if (_statusFilter != null && x.status != _statusFilter) return false;
      if (_priorityFilter != null && x.priority != _priorityFilter) return false;
      if (q.isNotEmpty && !('${x.code} ${x.title} ${x.projectName ?? ''} ${x.assignees.map((a) => a.name).join(' ')}'.toLowerCase().contains(q))) return false;
      return true;
    }).toList();
    // Open work first, soonest due date on top; finished tasks last.
    list.sort((a, b) {
      if (a.status.isClosed != b.status.isClosed) return a.status.isClosed ? 1 : -1;
      final da = a.due, db = b.due;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  void _pickPriority() {
    showAppSheet<void>(
      context,
      title: 'Filter by priority',
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: [
          for (final p in <TaskPriority?>[null, ...TaskPriority.values])
            ListTile(
              dense: true,
              leading: p == null ? const Icon(LucideIcons.layers, size: 18) : Container(width: 10, height: 10, decoration: BoxDecoration(color: p.dot, shape: BoxShape.circle)),
              title: Text(p?.label ?? 'All priorities'),
              trailing: _priorityFilter == p ? Icon(LucideIcons.check, size: 18, color: ctx.colors.primary) : null,
              onTap: () {
                setState(() => _priorityFilter = p);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  Widget _board(BuildContext context, bool isAssigned) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final list = _visible;
    final h = _heading;
    final base = _tasks.where((x) => _priorityFilter == null || x.priority == _priorityFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          title: h.title,
          subtitle: h.subtitle,
          action: isAssigned ? AppButton(label: 'New Task', icon: LucideIcons.plus, size: AppButtonSize.sm, onPressed: () => setState(() => _showForm = true)) : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: AppSearchField(controller: _search, hint: 'Search tasks', onChanged: (_) => setState(() {}))),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppIconButton(icon: LucideIcons.slidersHorizontal, variant: AppButtonVariant.outline, tooltip: 'Filter by priority', onPressed: _pickPriority),
                if (_priorityFilter != null) Positioned(top: -3, right: -3, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.background, width: 2)))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilterChips<TaskStatus>(
          selected: _statusFilter,
          onSelected: (v) => setState(() => _statusFilter = v),
          items: [
            (value: null, label: 'All', count: base.length, color: c.primary),
            for (final s in TaskStatus.values) (value: s, label: s.label, count: base.where((x) => x.status == s).length, color: s.color),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text('${list.length} task${list.length == 1 ? '' : 's'}', style: t.bodySmall),
              const Spacer(),
              if (_statusFilter != null || _priorityFilter != null || _search.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _statusFilter = null;
                    _priorityFilter = null;
                    _search.clear();
                  }),
                  child: Text('Clear filters', style: t.bodySmall?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(quiet: true),
            child: list.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: AppEmpty(
                        title: _tasks.isEmpty ? 'No tasks yet' : 'No tasks match',
                        description: _tasks.isEmpty ? (isAssigned ? 'Tap New Task to assign one.' : 'Tasks will appear here when they are assigned.') : 'Try another status or clear the filters.',
                        icon: LucideIcons.squareCheck,
                      ),
                    ),
                  ])
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, j) {
                      final task = list[j];
                      final canApprove = isAssigned && task.status == TaskStatus.review && task.canApprove;
                      return TaskCard(
                        task: task.toCard(),
                        showStatus: true,
                        onTap: () => setState(() {
                          if (isAssigned && task.canEdit) {
                            _editTask = task;
                            _showForm = true;
                          } else {
                            _openId = task.id;
                          }
                        }),
                        onApprove: canApprove ? () => _approve(task) : null,
                        onReject: canApprove ? () => _reject(task) : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

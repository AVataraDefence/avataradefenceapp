import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/upload_zone.dart';
import '../../../core/core.dart';
import '../../../data/app_api.dart';
import '../../../data/directory.dart';
import '../../../data/models.dart';
import '../../../data/notifications_store.dart';

DateTime? _ts(Object? v) => DateTime.tryParse('$v')?.toLocal();

/// A task opened from the board (web `TaskDetailView`): meta, description, comments,
/// checklist and documents. [canChangeStatus] is off on the view-only All Tasks board.
class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key, required this.task, required this.onBack, this.onEdit, this.canChangeStatus = true, this.onChanged, this.onStatusChange, this.highlightCommentId});

  final TaskItem task;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final bool canChangeStatus;

  /// The card counters (comments, documents, checklist) changed.
  final VoidCallback? onChanged;

  /// Moves the task; returns an error message or null.
  final Future<String?> Function(TaskStatus status)? onStatusChange;

  /// Comment to tint (from a notification link).
  final int? highlightCommentId;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  List<Rec> _comments = [];
  List<Rec> _docs = [];
  List<Rec> _checklist = [];
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  String _error = '';
  final _draft = TextEditingController();
  final _newItem = TextEditingController();
  int _seenNotification = 0;

  TaskItem get task => widget.task;
  int get _id => task.id;

  @override
  void initState() {
    super.initState();
    _seenNotification = NotificationsStore.instance.latest?.id ?? 0;
    NotificationsStore.instance.addListener(_onLive);
    _load();
  }

  @override
  void dispose() {
    NotificationsStore.instance.removeListener(_onLive);
    _draft.dispose();
    _newItem.dispose();
    super.dispose();
  }

  /// A notification about THIS task arrived while it is open: pull the fresh comments in place.
  void _onLive() {
    final n = NotificationsStore.instance.latest;
    if (n == null || n.id == _seenNotification) return;
    _seenNotification = n.id;
    if (n.referenceId == _id) _loadComments();
  }

  Future<void> _loadComments() async {
    final r = await AppApi.client.get(ApiEndpoints.taskComments(_id));
    if (!mounted || !r.ok) return;
    setState(() => _comments = asRows(r));
    _syncCounts();
  }

  Future<void> _load() async {
    final res = await Future.wait([
      AppApi.client.get(ApiEndpoints.taskComments(_id)),
      AppApi.client.get(ApiEndpoints.taskDocuments(_id)),
      AppApi.client.get(ApiEndpoints.taskChecklist(_id)),
    ]);
    if (!mounted) return;
    setState(() {
      _comments = asRows(res[0]);
      _docs = asRows(res[1]);
      _checklist = asRows(res[2]);
      _loading = false;
      final failed = res.where((r) => !r.ok).firstOrNull;
      if (failed != null) _error = failed.message;
    });
  }

  void _syncCounts() {
    task.commentCount = _comments.length;
    task.docCount = _docs.length;
    task.checklistTotal = _checklist.length;
    task.checklistDone = _checklist.where((i) => i['isCompleted'] == true).length;
    widget.onChanged?.call();
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = '';
    });
    final r = await AppApi.client.post(ApiEndpoints.taskComments(_id), body: {'comment': text});
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (r.ok && r.data is Map) {
        _comments = [..._comments, Map<String, dynamic>.from(r.data as Map)];
        _draft.clear();
        _syncCounts();
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _addItem() async {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    final r = await AppApi.client.post(ApiEndpoints.taskChecklist(_id), body: {'itemText': text});
    if (!mounted) return;
    setState(() {
      if (r.ok && r.data is Map) {
        _checklist = [..._checklist, Map<String, dynamic>.from(r.data as Map)];
        _newItem.clear();
        _syncCounts();
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _toggleItem(Rec item, bool value) async {
    final before = item['isCompleted'];
    setState(() {
      item['isCompleted'] = value;
      _syncCounts();
    });
    final r = await AppApi.client.put(ApiEndpoints.taskChecklistItem(_id, (item['checklistId'] as num).toInt()), body: {'isCompleted': value});
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        item['isCompleted'] = before;
        _error = r.message;
        _syncCounts();
      });
    }
  }

  Future<void> _removeItem(Rec item) async {
    final r = await AppApi.client.delete(ApiEndpoints.taskChecklistItem(_id, (item['checklistId'] as num).toInt()));
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _checklist.remove(item);
        _syncCounts();
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _upload({bool fromComment = false}) async {
    if (_uploading) return;
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'webp']);
    if (res.isEmpty || !mounted) return;
    setState(() {
      _uploading = true;
      _error = '';
    });
    final files = [for (final f in res) if (f.path != null) await http.MultipartFile.fromPath('files', f.path!, filename: f.name)];
    final r = await AppApi.client.postMultipart(ApiEndpoints.taskDocuments(_id), files: files);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (r.ok) {
        _docs = [..._docs, ...asRows(r)];
        _syncCounts();
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _removeDoc(Rec doc) async {
    final r = await AppApi.client.delete(ApiEndpoints.taskDocument(_id, (doc['docId'] as num).toInt()));
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _docs.remove(doc);
        _syncCounts();
      } else {
        _error = r.message;
      }
    });
  }

  Future<void> _move(TaskStatus s) async {
    final err = await widget.onStatusChange?.call(s);
    if (!mounted) return;
    setState(() => _error = err ?? '');
  }

  Widget _cardHeader(BuildContext context, IconData icon, Color color, String title, String badge) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: c.muted.withValues(alpha: 0.3), border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.6)))),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.rMd), child: Icon(icon, size: 13, color: color)),
          const SizedBox(width: 8),
          Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(color: color, borderRadius: AppRadius.rFull),
            alignment: Alignment.center,
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _metaCell(BuildContext context, String label, Widget child) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final overdue = task.overdue;
    final done = _checklist.where((i) => i['isCompleted'] == true).length;
    final byDate = <String, List<Rec>>{};
    for (final d in _docs) {
      final at = _ts(d['uploadedAt']);
      byDate.putIfAbsent(at == null ? '—' : formatAppDate(at), () => []).add(d);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(label: 'Back', icon: LucideIcons.arrowLeft, variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: widget.onBack),
            AppMono(task.code, size: 11),
            TaskStatusBadge(task.status),
            TaskPriorityBadge(task.priority),
            if (widget.onEdit != null && task.canEdit) AppButton(label: 'Edit task', variant: AppButtonVariant.outline, size: AppButtonSize.xs, onPressed: widget.onEdit),
          ],
        ),
        if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error, style: t.bodySmall?.copyWith(color: c.destructive))],
        if (widget.canChangeStatus && widget.onStatusChange != null) ...[
          const SizedBox(height: 12),
          Text('MOVE TO', style: t.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: TaskStatus.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = TaskStatus.values[i];
                final on = s == task.status;
                return GestureDetector(
                  onTap: on ? null : () => _move(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: on ? s.color : c.background, borderRadius: AppRadius.rFull, border: Border.all(color: on ? s.color : c.border)),
                    alignment: Alignment.center,
                    child: Text(s.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w600, color: on ? Colors.white : c.foreground)),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.code, style: t.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(task.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
                  ],
                ),
              ),
              const AppSeparator(),
              _metaCell(
                context,
                'Assignee',
                task.assignees.isEmpty
                    ? Text('—', style: t.bodySmall)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final a in task.assignees)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                AppAvatar(name: a.name, colorSeed: a.id, size: AppAvatarSize.xs),
                                const SizedBox(width: 8),
                                Text(a.name, style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                              ]),
                            ),
                        ],
                      ),
              ),
              const AppSeparator(),
              _metaCell(
                context,
                'Due Date',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.calendar, size: 13, color: overdue ? c.destructive : c.foreground),
                      const SizedBox(width: 5),
                      Text('${overdue ? 'Overdue · ' : ''}${task.due == null ? '—' : formatAppDate(task.due!)}', style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: overdue ? c.destructive : c.foreground)),
                    ]),
                    if (task.start != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Starts ${formatAppDate(task.start!)}', style: t.bodySmall)),
                  ],
                ),
              ),
              const AppSeparator(),
              _metaCell(
                context,
                'Project',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.projectName ?? '—', style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (task.createdByName != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Assigned by ${task.createdByName}', style: t.bodySmall)),
                  ],
                ),
              ),
              const AppSeparator(),
              AppAccordion(
                title: 'Description',
                child: Text(task.description.isEmpty ? 'No description provided.' : task.description, style: t.bodyMedium?.copyWith(fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // comments
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardHeader(context, LucideIcons.messageSquare, TwColors.violet600, 'Comments', '${_comments.length}'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _loading
                    ? Text('Loading…', style: t.bodySmall)
                    : _comments.isEmpty
                        ? Text('No comments yet.', style: t.bodySmall)
                        : Column(
                            children: [
                              for (final m in _comments)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: m['commentId'] == widget.highlightCommentId ? c.primary.withValues(alpha: 0.10) : null, borderRadius: AppRadius.rMd),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppAvatar(name: '${m['userName'] ?? '?'}', colorSeed: (m['userId'] as num?)?.toInt(), size: AppAvatarSize.xs),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(spacing: 6, children: [
                                              Text('${m['userName'] ?? 'Unknown'}', style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                                              if (_ts(m['createdAt']) != null) Text(timeAgo(_ts(m['createdAt'])!), style: t.bodySmall?.copyWith(fontSize: 10)),
                                            ]),
                                            const SizedBox(height: 2),
                                            Text('${m['comment'] ?? ''}', style: t.bodyMedium?.copyWith(fontSize: 13, height: 1.45)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                decoration: BoxDecoration(color: c.background, border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.6)))),
                child: Row(
                  children: [
                    AppIconButton(icon: _uploading ? LucideIcons.loader : LucideIcons.paperclip, tooltip: 'Attach a document', onPressed: _uploading ? null : _upload),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: c.muted, borderRadius: AppRadius.rFull),
                        child: TextField(
                          controller: _draft,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          onChanged: (_) => setState(() {}),
                          style: t.bodyMedium?.copyWith(fontSize: 14),
                          decoration: InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10), hintText: 'Write a comment', hintStyle: t.bodyMedium?.copyWith(color: c.mutedForeground)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: c.primary.withValues(alpha: _draft.text.trim().isEmpty || _sending ? 0.4 : 1),
                      shape: const CircleBorder(),
                      child: InkWell(customBorder: const CircleBorder(), onTap: _send, child: SizedBox(width: 40, height: 40, child: _sending ? const Padding(padding: EdgeInsets.all(11), child: AppSpinner(size: 18)) : Icon(LucideIcons.send, size: 17, color: c.primaryForeground))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // checklist
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardHeader(context, LucideIcons.listChecks, TwColors.emerald600, 'Checklist', '$done/${_checklist.length}'),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_checklist.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(_loading ? 'Loading…' : 'No checklist items yet.', style: t.bodySmall)),
                    for (final item in _checklist)
                      Row(
                        children: [
                          Expanded(child: AppCheckbox(value: item['isCompleted'] == true, label: '${item['itemText']}', onChanged: (v) => _toggleItem(item, v))),
                          AppIconButton(icon: LucideIcons.x, size: AppButtonSize.xs, onPressed: () => _removeItem(item)),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: AppInput(controller: _newItem, hint: 'Add an item…', onSubmitted: (_) => _addItem())),
                        const SizedBox(width: 8),
                        AppIconButton(icon: LucideIcons.plus, variant: AppButtonVariant.primary, onPressed: _addItem),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // documents
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cardHeader(context, LucideIcons.paperclip, TwColors.indigo600, 'Documents', '${_docs.length}'),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UploadZone(compact: true, subtitle: 'tap to browse · max 10MB', busy: _uploading, onTap: _upload),
                    if (_docs.isEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: Text(_loading ? 'Loading…' : 'No documents yet.', style: t.bodySmall))),
                    for (final e in byDate.entries) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Icon(LucideIcons.calendar, size: 11, color: c.mutedForeground),
                        const SizedBox(width: 5),
                        Text(e.key.toUpperCase(), style: t.labelSmall?.copyWith(fontSize: 10, letterSpacing: 1.2)),
                        const SizedBox(width: 8),
                        Expanded(child: Divider(height: 1, color: c.border.withValues(alpha: 0.5))),
                      ]),
                      const SizedBox(height: 6),
                      for (final d in e.value) ...[
                        FileRow(
                          name: '${d['docName']}',
                          ext: d['extension'] as String?,
                          meta: '${d['uploadedByName'] ?? 'Unknown'}${d['fileSize'] == null ? '' : ' · ${_size(d['fileSize'])}'}',
                          onOpen: d['fileUrl'] == null ? null : () => launchUrl(Uri.parse('${d['fileUrl']}'), mode: LaunchMode.externalApplication),
                          onDelete: () => _removeDoc(d),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _size(Object? bytes) {
    final b = (bytes as num?)?.toDouble() ?? 0;
    if (b < 1024) return '${b.toInt()} B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

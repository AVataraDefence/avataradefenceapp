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

/// Create / edit a task (web `TaskForm` on Assigned Tasks).
class TaskForm extends StatefulWidget {
  const TaskForm({super.key, this.task, required this.onSaved, required this.onCancel, this.onDelete});

  /// Null = new task.
  final TaskItem? task;
  final void Function(TaskItem task, bool isNew) onSaved;
  final VoidCallback onCancel;
  final Future<void> Function()? onDelete;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _description = TextEditingController(text: widget.task?.description ?? '');
  late List<String> _assignees = [for (final a in widget.task?.assignees ?? const <({int id, String name})>[]) '${a.id}'];
  TaskPriority? _priority;
  int? _projectId;
  late TaskStatus _status = widget.task?.status ?? TaskStatus.todo;
  DateTime? _start;
  DateTime? _due;
  final List<PlatformFile> _files = [];
  List<Rec> _savedDocs = [];
  List<AppOption<String>> _userOpts = [];
  List<AppOption<int>> _projectOpts = [];
  final Map<String, String> _errors = {};
  String _general = '';
  bool _saving = false;
  bool _saved = false;
  bool _deleting = false;
  bool _lookupsLoading = true;

  bool get _isEdit => widget.task != null;
  bool get _readOnly => _isEdit && !widget.task!.canEdit;

  @override
  void initState() {
    super.initState();
    _priority = widget.task?.priority;
    _projectId = widget.task?.projectId;
    _start = widget.task?.start;
    _due = widget.task?.due;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final res = await Future.wait([
      AppApi.client.get(ApiEndpoints.taskUsers),
      AppApi.client.get(ApiEndpoints.taskProjects),
      if (_isEdit) AppApi.client.get(ApiEndpoints.taskDocuments(widget.task!.id)),
    ]);
    if (!mounted) return;
    setState(() {
      _userOpts = [for (final u in asRows(res[0])) AppOption(value: '${u['userId']}', label: '${u['name']}', subtitle: u['employeeNumber'] as String?)];
      _projectOpts = [for (final p in asRows(res[1])) AppOption(value: (p['projectId'] as num).toInt(), label: '${p['projectName']}')];
      if (res.length > 2) _savedDocs = asRows(res[2]);
      _lookupsLoading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'webp']);
    if (res.isEmpty || !mounted) return;
    if (_isEdit) {
      // Existing task: upload straight away, like the web.
      final files = [for (final f in res) if (f.path != null) await http.MultipartFile.fromPath('files', f.path!, filename: f.name)];
      final r = await AppApi.client.postMultipart(ApiEndpoints.taskDocuments(widget.task!.id), files: files);
      if (!mounted) return;
      setState(() {
        if (r.ok) {
          _savedDocs = [..._savedDocs, ...asRows(r)];
        } else {
          _general = r.message;
        }
      });
    } else {
      setState(() => _files.addAll(res));
    }
  }

  Future<void> _removeSaved(Rec d) async {
    final r = await AppApi.client.delete(ApiEndpoints.taskDocument(widget.task!.id, (d['docId'] as num).toInt()));
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _savedDocs.remove(d);
      } else {
        _general = r.message;
      }
    });
  }

  Future<void> _save() async {
    final errs = <String, String>{};
    if (_title.text.trim().isEmpty) errs['title'] = 'Title is required';
    if (_assignees.isEmpty) errs['assignees'] = 'Select at least one assignee';
    if (_priority == null) errs['priority'] = 'Priority is required';
    if (_due == null) errs['due'] = 'Due date is required';
    if (_projectId == null) errs['project'] = 'Project is required';
    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
      _general = '';
    });
    if (errs.isNotEmpty) return;

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'assigneeIds': [for (final a in _assignees) int.parse(a)],
      'priority': _priority!.label,
      'projectId': _projectId,
      'startDate': _start == null ? null : isoDate(_start!),
      'dueDate': isoDate(_due!),
    }..removeWhere((k, v) => v == null);

    final task = widget.task;
    if (task != null) {
      // Status only goes in when it changed, so editing a task in Review never trips the approval gate.
      if (_status != task.status) body['status'] = _status.api;
      final r = await AppApi.client.put(ApiEndpoints.task(task.id), body: body);
      if (!mounted) return;
      if (!r.ok || r.data is! Map) {
        setState(() {
          _saving = false;
          _general = r.message;
        });
        return;
      }
      final updated = TaskItem.fromJson(Map<String, dynamic>.from(r.data as Map))..docCount = _savedDocs.length;
      setState(() {
        _saving = false;
        _saved = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) widget.onSaved(updated, false);
      return;
    }

    body['status'] = _status.api;
    final created = await AppApi.client.post(ApiEndpoints.tasks, body: body);
    if (!mounted) return;
    if (!created.ok || created.data is! Map) {
      setState(() {
        _saving = false;
        _general = created.message;
      });
      return;
    }
    final item = TaskItem.fromJson(Map<String, dynamic>.from(created.data as Map));
    if (_files.isNotEmpty) {
      final files = [for (final f in _files) if (f.path != null) await http.MultipartFile.fromPath('files', f.path!, filename: f.name)];
      final up = await AppApi.client.postMultipart(ApiEndpoints.taskDocuments(item.id), files: files);
      if (up.ok) {
        item.docCount = asRows(up).length;
      } else if (mounted) {
        setState(() => _general = 'Task created, but documents failed to upload: ${up.message}');
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) widget.onSaved(item, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final readOnly = _readOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_general.isNotEmpty) ...[AppAlert(title: _general, variant: AppAlertVariant.destructive), const SizedBox(height: 12)],
        AppCard(
          title: _isEdit ? 'Edit Task · ${widget.task!.code}' : 'Task Details',
          description: readOnly ? "View only — you don't have permission to edit this task." : (_isEdit ? 'Update the details, assignees or documents.' : 'Describe the work and who should do it.'),
          headerDivider: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(controller: _title, label: 'Task Title', hint: 'e.g. Coordinate perimeter sweep', error: _errors['title'], enabled: !readOnly, onChanged: (_) => setState(() => _errors.remove('title'))),
              const SizedBox(height: 16),
              AppMultiSelect<String>(
                label: 'Assign To',
                hint: _lookupsLoading ? 'Loading…' : 'Select employees',
                options: _userOpts,
                values: _assignees,
                error: _errors['assignees'],
                enabled: !readOnly,
                onChanged: (v) => setState(() {
                  _assignees = v;
                  _errors.remove('assignees');
                }),
              ),
              const SizedBox(height: 16),
              AppSelect<TaskPriority>(
                label: 'Priority',
                hint: 'Select priority',
                options: [for (final p in TaskPriority.values) AppOption(value: p, label: p.label)],
                value: _priority,
                error: _errors['priority'],
                enabled: !readOnly,
                onChanged: (v) => setState(() {
                  _priority = v;
                  _errors.remove('priority');
                }),
              ),
              const SizedBox(height: 16),
              AppSelect<int>(
                label: 'Project',
                hint: _lookupsLoading ? 'Loading…' : 'Select project',
                options: _projectOpts,
                value: _projectId,
                error: _errors['project'],
                enabled: !readOnly,
                onChanged: (v) => setState(() {
                  _projectId = v;
                  _errors.remove('project');
                }),
              ),
              const SizedBox(height: 16),
              AppSelect<TaskStatus>(
                label: 'Status',
                hint: 'Select status',
                options: [for (final s in TaskStatus.values) AppOption(value: s, label: s.label)],
                value: _status,
                enabled: !readOnly,
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 16),
              AppDateField(label: 'Start Date', value: _start, onChanged: (d) => setState(() => _start = d)),
              const SizedBox(height: 16),
              AppDateField(
                label: 'Due Date',
                value: _due,
                error: _errors['due'],
                onChanged: (d) => setState(() {
                  _due = d;
                  _errors.remove('due');
                }),
              ),
              const SizedBox(height: 16),
              AppInput.multiline(controller: _description, label: 'Description', hint: 'Describe the task in detail…', minLines: 5, maxLines: 8, enabled: !readOnly),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          title: 'Documents',
          description: 'Attach files related to this task.',
          headerDivider: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!readOnly) UploadZone(title: 'Tap to attach files', subtitle: 'PDF · DOC · XLS · JPG · PNG · max 10MB', onTap: _pick),
              if (_files.isEmpty && _savedDocs.isEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: Text('No documents attached yet.', style: t.bodySmall))),
              for (final d in _savedDocs) ...[
                const SizedBox(height: 6),
                FileRow(
                  name: '${d['docName']}',
                  ext: d['extension'] as String?,
                  meta: d['uploadedByName'] as String?,
                  onOpen: d['fileUrl'] == null ? null : () => launchUrl(Uri.parse('${d['fileUrl']}'), mode: LaunchMode.externalApplication),
                  onDelete: readOnly ? null : () => _removeSaved(d),
                ),
              ],
              for (final f in _files) ...[
                const SizedBox(height: 6),
                FileRow(name: f.name, ext: f.extension, meta: 'Ready to upload', onDelete: () => setState(() => _files.remove(f))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.onDelete != null && !readOnly)
              AppButton(
                label: 'Delete Task',
                icon: LucideIcons.trash2,
                variant: AppButtonVariant.destructive,
                loading: _deleting,
                onPressed: _saving || _deleting
                    ? null
                    : () async {
                        setState(() => _deleting = true);
                        await widget.onDelete!();
                        if (mounted) setState(() => _deleting = false);
                      },
              ),
            const Spacer(),
            AppButton(label: readOnly ? 'Close' : 'Cancel', variant: AppButtonVariant.outline, onPressed: _saving ? null : widget.onCancel),
            if (!readOnly) ...[
              const SizedBox(width: 12),
              AppButton(
                label: _saving ? 'Saving…' : (_saved ? 'Saved' : (_isEdit ? 'Update Task' : 'Assign Task')),
                icon: _saved ? LucideIcons.check : null,
                loading: _saving,
                onPressed: _saving || _saved || _deleting ? null : _save,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

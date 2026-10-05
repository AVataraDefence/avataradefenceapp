import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../../data/app_api.dart';
import '../../data/directory.dart';
import '../layout/main_content.dart';
import '../layout/sidebar_menu.dart';
import '../list_card.dart';
import '../upload_zone.dart';

/// The list + add/edit-form page every Employee / Master Data / Settings page on the web
/// repeats (`+ Add X` ↔ `View Table`, section cards, action menu, delete confirmation).
/// Each page only describes its API path, fields and columns; this widget does the calls.

enum CrudFieldType { text, multiline, select, multiSelect, date, checkbox, email, phone, number, password }

class CrudField {
  const CrudField(
    this.key,
    this.label, {
    this.type = CrudFieldType.text,
    this.hint,
    this.required = false,
    this.requiredMessage,
    this.options,
    this.uppercase = false,
    this.full = false,
    this.checkboxLabel,
    this.helper,
    this.enabled = true,
    this.intValue = false,
  });

  /// The API field name — used as-is for the request body and to read the list rows.
  final String key;
  final String label;
  final CrudFieldType type;
  final String? hint;
  final bool required;
  final String? requiredMessage;

  /// Evaluated each time the form builds, so lists that change (employees, users) stay fresh.
  final List<AppOption<String>> Function()? options;
  final bool uppercase;

  /// Span both columns on wide screens.
  final bool full;
  final String? checkboxLabel;
  final String? helper;

  /// Disabled fields are shown but never sent.
  final bool enabled;

  /// Send a `number` field as an integer (years, height …) instead of text.
  final bool intValue;
}

class CrudSection {
  const CrudSection(this.title, this.subtitle, this.fields) : uploadKey = null;

  /// A file attachment card (Employee → Documents).
  const CrudSection.upload(this.title, this.subtitle, String this.uploadKey) : fields = const [];

  final String title;
  final String subtitle;
  final List<CrudField> fields;
  final String? uploadKey;
}

enum CrudRole { field, title, subtitle }

/// One list-card line. [cell] draws the value.
class CrudColumn {
  const CrudColumn(this.header, this.cell, {this.width = 140, this.role = CrudRole.field, this.text});

  final String header;
  final Widget Function(BuildContext context, Rec row) cell;
  final double width;

  /// How the list card uses this column: its heading, its sub-heading, or a `label : value` line.
  final CrudRole role;

  /// Plain-text value, needed for columns used as title / subtitle.
  final String Function(Rec row)? text;

  CrudColumn asTitle() => CrudColumn(header, cell, width: width, role: CrudRole.title, text: text);
  CrudColumn asSubtitle() => CrudColumn(header, cell, width: width, role: CrudRole.subtitle, text: text);

  static Widget _text(BuildContext context, String value, {bool bold = false, bool mono = false}) {
    final t = Theme.of(context).textTheme;
    return Text(
      value.isEmpty ? '—' : value,
      style: t.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w500 : null, fontFamily: mono ? 'monospace' : null, fontSize: 13),
    );
  }

  factory CrudColumn.text(String header, String key, {double width = 140, bool bold = false, bool mono = false}) =>
      CrudColumn(header, (ctx, r) => _text(ctx, '${r[key] ?? ''}', bold: bold, mono: mono), width: width, text: (r) => '${r[key] ?? ''}');

  factory CrudColumn.computed(String header, String Function(Rec r) value, {double width = 140, bool bold = false, bool mono = false}) =>
      CrudColumn(header, (ctx, r) => _text(ctx, value(r), bold: bold, mono: mono), width: width, text: value);

  factory CrudColumn.date(String header, String key, {double width = 130}) => CrudColumn(
        header,
        (ctx, r) {
          final d = DateTime.tryParse('${r[key] ?? ''}');
          return _text(ctx, d == null ? '' : formatAppDate(d));
        },
        width: width,
      );

  /// Muted pill (account type, relationship, …).
  factory CrudColumn.pill(String header, String key, {double width = 120}) => CrudColumn(
        header,
        (ctx, r) {
          final v = '${r[key] ?? ''}';
          return v.isEmpty ? _text(ctx, '') : AppBadge(v, variant: AppBadgeVariant.secondary);
        },
        width: width,
      );

  /// Green "Yes" / grey "No".
  factory CrudColumn.yesNo(String header, String key, {double width = 90}) => CrudColumn(
        header,
        (ctx, r) => r[key] == true
            ? AppBadge.tinted('Yes', color: TwColors.green700, background: TwColors.green50)
            : const AppBadge('No', variant: AppBadgeVariant.secondary),
        width: width,
      );

  /// Coloured pill chosen from a value → colour map (document status, fitness status).
  factory CrudColumn.status(String header, String key, Map<String, Color> colors, {double width = 150}) => CrudColumn(
        header,
        (ctx, r) {
          final v = '${r[key] ?? ''}';
          if (v.isEmpty) return _text(ctx, '');
          final color = colors[v];
          return color == null ? AppBadge(v, variant: AppBadgeVariant.secondary) : AppBadge.tinted(v, color: color, background: color.withValues(alpha: 0.12));
        },
        width: width,
      );
}

/// Where a [CrudPage] reads and writes. `GET path` lists; `POST path` creates; `PUT|DELETE path/<id>`.
class CrudApi {
  const CrudApi(
    this.path, {
    required this.idKey,
    this.refresh = const [],
    this.multipart = false,
    this.fileKey = 'file',
    this.fileNameKey = 'fileName',
    this.fileUrlKey = 'fileUrl',
  });

  final String path;

  /// The id property on each row (`bankId`, `departmentId` …).
  final String idKey;

  /// [Directory] lists to reload after a change (`'departments'` …), so pickers stay current.
  final List<String> refresh;

  /// Create / update as `multipart/form-data` with one file (Employee → Documents).
  final bool multipart;
  final String fileKey;
  final String fileNameKey;
  final String fileUrlKey;
}

typedef CrudDeleteText = String Function(Rec row);

class CrudPage extends StatefulWidget {
  const CrudPage({
    super.key,
    required this.title,
    required this.backHref,
    required this.menu,
    required this.heading,
    required this.subtitle,
    required this.addLabel,
    required this.recordName,
    required this.sections,
    required this.columns,
    required this.api,
    required this.deleteTarget,
    this.updateLabel,
    this.saveLabel = 'Save Changes',
    this.statusKey,
    this.deleteHint = 'This action cannot be undone.',
    this.softDelete = false,
    this.emptyLabel,
    this.initialValues,
    this.initialValuesBuilder,
  });

  /// Header title + back target + side menu (the module this page lives in).
  final String title;
  final String backHref;
  final List<SidebarGroup> menu;

  final String heading;
  final String subtitle;

  /// "+ Add Department" → `Department`.
  final String addLabel;

  /// Noun for dialogs: "Department".
  final String recordName;
  final List<CrudSection> sections;
  final List<CrudColumn> columns;
  final CrudApi api;
  final CrudDeleteText deleteTarget;
  final String? updateLabel;
  final String saveLabel;

  /// Row key holding the active flag; adds a Status switch on each card.
  final String? statusKey;
  final String deleteHint;

  /// Delete only deactivates (departments, roles, …) instead of removing the row.
  final bool softDelete;
  final String? emptyLabel;
  final Map<String, dynamic>? initialValues;

  /// Defaults for a new record that depend on loaded data (next employee number …).
  final Map<String, dynamic> Function()? initialValuesBuilder;

  @override
  State<CrudPage> createState() => _CrudPageState();
}

enum _SaveState { idle, saving, saved }

class _CrudPageState extends State<CrudPage> {
  List<Rec> _rows = [];
  bool _loading = true;
  String _loadError = '';
  bool _showForm = false;
  Rec? _editing;
  Map<String, dynamic> _form = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _errors = {};
  String _general = '';
  _SaveState _save = _SaveState.idle;
  PlatformFile? _pickedFile;
  bool _clearFile = false;

  List<CrudField> get _allFields => [for (final s in widget.sections) ...s.fields];
  CrudApi get _api => widget.api;

  @override
  void initState() {
    super.initState();
    Directory.instance.addListener(_dirChanged);
    _load();
  }

  void _dirChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Directory.instance.removeListener(_dirChanged);
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    final r = await AppApi.client.get(_api.path);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _rows = [for (final x in asRows(r)) _normalise(x)];
        _loadError = '';
      } else if (!quiet) {
        _loadError = r.message;
      }
    });
  }

  /// Trims API timestamps on date fields to `yyyy-MM-dd`.
  Rec _normalise(Rec row) {
    for (final f in _allFields) {
      final v = row[f.key];
      if (f.type == CrudFieldType.date && v is String && v.length > 10) row[f.key] = v.substring(0, 10);
    }
    return row;
  }

  Object? _rowId(Rec row) => row[_api.idKey];

  void _openForm([Rec? row]) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _errors.clear();
    _general = '';
    _save = _SaveState.idle;
    _pickedFile = null;
    _clearFile = false;
    _editing = row;
    final defaults = {...?widget.initialValues, ...?widget.initialValuesBuilder?.call()};
    _form = {
      for (final f in _allFields) f.key: _formValue(f, row != null ? row[f.key] : defaults[f.key]),
    };
    for (final f in _allFields) {
      if (_isTextual(f.type)) _controllers[f.key] = TextEditingController(text: '${_form[f.key] ?? ''}');
    }
    setState(() => _showForm = true);
  }

  dynamic _formValue(CrudField f, dynamic v) => switch (f.type) {
        CrudFieldType.checkbox => v == true,
        CrudFieldType.multiSelect => [for (final x in (v as List? ?? const [])) '$x'],
        CrudFieldType.password => '',
        _ => v == null ? '' : '$v',
      };

  bool _isTextual(CrudFieldType t) => t == CrudFieldType.text || t == CrudFieldType.multiline || t == CrudFieldType.email || t == CrudFieldType.phone || t == CrudFieldType.number || t == CrudFieldType.password;

  void _closeForm() => setState(() {
        _showForm = false;
        _editing = null;
        _errors.clear();
      });

  /// Form → request body, shaped like the web pages send it.
  Map<String, dynamic> _payload() {
    final body = <String, dynamic>{};
    for (final f in _allFields) {
      if (!f.enabled) continue;
      final v = _form[f.key];
      switch (f.type) {
        case CrudFieldType.checkbox:
          body[f.key] = v == true;
        case CrudFieldType.multiSelect:
          body[f.key] = [for (final x in (v as List)) int.tryParse('$x') ?? x];
        case CrudFieldType.select:
          final s = '$v';
          if (s.isNotEmpty) body[f.key] = (f.key.endsWith('Id') || f.intValue) ? (int.tryParse(s) ?? s) : s;
        case CrudFieldType.number:
          final s = '$v'.trim();
          if (s.isNotEmpty) body[f.key] = f.intValue ? (int.tryParse(s) ?? s) : s;
        case CrudFieldType.password:
          if ('$v'.isNotEmpty) body[f.key] = '$v';
        default:
          body[f.key] = '$v'.trim();
      }
    }
    return body;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final errs = <String, String>{};
    for (final f in _allFields) {
      if (!f.required) continue;
      final v = _form[f.key];
      final empty = v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);
      if (empty) errs[f.key] = f.requiredMessage ?? '${f.label.replaceAll(' *', '')} is required';
    }
    if (errs.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errs);
        _general = '';
      });
      return;
    }

    setState(() {
      _save = _SaveState.saving;
      _general = '';
    });
    final editing = _editing;
    final body = _payload();
    final ApiResult<dynamic> r;
    if (_api.multipart) {
      final fields = {for (final e in body.entries) e.key: '${e.value}'};
      if (_clearFile && _pickedFile == null) fields['clearFile'] = 'true';
      final files = <http.MultipartFile>[];
      if (_pickedFile?.path != null) files.add(await http.MultipartFile.fromPath(_api.fileKey, _pickedFile!.path!, filename: _pickedFile!.name));
      r = editing == null ? await AppApi.client.postMultipart(_api.path, fields: fields, files: files) : await AppApi.client.putMultipart('${_api.path}/${_rowId(editing)}', fields: fields, files: files);
    } else {
      r = editing == null ? await AppApi.client.post(_api.path, body: body) : await AppApi.client.put('${_api.path}/${_rowId(editing)}', body: body);
    }
    if (!mounted) return;
    if (!r.ok || r.data is! Map) {
      setState(() {
        _save = _SaveState.idle;
        _general = r.message;
      });
      return;
    }
    final saved = _normalise(Map<String, dynamic>.from(r.data as Map));
    setState(() {
      if (editing != null) {
        final i = _rows.indexOf(editing);
        if (i >= 0) _rows[i] = saved;
      } else {
        _rows = [..._rows, saved];
      }
      _save = _SaveState.saved;
    });
    _refreshDirectory();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) _closeForm();
  }

  void _refreshDirectory() {
    for (final k in _api.refresh) {
      Directory.instance.refresh(k);
    }
    // A change may alter many rows (a primary flag, a head of department) — reload quietly.
    _load(quiet: true);
  }

  Future<void> _delete(Rec row) async {
    final ok = await showAppConfirm(
      context,
      title: 'Delete ${widget.recordName}',
      description: 'Are you sure you want to delete ${widget.deleteTarget(row)}? ${widget.softDelete ? 'This deactivates the ${widget.recordName.toLowerCase()}.' : widget.deleteHint}',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final r = await AppApi.client.delete('${_api.path}/${_rowId(row)}');
    if (!mounted) return;
    if (!r.ok) return AppToast.error(context, r.message);
    setState(() {
      if (widget.softDelete && widget.statusKey != null) {
        row[widget.statusKey!] = false;
      } else {
        _rows.remove(row);
      }
    });
    _refreshDirectory();
  }

  Future<void> _toggleStatus(Rec row, bool value) async {
    final key = widget.statusKey!;
    final before = row[key];
    setState(() => row[key] = value);
    final r = await AppApi.client.put('${_api.path}/${_rowId(row)}', body: {key: value});
    if (!mounted) return;
    if (!r.ok) {
      setState(() => row[key] = before);
      AppToast.error(context, r.message);
      return;
    }
    _refreshDirectory();
  }

  void _rowActions(Rec row) {
    showAppActionSheet(
      context,
      title: widget.deleteTarget(row),
      actions: [
        AppMenuAction(label: 'Edit', icon: LucideIcons.pencil, onTap: () => _openForm(row)),
        AppMenuAction(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () => _delete(row)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return MainContent(
      title: widget.title,
      backHref: widget.backHref,
      sidebarMenu: widget.menu,
      onRefresh: _showForm ? null : () => _load(quiet: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.heading, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
                const SizedBox(height: 12),
                AppButton(
                  label: _showForm ? 'View Table' : '+ Add ${widget.addLabel}',
                  icon: _showForm ? LucideIcons.arrowLeft : null,
                  size: AppButtonSize.sm,
                  onPressed: _showForm ? _closeForm : (_loading ? null : () => _openForm()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_showForm) _buildForm(context) else _buildList(context),
        ],
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    if (_loading) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: AppSpinner(size: 24)));
    }
    if (_loadError.isNotEmpty) {
      return AppCard(
        child: Column(
          children: [
            AppAlert(title: _loadError, variant: AppAlertVariant.destructive),
            const SizedBox(height: 12),
            AppButton(label: 'Try again', icon: LucideIcons.refreshCw, variant: AppButtonVariant.outline, onPressed: _load),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text.rich(
              TextSpan(
                text: widget.emptyLabel ?? 'No records found. Click ',
                children: [TextSpan(text: '+ Add ${widget.addLabel}', style: TextStyle(fontWeight: FontWeight.w600, color: c.primary)), const TextSpan(text: ' to create one.')],
              ),
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: c.mutedForeground),
            ),
          ),
        ),
      );
    }

    final titleCol = widget.columns.where((c) => c.role == CrudRole.title).firstOrNull ?? widget.columns.firstWhere((c) => c.text != null);
    final subCol = widget.columns.where((c) => c.role == CrudRole.subtitle).firstOrNull;
    final fieldCols = [for (final col in widget.columns) if (col != titleCol && col != subCol && col.header.isNotEmpty) col];
    String textOf(CrudColumn col, Rec r) => col.text?.call(r) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in _rows) ...[
          AppListCard(
            title: textOf(titleCol, row).isEmpty ? widget.deleteTarget(row) : textOf(titleCol, row),
            subtitle: subCol == null ? null : textOf(subCol, row),
            leading: widget.columns.where((c) => c.header.isEmpty).firstOrNull?.cell(context, row),
            onTap: () => _openForm(row),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.statusKey != null) AppSwitch(value: row[widget.statusKey!] == true, onChanged: (v) => _toggleStatus(row, v)),
                AppIconButton(icon: LucideIcons.ellipsisVertical, size: AppButtonSize.sm, tooltip: 'Actions', onPressed: () => _rowActions(row)),
              ],
            ),
            rows: [for (final col in fieldCols) (col.header, col.cell(context, row))],
          ),
          const SizedBox(height: 10),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          child: Text('Showing ${_rows.length} ${widget.recordName.toLowerCase()}${_rows.length == 1 ? '' : 's'}', style: t.bodySmall),
        ),
      ],
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────────
  Widget _buildForm(BuildContext context) {
    final saving = _save == _SaveState.saving;
    final isEdit = _editing != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_general.isNotEmpty) ...[
          AppAlert(title: _general, variant: AppAlertVariant.destructive),
          const SizedBox(height: 16),
        ],
        for (final s in widget.sections) ...[
          AppCard(
            title: s.title,
            description: s.subtitle,
            headerDivider: true,
            padding: const EdgeInsets.all(16),
            child: s.uploadKey != null ? _uploadCard(context) : _fieldGrid(context, s.fields),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: saving ? null : _closeForm),
            const SizedBox(width: 12),
            AppButton(
              label: switch (_save) {
                _SaveState.saving => 'Saving…',
                _SaveState.saved => isEdit ? 'Updated' : 'Saved',
                _SaveState.idle => isEdit ? (widget.updateLabel ?? 'Update ${widget.recordName}') : widget.saveLabel,
              },
              icon: _save == _SaveState.saved ? LucideIcons.check : null,
              loading: saving,
              onPressed: _save == _SaveState.idle ? _submit : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']);
    if (f == null || !mounted) return;
    final bytes = (await f.length()) ?? 0;
    if (!mounted) return;
    if (bytes > 10 * 1024 * 1024) return AppToast.error(context, 'File is larger than 10MB');
    setState(() {
      _pickedFile = f;
      _clearFile = false;
    });
  }

  Widget _uploadCard(BuildContext context) {
    final existingName = _clearFile ? '' : '${_editing?[_api.fileNameKey] ?? ''}';
    final existingUrl = _editing?[_api.fileUrlKey] as String?;
    if (_pickedFile != null) {
      return FileRow(name: _pickedFile!.name, ext: _pickedFile!.extension, meta: 'Ready to upload', onDelete: () => setState(() => _pickedFile = null));
    }
    if (existingName.isNotEmpty) {
      return FileRow(
        name: existingName,
        ext: existingName.split('.').last,
        meta: 'Attached',
        onOpen: existingUrl == null ? null : () => launchUrl(Uri.parse(existingUrl), mode: LaunchMode.externalApplication),
        onDelete: () => setState(() => _clearFile = true),
      );
    }
    return UploadZone(title: 'Tap to attach a file', subtitle: 'PDF · JPG · PNG · DOC · DOCX · max 10MB', onTap: _pickFile);
  }

  Widget _fieldGrid(BuildContext context, List<CrudField> fields) {
    return LayoutBuilder(
      builder: (context, box) {
        final two = box.maxWidth >= 560;
        final half = (box.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final f in fields)
              SizedBox(width: two && !f.full && f.type != CrudFieldType.multiline && f.type != CrudFieldType.checkbox ? half : box.maxWidth, child: _buildField(f)),
          ],
        );
      },
    );
  }

  Widget _buildField(CrudField f) {
    final err = _errors[f.key];
    void change(dynamic v) => setState(() {
          _form[f.key] = v;
          _errors.remove(f.key);
        });
    final label = f.label;
    switch (f.type) {
      case CrudFieldType.text:
      case CrudFieldType.email:
      case CrudFieldType.phone:
      case CrudFieldType.number:
      case CrudFieldType.password:
        return AppInput(
          controller: _controllers[f.key],
          label: label,
          hint: f.hint ?? label,
          helper: f.helper,
          required: f.required && label.endsWith('*'),
          error: err,
          enabled: f.enabled,
          obscureText: f.type == CrudFieldType.password,
          keyboardType: switch (f.type) {
            CrudFieldType.email => TextInputType.emailAddress,
            CrudFieldType.phone => TextInputType.phone,
            CrudFieldType.number => TextInputType.number,
            _ => TextInputType.text,
          },
          inputFormatters: [if (f.uppercase) _UpperCaseFormatter(), if (f.type == CrudFieldType.number) FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => change(v),
        );
      case CrudFieldType.multiline:
        return AppInput.multiline(controller: _controllers[f.key], label: label, hint: f.hint ?? label, error: err, minLines: 3, maxLines: 6, onChanged: (v) => change(v));
      case CrudFieldType.select:
        return AppSelect<String>(
          label: label,
          hint: f.hint ?? 'Select ${label.toLowerCase()}',
          options: f.options!(),
          value: (_form[f.key] as String?)?.isEmpty ?? true ? null : _form[f.key] as String,
          error: err,
          onChanged: change,
        );
      case CrudFieldType.multiSelect:
        return AppMultiSelect<String>(
          label: label,
          hint: f.hint ?? 'Select ${label.toLowerCase()}',
          options: f.options!(),
          values: List<String>.from(_form[f.key] as List? ?? const []),
          error: err,
          onChanged: change,
        );
      case CrudFieldType.date:
        return AppDateField(
          label: label,
          hint: f.hint ?? 'Select date',
          value: DateTime.tryParse('${_form[f.key] ?? ''}'),
          error: err,
          firstDate: DateTime(1940),
          lastDate: DateTime(DateTime.now().year + 15),
          onChanged: (d) => change(d.toIso8601String().substring(0, 10)),
        );
      case CrudFieldType.checkbox:
        return AppCheckbox(value: _form[f.key] == true, onChanged: (v) => change(v), label: f.checkboxLabel ?? label);
    }
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) => newValue.copyWith(text: newValue.text.toUpperCase());
}

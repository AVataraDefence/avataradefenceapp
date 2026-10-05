import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../components/layout/main_content.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../components/upload_zone.dart';
import '../../../../core/core.dart';
import '../../../../data/app_api.dart';
import '../../../../data/directory.dart';

/// `/module/projects/details` — long-form project info + documents (web `projects/details/page.tsx`).
class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({super.key});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  List<Rec> _projects = [];
  bool _loading = true;
  int? _projectId;
  final _info = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  String _saveError = '';
  List<Rec> _docs = [];
  bool _docsLoading = false;
  bool _uploading = false;
  String _docError = '';

  Rec? get _project {
    for (final p in _projects) {
      if (p['projectId'] == _projectId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _info.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final r = await AppApi.client.get(ApiEndpoints.projects);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _projects = asRows(r);
    });
  }

  Future<void> _select(int id) async {
    setState(() {
      _projectId = id;
      _saved = false;
      _saveError = '';
      _docError = '';
      _docs = [];
      _docsLoading = true;
      _info.text = '${_project?['projectInfo'] ?? ''}';
    });
    final r = await AppApi.client.get(ApiEndpoints.projectDocuments(id));
    if (!mounted || _projectId != id) return;
    setState(() {
      _docs = asRows(r);
      _docsLoading = false;
    });
  }

  Future<void> _save() async {
    final p = _project;
    if (p == null) {
      setState(() => _saveError = 'Select a project first');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = '';
    });
    final r = await AppApi.client.put(ApiEndpoints.project(_projectId!), body: {'projectInfo': _info.text});
    if (!mounted) return;
    if (r.ok && r.data is Map) p['projectInfo'] = (r.data as Map)['projectInfo'];
    setState(() {
      _saving = false;
      _saved = r.ok;
      if (!r.ok) _saveError = r.message;
    });
    if (r.ok) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _saved = false);
    }
  }

  Future<void> _upload() async {
    final id = _projectId;
    if (id == null) return;
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'webp']);
    if (res.isEmpty || !mounted) return;
    setState(() {
      _uploading = true;
      _docError = '';
    });
    final files = [for (final f in res) if (f.path != null) await http.MultipartFile.fromPath('files', f.path!, filename: f.name)];
    final r = await AppApi.client.postMultipart(ApiEndpoints.projectDocuments(id), files: files);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (r.ok) {
        _docs = [..._docs, ...asRows(r)];
      } else {
        _docError = r.message;
      }
    });
  }

  Future<void> _remove(Rec doc) async {
    final r = await AppApi.client.delete(ApiEndpoints.projectDocument(_projectId!, (doc['docId'] as num).toInt()));
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _docs.remove(doc);
      } else {
        _docError = r.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return MainContent(
      title: 'Projects',
      backHref: '/module/projects',
      sidebarMenu: projectsMenu,
      onRefresh: _loadProjects,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Details', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Full information and documents for a project', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            title: 'Project Details',
            description: 'Select a project and add its detailed information.',
            headerDivider: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSelect<int>(
                  label: 'Project Name',
                  hint: _loading ? 'Loading projects…' : 'Select project',
                  options: [for (final p in _projects) AppOption(value: (p['projectId'] as num).toInt(), label: '${p['projectName']}')],
                  value: _projectId,
                  onChanged: _select,
                ),
                const SizedBox(height: 20),
                AppInput.multiline(controller: _info, label: 'Project Information', hint: 'Enter detailed information about this project…', minLines: 10, maxLines: 14, onChanged: (_) => setState(() {
                      _saved = false;
                      _saveError = '';
                    })),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_saveError.isNotEmpty) Expanded(child: Text(_saveError, style: t.bodySmall?.copyWith(color: c.destructive))) else const Spacer(),
                    AppButton(label: _saving ? 'Saving…' : (_saved ? 'Saved' : 'Save Changes'), loading: _saving, onPressed: _saving ? null : _save),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            title: 'Documents',
            description: 'Attach files related to this project.',
            headerDivider: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UploadZone(
                  title: 'Tap to upload files',
                  subtitle: _projectId == null ? 'Select a project first' : 'You can pick several at once',
                  hint: 'PDF · DOC · DOCX · XLS · XLSX · JPG · PNG · max 10MB',
                  enabled: _projectId != null,
                  busy: _uploading,
                  onTap: _upload,
                ),
                if (_docError.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_docError, style: t.bodySmall?.copyWith(color: c.destructive))),
                if (_docsLoading) const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: AppSpinner(size: 18))),
                if (_docs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('UPLOADED · ${_docs.length}', style: t.labelSmall),
                  const SizedBox(height: 8),
                  for (final d in _docs) ...[
                    FileRow(
                      name: '${d['docName']}',
                      ext: d['extension'] as String?,
                      meta: d['uploadedByName'] as String?,
                      onOpen: d['fileUrl'] == null ? null : () => launchUrl(Uri.parse('${d['fileUrl']}'), mode: LaunchMode.externalApplication),
                      onDelete: () => _remove(d),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

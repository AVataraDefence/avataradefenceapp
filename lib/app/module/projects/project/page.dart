import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/directory.dart';
import '../../../../data/models.dart';

/// `/module/projects/project` (web `projects/project/page.tsx`).
class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Projects',
      backHref: '/module/projects',
      menu: projectsMenu,
      heading: 'Project',
      subtitle: 'Manage every project, its responsible person and timeline',
      addLabel: 'Project',
      recordName: 'Project',
      updateLabel: 'Update Project',
      deleteTarget: (r) => '${r['projectName']}',
      sections: [
        CrudSection('Project Information', 'Name, client and ownership', [
          const CrudField('projectName', 'Project Name', required: true, requiredMessage: 'Project name is required'),
          const CrudField('client', 'Client', required: true, requiredMessage: 'Client is required'),
          const CrudField('responsibleUserId', 'Responsible Person', type: CrudFieldType.select, hint: 'Select responsible person', required: true, requiredMessage: 'Responsible person is required', options: userOptions),
          CrudField('status', 'Status', type: CrudFieldType.select, hint: 'Status', required: true, requiredMessage: 'Status is required', options: () => [for (final s in ProjectStatus.values) AppOption(value: s.api, label: s.label)]),
          const CrudField('description', 'Project Description', type: CrudFieldType.multiline),
        ]),
        const CrudSection('Timeline & Progress', 'Schedule and progress tracking', [
          CrudField('startDate', 'Start Date', type: CrudFieldType.date),
          CrudField('endDate', 'End Date', type: CrudFieldType.date),
          CrudField('progress', 'Progress (%)', enabled: false, helper: "Calculated from the project's task progress."),
        ]),
      ],
      columns: [
        CrudColumn.text('Project', 'projectName', width: 230, bold: true),
        CrudColumn.text('Client', 'client', width: 170),
        CrudColumn.computed('Responsible Person', (r) => '${r['responsibleName'] ?? ''}'.isNotEmpty ? '${r['responsibleName']}' : userNameById(r['responsibleUserId']), width: 170),
        CrudColumn('Status', (ctx, r) => ProjectStatusBadge(ProjectStatusApi.parse(r['status'])), width: 120),
        CrudColumn('Progress', (ctx, r) => SizedBox(width: 140, child: AppProgress(value: (r['progress'] as num?)?.toDouble() ?? 0, showLabel: true)), width: 150),
        CrudColumn.computed('Timeline', (r) {
          final s = parseDate(r['startDate']);
          final e = parseDate(r['endDate']);
          return '${s == null ? '—' : formatAppDate(s)} – ${e == null ? '—' : formatAppDate(e)}';
        }, width: 230),
      ],
      api: const CrudApi('/api/projects', idKey: 'projectId', refresh: ['projects']),
    );
  }
}

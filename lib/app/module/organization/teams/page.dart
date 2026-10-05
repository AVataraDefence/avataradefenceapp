import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../../../../data/directory.dart';

/// `/module/organization/teams` (web `organization/teams/page.tsx`).
class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Organization',
      backHref: '/module/organization',
      menu: organizationMenu,
      heading: 'Teams',
      subtitle: 'Create and manage cross-functional teams',
      addLabel: 'Team',
      recordName: 'Team',
      deleteTarget: (r) => '${r['teamName']}',
      sections: const [
        CrudSection('Team', 'Name, lead and members', [
          CrudField('teamName', 'Team Name', required: true, requiredMessage: 'Team name is required'),
          CrudField('teamLeadId', 'Team Lead', type: CrudFieldType.select, hint: 'Select team lead', required: true, requiredMessage: 'Team lead is required', options: teamPersonOptions),
          CrudField('description', 'Description', type: CrudFieldType.multiline, full: true),
          CrudField('members', 'Members', type: CrudFieldType.multiSelect, hint: 'Select members', full: true, options: teamPersonOptions),
        ]),
      ],
      columns: [
        CrudColumn.text('Team Name', 'teamName', width: 170, bold: true),
        CrudColumn.computed('Lead', (r) => userNameById(r['teamLeadId']), width: 160),
        CrudColumn(
          'Members',
          (ctx, r) {
            final ids = [for (final x in (r['members'] as List? ?? const [])) '$x'];
            if (ids.isEmpty) return Text('—', style: Theme.of(ctx).textTheme.bodyMedium);
            return AppAvatarStack(people: [for (final id in ids) (name: userNameById(id), id: int.tryParse(id), imageUrl: null)], max: 4, size: AppAvatarSize.sm);
          },
          width: 130,
        ),
        CrudColumn.text('Description', 'description', width: 220),
      ],
      api: const CrudApi('/api/organization/teams', idKey: 'teamId'),
    );
  }
}

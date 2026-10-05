import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';

/// `/module/master-data/roles` (web `master-data/roles/page.tsx`).
class RolesPage extends StatelessWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Master Data',
      backHref: '/module/master-data',
      menu: masterDataMenu,
      heading: 'Roles',
      subtitle: 'Manage system roles and access levels',
      addLabel: 'Role',
      recordName: 'Role',
      statusKey: 'isActive',
      softDelete: true,
      deleteTarget: (r) => '${r['name']}',
      sections: const [
        CrudSection('Role', 'Name and purpose of the role', [
          CrudField('name', 'Role Name', hint: 'e.g. Manager', required: true, requiredMessage: 'Role name is required'),
          CrudField('description', 'Description', type: CrudFieldType.multiline, full: true),
        ]),
      ],
      columns: [
        CrudColumn.text('Role Name', 'name', width: 170, bold: true),
        CrudColumn.text('Description', 'description', width: 280),
      ],
      api: const CrudApi('/api/master-data/roles', idKey: 'roleId', refresh: ['roles']),
    );
  }
}

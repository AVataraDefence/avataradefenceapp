import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../data/directory.dart';

/// `/module/master-data/designations` (web `master-data/designations/page.tsx`).
class DesignationsPage extends StatelessWidget {
  const DesignationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Master Data',
      backHref: '/module/master-data',
      menu: masterDataMenu,
      heading: 'Designations',
      subtitle: 'Manage job designations and their departments',
      addLabel: 'Designation',
      recordName: 'Designation',
      statusKey: 'isActive',
      softDelete: true,
      deleteTarget: (r) => '${r['designationName']}',
      sections: const [
        CrudSection('Designation', 'Job title and the department it belongs to', [
          CrudField('designationName', 'Designation Name', hint: 'e.g. Senior Engineer', required: true, requiredMessage: 'Designation name is required'),
          CrudField('departmentId', 'Department', type: CrudFieldType.select, hint: 'Select department', options: departmentOptions),
          CrudField('description', 'Description', type: CrudFieldType.multiline, full: true),
        ]),
      ],
      columns: [
        CrudColumn.text('Designation', 'designationName', width: 170, bold: true),
        CrudColumn.computed('Department', (r) => departmentNameById(r['departmentId']), width: 160),
        CrudColumn.text('Description', 'description', width: 260),
      ],
      api: const CrudApi('/api/master-data/designations', idKey: 'designationId', refresh: ['designations']),
    );
  }
}

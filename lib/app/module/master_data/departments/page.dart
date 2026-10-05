import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../data/directory.dart';

/// `/module/master-data/departments` (web `master-data/departments/page.tsx`).
class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Master Data',
      backHref: '/module/master-data',
      menu: masterDataMenu,
      heading: 'Departments',
      subtitle: 'Manage organisational departments and their heads',
      addLabel: 'Department',
      recordName: 'Department',
      statusKey: 'isActive',
      softDelete: true,
      deleteTarget: (r) => '${r['departmentName']}',
      sections: const [
        CrudSection('New Department', 'Add a new department to the organisation.', [
          CrudField('departmentName', 'Department Name', hint: 'e.g. Operations', required: true, requiredMessage: 'Department name is required'),
          CrudField('headOfDeptId', 'Head of Department', type: CrudFieldType.select, hint: 'Select head of department', options: userOptions),
          CrudField('description', 'Description', type: CrudFieldType.multiline, full: true),
        ]),
      ],
      columns: [
        CrudColumn.text('Department Name', 'departmentName', width: 170, bold: true),
        CrudColumn.computed('Head of Department', (r) => userNameById(r['headOfDeptId']), width: 180),
        CrudColumn.text('Description', 'description', width: 260),
      ],
      api: const CrudApi('/api/master-data/departments', idKey: 'departmentId', refresh: ['departments']),
    );
  }
}

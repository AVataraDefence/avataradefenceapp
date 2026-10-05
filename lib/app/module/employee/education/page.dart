import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _degrees = [
  'Secondary (10th)', 'Higher Secondary (12th)', 'Diploma', 'Bachelor of Technology (B.Tech)', 'Bachelor of Engineering (B.E)',
  'Bachelor of Science (B.Sc)', 'Bachelor of Arts (B.A)', 'Bachelor of Commerce (B.Com)', 'Master of Technology (M.Tech)',
  'Master of Science (M.Sc)', 'Master of Business Administration (MBA)', 'Master of Arts (M.A)', 'Doctor of Philosophy (Ph.D)', 'Other',
];

List<String> _years() => [for (var i = 0; i < 50; i++) '${DateTime.now().year - i}'];

/// `/module/employee/education` (web `employee/education/page.tsx`).
class EmployeeEducationPage extends StatelessWidget {
  const EmployeeEducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Education',
      subtitle: 'Manage educational qualifications for each employee',
      addLabel: 'Record',
      recordName: 'Education',
      updateLabel: 'Update Record',
      deleteTarget: (r) => '${r['degree']}',
      sections: [
        const CrudSection('Employee', 'Link this qualification to an employee', [employeeField]),
        CrudSection('Education Details', 'Degree, institution and result', [
          CrudField('degree', 'Degree / Qualification', type: CrudFieldType.select, hint: 'Degree / Qualification', required: true, requiredMessage: 'Degree is required', options: () => strOptions(_degrees)),
          const CrudField('institution', 'Institution / University', required: true, requiredMessage: 'Institution is required'),
          const CrudField('fieldOfStudy', 'Field of Study'),
          CrudField('startYear', 'Start Year', intValue: true, type: CrudFieldType.select, hint: 'Start Year', options: () => strOptions(_years())),
          CrudField('endYear', 'End Year', intValue: true, type: CrudFieldType.select, hint: 'End Year', options: () => strOptions(_years())),
          const CrudField('grade', 'Grade / Percentage / CGPA'),
          const CrudField('notes', 'Notes', type: CrudFieldType.multiline),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Degree / Qualification', 'degree', width: 230),
        CrudColumn.text('Institution', 'institution', width: 200),
        CrudColumn.text('Field of Study', 'fieldOfStudy', width: 160),
        CrudColumn.text('Start Year', 'startYear', width: 100),
        CrudColumn.text('End Year', 'endYear', width: 100),
        CrudColumn.text('Grade', 'grade', width: 100),
      ],
      api: const CrudApi('/api/employee/education', idKey: 'educationId'),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _relationships = ['Father', 'Mother', 'Spouse', 'Son', 'Daughter', 'Brother', 'Sister', 'Guardian', 'Other'];

/// `/module/employee/family` (web `employee/family/page.tsx`).
class EmployeeFamilyPage extends StatelessWidget {
  const EmployeeFamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Family Details',
      subtitle: 'Manage family members and dependents for each employee',
      addLabel: 'Record',
      recordName: 'Family Member',
      updateLabel: 'Update Record',
      deleteTarget: (r) => '${r['memberName']}',
      sections: [
        const CrudSection('Employee', 'Link this family member to an employee', [employeeField]),
        CrudSection('Member Details', 'Family member information', [
          const CrudField('memberName', 'Member Name', required: true, requiredMessage: 'Member name is required'),
          CrudField('relationship', 'Relationship', type: CrudFieldType.select, hint: 'Relationship', required: true, requiredMessage: 'Relationship is required', options: () => strOptions(_relationships)),
          const CrudField('dateOfBirth', 'Date of Birth', type: CrudFieldType.date),
          CrudField('gender', 'Gender', type: CrudFieldType.select, hint: 'Gender', options: () => strOptions(genders)),
          const CrudField('phone', 'Phone', type: CrudFieldType.phone),
          const CrudField('occupation', 'Occupation'),
          const CrudField('isDependent', 'Dependent', type: CrudFieldType.checkbox, checkboxLabel: 'This member is a dependent of the employee'),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Member Name', 'memberName', width: 150, bold: true),
        CrudColumn.pill('Relationship', 'relationship', width: 120),
        CrudColumn.date('Date of Birth', 'dateOfBirth'),
        CrudColumn.text('Gender', 'gender', width: 90),
        CrudColumn.text('Occupation', 'occupation', width: 140),
        CrudColumn.text('Phone', 'phone', width: 140),
        CrudColumn.yesNo('Dependent', 'isDependent', width: 100),
      ],
      api: const CrudApi('/api/employee/family', idKey: 'familyId'),
    );
  }
}

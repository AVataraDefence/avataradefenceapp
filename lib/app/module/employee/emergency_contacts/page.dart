import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _relationships = ['Father', 'Mother', 'Spouse', 'Son', 'Daughter', 'Brother', 'Sister', 'Guardian', 'Friend', 'Other'];

/// `/module/employee/emergency-contacts` (web `employee/emergency-contacts/page.tsx`).
class EmployeeEmergencyContactsPage extends StatelessWidget {
  const EmployeeEmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Emergency Contacts',
      subtitle: 'Manage emergency contact persons for each employee',
      addLabel: 'Record',
      recordName: 'Contact',
      updateLabel: 'Update Record',
      deleteTarget: (r) => '${r['contactName']}',
      sections: [
        const CrudSection('Employee', 'Link this emergency contact to an employee', [employeeField]),
        CrudSection('Contact Details', 'Who to call in an emergency', [
          const CrudField('contactName', 'Contact Name', required: true, requiredMessage: 'Contact name is required'),
          CrudField('relationship', 'Relationship', type: CrudFieldType.select, hint: 'Relationship', options: () => strOptions(_relationships)),
          const CrudField('primaryPhone', 'Primary Phone', type: CrudFieldType.phone, required: true, requiredMessage: 'Primary phone is required'),
          const CrudField('alternatePhone', 'Alternate Phone', type: CrudFieldType.phone),
          const CrudField('email', 'Email', type: CrudFieldType.email),
          const CrudField('address', 'Address', full: true),
          const CrudField('isPrimary', 'Primary', type: CrudFieldType.checkbox, checkboxLabel: 'Set as primary emergency contact'),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Contact Name', 'contactName', width: 150, bold: true),
        CrudColumn.pill('Relationship', 'relationship', width: 120),
        CrudColumn.text('Primary Phone', 'primaryPhone', width: 140),
        CrudColumn.text('Alternate Phone', 'alternatePhone', width: 140),
        CrudColumn.text('Email', 'email', width: 200),
        CrudColumn.text('Address', 'address', width: 180),
        CrudColumn.yesNo('Primary', 'isPrimary'),
      ],
      api: const CrudApi('/api/employee/emergency-contacts', idKey: 'emergencyId'),
    );
  }
}

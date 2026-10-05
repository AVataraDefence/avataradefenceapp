import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

/// `/module/employee/contact` (web `employee/contact/page.tsx`).
class EmployeeContactPage extends StatelessWidget {
  const EmployeeContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Contact Details',
      subtitle: 'Manage employee phone, email and address information',
      addLabel: 'Record',
      recordName: 'Contact',
      updateLabel: 'Update Record',
      initialValues: const {'country': 'India'},
      deleteTarget: (r) => 'this contact record',
      sections: [
        const CrudSection('Employee', 'Link this contact record to an employee', [employeeField]),
        const CrudSection('Phone & Email', 'How to reach the employee', [
          CrudField('personalPhone', 'Personal Phone', type: CrudFieldType.phone),
          CrudField('workPhone', 'Work Phone', type: CrudFieldType.phone),
          CrudField('personalEmail', 'Personal Email', type: CrudFieldType.email),
          CrudField('workEmail', 'Work Email', type: CrudFieldType.email),
        ]),
        CrudSection('Address', 'Current and permanent address', [
          const CrudField('currentAddress', 'Current Address', full: true),
          const CrudField('permanentAddress', 'Permanent Address', full: true),
          const CrudField('city', 'City'),
          CrudField('state', 'State', type: CrudFieldType.select, hint: 'State', options: () => strOptions(indianStates)),
          const CrudField('pinCode', 'Pin Code', type: CrudFieldType.number),
          const CrudField('country', 'Country'),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Personal Phone', 'personalPhone', width: 140),
        CrudColumn.text('Work Phone', 'workPhone', width: 140),
        CrudColumn.text('Personal Email', 'personalEmail', width: 210),
        CrudColumn.text('Work Email', 'workEmail', width: 220),
        CrudColumn.text('City', 'city', width: 110),
        CrudColumn.text('State', 'state', width: 130),
      ],
      api: const CrudApi('/api/employee/contact', idKey: 'contactId'),
    );
  }
}

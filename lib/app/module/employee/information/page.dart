import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../data/directory.dart';
import '../common.dart';

/// `/module/employee/information` (web `employee/information/page.tsx`).
class EmployeeInformationPage extends StatelessWidget {
  const EmployeeInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Information',
      subtitle: 'Manage employee personal and employment details',
      addLabel: 'Record',
      recordName: 'Employee',
      saveLabel: 'Save Changes',
      updateLabel: 'Update Employee',
      statusKey: 'isActive',
      initialValuesBuilder: () => {'employeeNumber': nextEmployeeNumber()},
      deleteTarget: (r) => '${r['firstName']} ${r['lastName']}',
      softDelete: true,
      sections: [
        CrudSection('Basic Information', 'Employee identity and personal details', [
          const CrudField('firstName', 'First Name', required: true, requiredMessage: 'First name is required'),
          const CrudField('middleName', 'Middle Name'),
          const CrudField('lastName', 'Last Name', required: true, requiredMessage: 'Last name is required'),
          const CrudField('dateOfBirth', 'Date of Birth', type: CrudFieldType.date),
          CrudField('gender', 'Gender', type: CrudFieldType.select, hint: 'Gender', options: () => strOptions(genders)),
          CrudField('bloodGroup', 'Blood Group', type: CrudFieldType.select, hint: 'Blood Group', options: () => strOptions(bloodGroups)),
          const CrudField('nationality', 'Nationality'),
          CrudField('maritalStatus', 'Marital Status', type: CrudFieldType.select, hint: 'Marital Status', options: () => strOptions(maritalStatuses)),
        ]),
        CrudSection('Employment Details', 'Job-related information and assignment', [
          const CrudField('employeeNumber', 'Employee Number', enabled: false),
          const CrudField('dateOfJoining', 'Date of Joining', type: CrudFieldType.date),
          const CrudField('departmentId', 'Department', type: CrudFieldType.select, hint: 'Select department', options: departmentOptions),
          const CrudField('designationId', 'Designation', type: CrudFieldType.select, hint: 'Select designation', options: designationOptions),
          CrudField('employmentType', 'Employment Type', type: CrudFieldType.select, hint: 'Employment Type', options: () => strOptions(employmentTypesShort)),
          const CrudField('userId', 'Linked User Account', type: CrudFieldType.select, hint: 'Select user account', options: userOptions),
        ]),
      ],
      columns: [
        CrudColumn.text('Emp No', 'employeeNumber', width: 100, bold: true).asSubtitle(),
        CrudColumn.computed('Full Name', (r) => '${r['firstName']} ${r['middleName'] ?? ''} ${r['lastName']}'.replaceAll('  ', ' ').trim(), width: 170, bold: true).asTitle(),
        CrudColumn.text('Gender', 'gender', width: 90),
        CrudColumn.text('Blood Group', 'bloodGroup', width: 110),
        CrudColumn.computed('Department', (r) => departmentNameById(r['departmentId']), width: 140),
        CrudColumn.computed('Designation', (r) => designationNameById(r['designationId']), width: 150),
        CrudColumn.pill('Emp Type', 'employmentType', width: 120),
        CrudColumn.date('Date of Joining', 'dateOfJoining', width: 140),
      ],
      api: const CrudApi('/api/employee/information', idKey: 'employeeId', refresh: ['employees']),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _employmentTypes = ['Full-time', 'Part-time', 'Contract', 'Internship', 'Freelance', 'Consultant'];

/// `/module/employee/work-experience` (web `employee/work-experience/page.tsx`).
class EmployeeWorkExperiencePage extends StatelessWidget {
  const EmployeeWorkExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Work Experience',
      subtitle: 'Manage work history and professional experience for each employee',
      addLabel: 'Record',
      recordName: 'Experience',
      updateLabel: 'Update Record',
      deleteTarget: (r) => '${r['jobTitle']} at ${r['companyName']}',
      sections: [
        const CrudSection('Employee', 'Link this experience to an employee', [employeeField]),
        CrudSection('Experience Details', 'Company, role and dates', [
          const CrudField('companyName', 'Company Name', required: true, requiredMessage: 'Company name is required'),
          const CrudField('jobTitle', 'Job Title / Designation', required: true, requiredMessage: 'Job title is required'),
          const CrudField('department', 'Department'),
          CrudField('employmentType', 'Employment Type', type: CrudFieldType.select, hint: 'Employment Type', options: () => strOptions(_employmentTypes)),
          const CrudField('location', 'Location'),
          const CrudField('startDate', 'Start Date', type: CrudFieldType.date),
          const CrudField('endDate', 'End Date', type: CrudFieldType.date),
          const CrudField('isCurrent', 'Current', type: CrudFieldType.checkbox, checkboxLabel: 'I currently work here'),
          const CrudField('description', 'Description / Responsibilities', type: CrudFieldType.multiline),
          const CrudField('reasonForLeaving', 'Reason for Leaving', type: CrudFieldType.multiline),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Company', 'companyName', width: 170, bold: true),
        CrudColumn.text('Job Title', 'jobTitle', width: 160),
        CrudColumn.text('Department', 'department', width: 130),
        CrudColumn.pill('Type', 'employmentType', width: 120),
        CrudColumn.date('Start Date', 'startDate'),
        CrudColumn.date('End Date', 'endDate'),
        CrudColumn.yesNo('Current', 'isCurrent'),
        CrudColumn.text('Location', 'location', width: 120),
      ],
      api: const CrudApi('/api/employee/work-experience', idKey: 'experienceId'),
    );
  }
}

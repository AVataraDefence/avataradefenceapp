import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _types = ['Skill', 'Certification'];
const _categories = ['Technical', 'Software', 'Hardware', 'Networking', 'Defence Systems', 'Management', 'Language', 'Soft Skills', 'Other'];
const _levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

/// `/module/employee/skills` (web `employee/skills/page.tsx`).
class EmployeeSkillsPage extends StatelessWidget {
  const EmployeeSkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Skills & Certifications',
      subtitle: 'Manage skills and professional certifications for each employee',
      addLabel: 'Record',
      recordName: 'Skill',
      updateLabel: 'Update Record',
      deleteTarget: (r) => '${r['skillName']}',
      sections: [
        const CrudSection('Employee', 'Link this skill or certification to an employee', [employeeField]),
        CrudSection('Skill / Certification Details', 'What it is and who issued it', [
          CrudField('type', 'Type', type: CrudFieldType.select, hint: 'Type', required: true, requiredMessage: 'Type is required', options: () => strOptions(_types)),
          const CrudField('skillName', 'Name', required: true, requiredMessage: 'Name is required'),
          CrudField('category', 'Category', type: CrudFieldType.select, hint: 'Category', options: () => strOptions(_categories)),
          CrudField('proficiencyLevel', 'Proficiency Level', type: CrudFieldType.select, hint: 'Proficiency Level', options: () => strOptions(_levels)),
          const CrudField('issuingOrg', 'Issuing Organisation'),
          const CrudField('certificateNumber', 'Certificate Number'),
          const CrudField('issueDate', 'Issue Date', type: CrudFieldType.date),
          const CrudField('expiryDate', 'Expiry Date', type: CrudFieldType.date),
          const CrudField('notes', 'Notes', type: CrudFieldType.multiline),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.pill('Type', 'type', width: 120),
        CrudColumn.text('Name', 'skillName', width: 190, bold: true),
        CrudColumn.text('Category', 'category', width: 140),
        CrudColumn.text('Proficiency', 'proficiencyLevel', width: 120),
        CrudColumn.text('Issuing Org', 'issuingOrg', width: 160),
        CrudColumn.date('Issue Date', 'issueDate'),
        CrudColumn.date('Expiry Date', 'expiryDate'),
      ],
      api: const CrudApi('/api/employee/skills', idKey: 'skillId'),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../core/core.dart';
import '../common.dart';

const _recordTypes = [
  'Annual Health Checkup', 'Blood Test', 'Vision Test', 'Hearing Test', 'Vaccination', 'X-Ray', 'ECG', 'Fitness Certificate',
  'Medical Certificate', 'Dental Checkup', 'Physical Fitness Test', 'Psychiatric Evaluation', 'Other',
];
const _fitness = ['Fit', 'Conditionally Fit', 'Unfit', 'Pending Review'];

/// `/module/employee/medical` (web `employee/medical/page.tsx`).
class EmployeeMedicalPage extends StatelessWidget {
  const EmployeeMedicalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Medical Records',
      subtitle: 'Manage health checkups, fitness certificates and medical history',
      addLabel: 'Record',
      recordName: 'Medical Record',
      updateLabel: 'Update Record',
      deleteTarget: (r) => 'the ${r['recordType']} record',
      sections: [
        const CrudSection('Employee', 'Link this medical record to an employee', [employeeField]),
        CrudSection('Examination Details', 'Checkup, measurements and fitness', [
          CrudField('recordType', 'Record Type', type: CrudFieldType.select, hint: 'Record Type', required: true, requiredMessage: 'Record type is required', options: () => strOptions(_recordTypes)),
          const CrudField('examinationDate', 'Date of Examination', type: CrudFieldType.date, required: true, requiredMessage: 'Examination date is required'),
          const CrudField('nextDueDate', 'Next Due Date', type: CrudFieldType.date),
          const CrudField('doctor', 'Doctor / Medical Officer'),
          const CrudField('hospital', 'Hospital / Clinic'),
          CrudField('fitnessStatus', 'Fitness Status', type: CrudFieldType.select, hint: 'Fitness Status', options: () => strOptions(_fitness)),
          CrudField('bloodGroup', 'Blood Group', type: CrudFieldType.select, hint: 'Blood Group', options: () => strOptions(bloodGroups)),
          const CrudField('height', 'Height (cm)', type: CrudFieldType.number, intValue: true),
          const CrudField('weight', 'Weight (kg)', type: CrudFieldType.number, intValue: true),
          const CrudField('bloodPressure', 'Blood Pressure', hint: 'e.g. 120/80'),
          const CrudField('remarks', 'Remarks', type: CrudFieldType.multiline),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Record Type', 'recordType', width: 180),
        CrudColumn.date('Exam Date', 'examinationDate'),
        CrudColumn.text('Doctor', 'doctor', width: 150),
        CrudColumn.text('Hospital / Clinic', 'hospital', width: 170),
        CrudColumn.text('Blood Group', 'bloodGroup', width: 110),
        CrudColumn.text('Height', 'height', width: 80),
        CrudColumn.text('Weight', 'weight', width: 80),
        CrudColumn.text('BP', 'bloodPressure', width: 90),
        CrudColumn.status('Fitness Status', 'fitnessStatus', {'Fit': TwColors.green700, 'Conditionally Fit': TwColors.amber700, 'Unfit': TwColors.red700}, width: 150),
        CrudColumn.date('Next Due', 'nextDueDate'),
      ],
      api: const CrudApi('/api/employee/medical', idKey: 'medicalId'),
    );
  }
}

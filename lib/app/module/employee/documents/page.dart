import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../../../../components/upload_zone.dart';
import '../../../../core/core.dart';
import '../common.dart';

const _docTypes = [
  'Aadhaar Card', 'PAN Card', 'Passport', 'Driving Licence', 'Voter ID', 'Birth Certificate', 'Education Certificate', 'Experience Letter',
  'Offer Letter', 'Appointment Letter', 'Joining Letter', 'Relieving Letter', 'Salary Slip', 'NOC', 'Medical Fitness Certificate',
  'Police Verification Certificate', 'Security Clearance Certificate', 'Other',
];
const _statuses = ['Valid', 'Expired', 'Pending Verification', 'Under Renewal'];

/// `/module/employee/documents` (web `employee/documents/page.tsx`).
class EmployeeDocumentsPage extends StatelessWidget {
  const EmployeeDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Documents',
      subtitle: 'Manage identity documents, certificates and official records for each employee',
      addLabel: 'Record',
      recordName: 'Document',
      updateLabel: 'Update Record',
      deleteTarget: (r) => 'the ${r['documentType']}',
      sections: [
        const CrudSection('Employee', 'Link this document to an employee', [employeeField]),
        CrudSection('Document Details', 'Type, number and validity', [
          CrudField('documentType', 'Document Type *', type: CrudFieldType.select, hint: 'Document Type', required: true, requiredMessage: 'Document type is required', options: () => strOptions(_docTypes)),
          const CrudField('documentNumber', 'Document Number'),
          const CrudField('issueDate', 'Issue Date', type: CrudFieldType.date),
          const CrudField('expiryDate', 'Expiry Date', type: CrudFieldType.date),
          CrudField('status', 'Status', type: CrudFieldType.select, hint: 'Status', options: () => strOptions(_statuses)),
          const CrudField('issuingAuthority', 'Issuing Authority'),
          const CrudField('remarks', 'Remarks', type: CrudFieldType.multiline),
        ]),
        const CrudSection.upload('Attach File', 'PDF, image or Word document up to 10MB', 'fileName'),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Document Type', 'documentType', width: 190),
        CrudColumn.text('Document Number', 'documentNumber', width: 160, mono: true),
        CrudColumn.date('Issue Date', 'issueDate'),
        CrudColumn.date('Expiry Date', 'expiryDate'),
        CrudColumn.text('Issuing Authority', 'issuingAuthority', width: 170),
        CrudColumn.status('Status', 'status', {'Valid': TwColors.green700, 'Expired': TwColors.red700, 'Pending Verification': TwColors.amber700, 'Under Renewal': TwColors.blue700}, width: 170),
        CrudColumn('File', (ctx, r) {
          final name = '${r['fileName'] ?? ''}';
          if (name.isEmpty) return Text('—', style: Theme.of(ctx).textTheme.bodyMedium);
          final f = fileIconFor(name.split('.').last);
          return Icon(f.icon, size: 18, color: f.color);
        }, width: 70),
      ],
      api: const CrudApi('/api/employee/documents', idKey: 'documentId', multipart: true),
    );
  }
}

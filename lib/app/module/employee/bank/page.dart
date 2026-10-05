import 'package:flutter/material.dart';

import '../../../../components/crud/crud_page.dart';
import '../../../../components/layout/sidebar_menu.dart';
import '../common.dart';

const _accountTypes = ['Savings', 'Current', 'Salary', 'NRE', 'NRO'];
const _banks = [
  'State Bank of India (SBI)', 'Bank of Baroda', 'Punjab National Bank', 'Canara Bank', 'Union Bank of India', 'HDFC Bank', 'ICICI Bank',
  'Axis Bank', 'Kotak Mahindra Bank', 'IndusInd Bank', 'Yes Bank', 'IDFC First Bank', 'Federal Bank', 'Bank of India',
  'Central Bank of India', 'Indian Bank', 'UCO Bank', 'Other',
];

String _mask(String num) {
  final clean = num.replaceAll(RegExp(r'\s'), '');
  return clean.length <= 4 ? num : '•••• •••• •••• ${clean.substring(clean.length - 4)}';
}

/// `/module/employee/bank` (web `employee/bank/page.tsx`).
class EmployeeBankPage extends StatelessWidget {
  const EmployeeBankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: 'Employee',
      backHref: '/module/employee',
      menu: employeeMenu,
      heading: 'Employee Bank Details',
      subtitle: 'Manage bank accounts and salary disbursement details for each employee',
      addLabel: 'Record',
      recordName: 'Bank Record',
      updateLabel: 'Update Record',
      deleteTarget: (r) => 'the ${r['bankName']} account',
      sections: [
        const CrudSection('Employee', 'Link this bank account to an employee', [employeeField]),
        CrudSection('Bank Details', 'Account and branch information', [
          CrudField('bankName', 'Bank Name', type: CrudFieldType.select, hint: 'Bank Name', required: true, requiredMessage: 'Bank name is required', options: () => strOptions(_banks)),
          CrudField('accountType', 'Account Type', type: CrudFieldType.select, hint: 'Account Type', options: () => strOptions(_accountTypes)),
          const CrudField('accountNumber', 'Account Number', type: CrudFieldType.number, required: true, requiredMessage: 'Account number is required'),
          const CrudField('accountHolderName', 'Account Holder Name'),
          const CrudField('ifscCode', 'IFSC Code', uppercase: true, required: true, requiredMessage: 'IFSC code is required'),
          const CrudField('branchName', 'Branch Name'),
          const CrudField('branchAddress', 'Branch Address', full: true),
          const CrudField('isPrimary', 'Primary', type: CrudFieldType.checkbox, checkboxLabel: 'Set as primary account (used for salary disbursement)'),
        ]),
      ],
      columns: [
        ...employeeColumns(),
        CrudColumn.text('Bank Name', 'bankName', width: 190),
        CrudColumn.computed('Account Number', (r) => _mask('${r['accountNumber'] ?? ''}'), width: 170, mono: true),
        CrudColumn.pill('Type', 'accountType', width: 110),
        CrudColumn.text('IFSC Code', 'ifscCode', width: 130, mono: true),
        CrudColumn.text('Branch', 'branchName', width: 140),
        CrudColumn.text('Account Holder', 'accountHolderName', width: 160),
        CrudColumn.yesNo('Primary', 'isPrimary'),
      ],
      api: const CrudApi('/api/employee/bank', idKey: 'bankId'),
    );
  }
}

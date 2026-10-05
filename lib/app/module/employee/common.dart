import '../../../components/crud/crud_page.dart';
import '../../../core/core.dart';
import '../../../data/directory.dart';

/// Picker lists shared by the Employee pages (same constants the web pages declare).
const genders = ['Male', 'Female', 'Other'];
const bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];
const maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];
const employmentTypesShort = ['Full-time', 'Part-time', 'Contract', 'Intern'];
const indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
  'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
  'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Jammu & Kashmir', 'Ladakh', 'Delhi', 'Chandigarh',
];

List<AppOption<String>> strOptions(List<String> values) => [for (final v in values) AppOption(value: v, label: v)];

/// "Employee" picker at the top of nearly every Employee form.
const employeeField = CrudField('employeeId', 'Employee', type: CrudFieldType.select, hint: 'Select employee', required: true, requiredMessage: 'Employee is required', options: employeeOptions);

/// "Emp No" + "Employee Name" columns every Employee table starts with.
List<CrudColumn> employeeColumns() => [
      CrudColumn.computed('Emp No', (r) => employeeNumberById(r['employeeId']), width: 100, bold: true).asSubtitle(),
      CrudColumn.computed('Employee Name', (r) => employeeNameById(r['employeeId']), width: 170, bold: true).asTitle(),
    ];

DateTime ago(int years, [int month = 1, int day = 1]) => DateTime(DateTime.now().year - years, month, day);
String iso(DateTime d) => d.toIso8601String().substring(0, 10);

// Live check of the field names the app sends, against the running web server:
//   dart run -DAPI_BASE_URL=http://localhost:3000 tool/live_check.dart <session-jwt>
// For each resource: create → update → delete (rows it creates are removed again).
import 'dart:io';

import 'package:avataradefence/core/api/api.dart';

Future<void> main(List<String> args) async {
  final store = MemorySessionStore();
  await store.write(args.first);
  final api = ApiClient(sessionStore: store);
  await api.restoreSession();
  var failures = 0;

  void report(String name, ApiResult<dynamic> r, [String? extra]) {
    if (!r.ok) failures++;
    stdout.writeln('${r.ok ? 'OK  ' : 'FAIL'} $name ${r.ok ? '' : '-> ${r.statusCode} ${r.message}'} ${extra ?? ''}');
  }

  Future<void> crud(String name, String path, String idKey, Map<String, dynamic> create, Map<String, dynamic> update) async {
    final list = await api.get(path);
    report('$name list', list, '(${(list.data as List?)?.length ?? 0} rows)');
    final c = await api.post(path, body: create);
    report('$name create', c);
    if (!c.ok || c.data is! Map) return;
    final id = (c.data as Map)[idKey];
    stdout.writeln('     id=$id keys: ${(c.data as Map).keys.join(',')}');
    report('$name update', await api.put('$path/$id', body: update));
    report('$name delete', await api.delete('$path/$id'));
  }

  report('permissions', await api.get(ApiEndpoints.myPermissions));

  final emps = await api.get(ApiEndpoints.employeeInformation);
  final empId = (emps.data as List).isEmpty ? null : (emps.data as List).first['employeeId'];
  stdout.writeln('employee used: $empId');
  if (empId != null) {
    await crud('contact', ApiEndpoints.employeeContact, 'contactId', {'employeeId': empId, 'personalPhone': '9', 'workPhone': '', 'personalEmail': '', 'workEmail': '', 'currentAddress': 'x', 'permanentAddress': '', 'city': 'Pune', 'state': 'Maharashtra', 'pinCode': '411001', 'country': 'India'}, {'city': 'Mumbai'});
    await crud('emergency', ApiEndpoints.employeeEmergencyContacts, 'emergencyId', {'employeeId': empId, 'contactName': 'T', 'relationship': 'Friend', 'primaryPhone': '9', 'alternatePhone': '', 'email': '', 'address': '', 'isPrimary': false}, {'contactName': 'T2'});
    await crud('family', ApiEndpoints.employeeFamily, 'familyId', {'employeeId': empId, 'memberName': 'T', 'relationship': 'Other', 'dateOfBirth': '', 'gender': '', 'phone': '', 'occupation': '', 'isDependent': false}, {'memberName': 'T2'});
    await crud('education', ApiEndpoints.employeeEducation, 'educationId', {'employeeId': empId, 'degree': 'Diploma', 'institution': 'X', 'fieldOfStudy': '', 'startYear': 2015, 'endYear': 2018, 'grade': '', 'notes': ''}, {'grade': 'A'});
    await crud('work', ApiEndpoints.employeeWorkExperience, 'experienceId', {'employeeId': empId, 'companyName': 'X', 'jobTitle': 'Y', 'department': '', 'employmentType': 'Full-time', 'location': '', 'startDate': '2020-01-01', 'endDate': '', 'isCurrent': true, 'description': '', 'reasonForLeaving': ''}, {'jobTitle': 'Z'});
    await crud('skills', ApiEndpoints.employeeSkills, 'skillId', {'employeeId': empId, 'type': 'Skill', 'skillName': 'Dart', 'category': 'Software', 'proficiencyLevel': 'Advanced', 'issuingOrg': '', 'certificateNumber': '', 'issueDate': '', 'expiryDate': '', 'notes': ''}, {'proficiencyLevel': 'Expert'});
    await crud('medical', ApiEndpoints.employeeMedical, 'medicalId', {'employeeId': empId, 'recordType': 'Blood Test', 'examinationDate': '2026-01-01', 'nextDueDate': '', 'doctor': '', 'hospital': '', 'fitnessStatus': 'Fit', 'bloodGroup': 'O+', 'height': 170, 'weight': 70, 'bloodPressure': '', 'remarks': ''}, {'remarks': 'ok'});
    await crud('bank', ApiEndpoints.employeeBank, 'bankId', {'employeeId': empId, 'bankName': 'HDFC Bank', 'accountType': 'Savings', 'accountNumber': '1234567890', 'accountHolderName': 'T', 'ifscCode': 'HDFC0000001', 'branchName': '', 'branchAddress': '', 'isPrimary': false}, {'branchName': 'B'});
  }
  await crud('role', ApiEndpoints.roles, 'roleId', {'name': 'ZZ Test Role', 'description': 'tmp'}, {'description': 'tmp2'});
  await crud('department', ApiEndpoints.departments, 'departmentId', {'departmentName': 'ZZ Test Dept', 'description': 'tmp'}, {'description': 'tmp2'});
  await crud('designation', ApiEndpoints.designations, 'designationId', {'designationName': 'ZZ Test Desig', 'description': 'tmp'}, {'description': 'tmp2'});

  for (final p in [ApiEndpoints.settingsUsers, ApiEndpoints.teams, ApiEndpoints.projects, ApiEndpoints.projectUsers, ApiEndpoints.taskUsers, ApiEndpoints.taskProjects, ApiEndpoints.taskTeam, ApiEndpoints.employeeDocuments, ApiEndpoints.notifications, ApiEndpoints.settingsProfile]) {
    final r = await api.get(p);
    final sample = r.data is List && (r.data as List).isNotEmpty ? ((r.data as List).first as Map).keys.join(',') : '';
    report('GET $p', r, sample);
  }
  final users = await api.get(ApiEndpoints.settingsUsers);
  final lead = ((users.data as List).first as Map)['userId'];
  await crud('team', ApiEndpoints.teams, 'teamId', {'teamName': 'ZZ Test Team', 'teamLeadId': lead, 'description': '', 'members': [lead]}, {'description': 'x'});
  stdout.writeln(failures == 0 ? '\nALL OK' : '\n$failures FAILED');
  exit(failures == 0 ? 0 : 1);
}

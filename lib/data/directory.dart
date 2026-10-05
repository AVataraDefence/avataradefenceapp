import 'package:flutter/foundation.dart';

import '../core/core.dart';
import 'app_api.dart';

/// One API record (JSON object).
typedef Rec = Map<String, dynamic>;

String _s(Object? v) => '${v ?? ''}';

// ── Name helpers (users, employees …) ────────────────────────────────────────────
String userFullName(Rec u) => [u['firstName'], u['middleName'], u['lastName']].where((s) => _s(s).trim().isNotEmpty).join(' ');

/// Lookup lists shared by the pickers and table cells: loaded once after sign-in and refreshed
/// after the screen that owns a list changes it.
class Directory extends ChangeNotifier {
  Directory._();
  static final Directory instance = Directory._();

  List<Rec> employees = [];
  List<Rec> users = [];
  List<Rec> departments = [];
  List<Rec> designations = [];
  List<Rec> roles = [];
  List<Rec> projects = [];

  /// Loads every list the signed-in user may read (a 403 just leaves that list empty).
  Future<void> load() async {
    await Future.wait([for (final k in _paths.keys) refresh(k, notify: false)]);
    notifyListeners();
  }

  static const _paths = {
    'employees': ApiEndpoints.employeeInformation,
    'users': ApiEndpoints.settingsUsers,
    'departments': ApiEndpoints.departments,
    'designations': ApiEndpoints.designations,
    'roles': ApiEndpoints.roles,
    'projects': ApiEndpoints.projects,
  };

  Future<void> refresh(String key, {bool notify = true}) async {
    final path = _paths[key];
    if (path == null) return;
    final rows = asRows(await AppApi.client.get(path));
    switch (key) {
      case 'employees':
        employees = rows;
      case 'users':
        users = rows;
      case 'departments':
        departments = rows;
      case 'designations':
        designations = rows;
      case 'roles':
        roles = rows;
      case 'projects':
        projects = rows;
    }
    if (notify) notifyListeners();
  }

  void clear() {
    employees = users = departments = designations = roles = projects = [];
    notifyListeners();
  }
}

Directory get _d => Directory.instance;

Rec? _byId(List<Rec> rows, String idKey, Object? id) {
  for (final r in rows) {
    if (_s(r[idKey]) == _s(id)) return r;
  }
  return null;
}

String userNameById(Object? id) {
  final u = _byId(_d.users, 'userId', id);
  if (u != null) return userFullName(u);
  // Users the signed-in role cannot list may still appear as employees.
  for (final e in _d.employees) {
    if (_s(e['userId']) == _s(id)) return _empName(e);
  }
  return '—';
}

String _empName(Rec e) => userFullName(e);
String employeeNameById(Object? id) {
  final e = _byId(_d.employees, 'employeeId', id);
  return e == null ? '—' : _empName(e);
}

String employeeNumberById(Object? id) => _s(_byId(_d.employees, 'employeeId', id)?['employeeNumber']).ifEmpty('—');
String departmentNameById(Object? id) => _s(_byId(_d.departments, 'departmentId', id)?['departmentName']).ifEmpty('—');
String designationNameById(Object? id) => _s(_byId(_d.designations, 'designationId', id)?['designationName']).ifEmpty('—');
String projectNameById(Object? id) => _s(_byId(_d.projects, 'projectId', id)?['projectName']);

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}

// ── Picker options (value = the id as a string) ──────────────────────────────────
List<AppOption<String>> userOptions() => [
      for (final u in _d.users.where((u) => u['isActive'] != false)) AppOption(value: _s(u['userId']), label: userFullName(u), subtitle: u['roleName'] as String?),
    ];

List<AppOption<String>> employeeOptions() => [
      for (final e in _d.employees.where((e) => e['isActive'] != false)) AppOption(value: _s(e['employeeId']), label: _empName(e), subtitle: e['employeeNumber'] as String?),
    ];

/// Team lead / members: employees that have a linked user account (the team stores user ids).
List<AppOption<String>> teamPersonOptions() => [
      for (final e in _d.employees.where((e) => e['isActive'] != false && e['userId'] != null)) AppOption(value: _s(e['userId']), label: _empName(e), subtitle: e['employeeNumber'] as String?),
    ];

List<AppOption<String>> departmentOptions() => [for (final d in _d.departments.where((d) => d['isActive'] != false)) AppOption(value: _s(d['departmentId']), label: _s(d['departmentName']))];
List<AppOption<String>> designationOptions() => [for (final d in _d.designations.where((d) => d['isActive'] != false)) AppOption(value: _s(d['designationId']), label: _s(d['designationName']))];
List<AppOption<String>> roleOptions() => [for (final r in _d.roles.where((r) => r['isActive'] != false)) AppOption(value: _s(r['roleId']), label: _s(r['name']))];

/// Next free `EMP-###` (shown disabled on the new-employee form; the server assigns the real one).
String nextEmployeeNumber() {
  var max = 0;
  for (final e in _d.employees) {
    final n = int.tryParse(_s(e['employeeNumber']).replaceAll(RegExp(r'[^0-9]'), ''));
    if (n != null && n > max) max = n;
  }
  return 'EMP-${(max + 1).toString().padLeft(3, '0')}';
}

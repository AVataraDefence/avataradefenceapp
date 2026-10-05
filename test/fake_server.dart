import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:avataradefence/core/api/api.dart';
import 'package:avataradefence/data/app_api.dart';

/// A tiny in-memory stand-in for the web API so screens can be tested end to end
/// (sign in → permissions → lists → create / delete) without a network.
class FakeServer {
  FakeServer() {
    banks = [
      {'bankId': 1, 'employeeId': 2, 'bankName': 'HDFC Bank', 'accountType': 'Salary', 'accountNumber': '50100234567890', 'accountHolderName': 'Rushikesh Ravtale', 'ifscCode': 'HDFC0000123', 'branchName': 'Kothrud', 'branchAddress': '', 'isPrimary': true},
    ];
  }

  late List<Map<String, dynamic>> banks;
  final List<String> calls = [];
  Map<String, dynamic>? lastBody;

  static const user = {'userId': 1, 'username': 'rushi', 'email': 'rushi@example.com', 'roleId': 1, 'roleName': 'Superuser', 'imageUrl': null};

  static const _employees = [
    {'employeeId': 2, 'firstName': 'Rushikesh', 'middleName': '', 'lastName': 'Ravtale', 'employeeNumber': 'EMP-002', 'isActive': true, 'userId': 1},
    {'employeeId': 13, 'firstName': 'Purvesh', 'middleName': '', 'lastName': 'Bagal', 'employeeNumber': 'EMP-013', 'isActive': true, 'userId': 2},
  ];

  static const _users = [
    {'userId': 1, 'firstName': 'Rushikesh', 'middleName': '', 'lastName': 'Ravtale', 'email': 'rushi@example.com', 'phoneNo': '8999984137', 'username': 'rushi', 'roleId': 1, 'roleName': 'Superuser', 'isActive': true, 'imageUrl': null, 'reportsToUserId': null},
    {'userId': 2, 'firstName': 'Purvesh', 'middleName': '', 'lastName': 'Bagal', 'email': 'p@example.com', 'phoneNo': '1', 'username': 'purvesh', 'roleId': 5, 'roleName': 'Technical', 'isActive': true, 'imageUrl': null, 'reportsToUserId': 1},
  ];

  static String _day(int offset) => DateTime.now().add(Duration(days: offset)).toIso8601String().substring(0, 10);

  static List<Map<String, dynamic>> tasks() => [
        for (final t in [
          (1, 'Coordinate perimeter sweep', 'High', 'inprogress', 3, 1, 4),
          (2, 'Order camera mounts', 'Medium', 'todo', 10, 0, 0),
          (3, 'Vehicle spec review', 'Critical', 'review', -2, 3, 3),
          (4, 'Update firmware checklist', 'Low', 'done', -12, 0, 0),
          (5, 'Survey checkpoint site', 'Medium', 'onhold', 20, 0, 0),
        ])
          {
            'taskId': t.$1,
            'taskCode': 'TSK-00${t.$1}',
            'title': t.$2,
            'description': 'Sample description for ${t.$2}.',
            'projectId': 1,
            'projectName': 'Perimeter Surveillance',
            'priority': t.$3,
            'status': t.$4,
            'startDate': _day(-5),
            'dueDate': _day(t.$5),
            'createdBy': 2,
            'createdByName': 'Purvesh Bagal',
            'createdAt': null,
            'assignees': [
              {'userId': 1, 'name': 'Rushikesh Ravtale'},
              if (t.$1 % 2 == 0) {'userId': 2, 'name': 'Purvesh Bagal'},
            ],
            'checklistDone': t.$6,
            'checklistTotal': t.$7,
            'commentCount': 2,
            'docCount': 1,
            'canApprove': t.$4 == 'review',
            'inMyTeam': true,
            'canEdit': true,
            'canDelete': true,
          },
      ];

  /// Every module fully permitted, like a superuser.
  static Map<String, dynamic> permissions() {
    const items = {
      'employee': ['information', 'contact', 'emergency-contacts', 'family', 'education', 'work-experience', 'skills', 'medical', 'bank', 'documents'],
      'masterData': ['roles', 'departments', 'designations'],
      'settings': ['general', 'profile', 'users', 'permissions'],
      'taskManagement': ['dashboard', 'my-tasks', 'assigned', 'all-tasks', 'reports'],
      'organization': ['teams', 'org-hierarchy', 'org-chart'],
      'projects': ['projects', 'details'],
      'notifications': ['alerts'],
    };
    return {
      'user': user,
      'permissions': [
        for (final e in items.entries)
          {
            'modulename': e.key,
            'modulenameaccess': 'Y',
            'permissiontype': {'view': true},
            'menuitemaccess': [for (final i in e.value) {'id': i, 'label': i, 'access': 'Y'}],
          },
      ],
    };
  }

  http.Response _ok(Object? data, {int status = 200, Map<String, String> headers = const {}}) =>
      http.Response(jsonEncode({'success': true, 'message': 'ok', 'data': data}), status, headers: {'content-type': 'application/json', ...headers});

  http.Response _fail(int status, String message) => http.Response(jsonEncode({'success': false, 'message': message}), status, headers: {'content-type': 'application/json'});

  Future<http.Response> handle(http.Request req) async {
    final key = '${req.method} ${req.url.path}';
    calls.add(key);
    final body = req.body.isEmpty ? null : jsonDecode(req.body);
    if (body is Map<String, dynamic>) lastBody = body;

    switch (key) {
      case 'POST /api/auth/signin':
        if (body?['password'] != 'secret123') return _fail(401, 'Incorrect password');
        return _ok(user, headers: {'set-cookie': 'session=tok123; Path=/; HttpOnly'});
      case 'POST /api/auth/signout':
        return _ok(null, headers: {'set-cookie': 'session=; Path=/; Max-Age=0'});
      case 'GET /api/auth/permissions':
        return _ok(permissions());
      case 'GET /api/settings/profile':
        return _ok(_users.first);
      case 'GET /api/settings/users':
        return _ok(_users);
      case 'GET /api/employee/information':
        return _ok(_employees);
      case 'GET /api/master-data/departments':
      case 'GET /api/master-data/designations':
      case 'GET /api/projects':
      case 'GET /api/tasks/team':
      case 'GET /api/tasks/users':
      case 'GET /api/tasks/projects':
        return _ok(<dynamic>[]);
      case 'GET /api/master-data/roles':
        return _ok([
          {'roleId': 1, 'name': 'Superuser', 'description': '', 'isActive': true},
        ]);
      case 'GET /api/tasks':
        return _ok(tasks());
      case 'GET /api/notifications':
        return _ok({'items': <dynamic>[], 'unread': 0});
      case 'GET /api/employee/bank':
        return _ok(banks);
      case 'POST /api/employee/bank':
        final row = <String, dynamic>{'bankId': 50 + banks.length, ...?body};
        banks.add(row);
        return _ok(row, status: 201);
    }
    if (req.method == 'DELETE' && req.url.path.startsWith('/api/employee/bank/')) {
      final id = int.parse(req.url.pathSegments.last);
      banks.removeWhere((b) => b['bankId'] == id);
      return _ok(null);
    }
    return _ok(<dynamic>[]);
  }

  /// Installs this server as the app's API client.
  void install() {
    AppApi.liveSocket = false;
    AppApi.configure(ApiClient(httpClient: MockClient(handle), sessionStore: MemorySessionStore()));
  }
}

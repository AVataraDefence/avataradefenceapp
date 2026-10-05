import 'package:flutter/material.dart';

import '../components/layout/module_grid.dart';
import '../components/layout/sidebar_menu.dart';
import 'auth/forgot_password/page.dart';
import 'splash/page.dart';
import 'auth/signin/page.dart';
import 'auth/signup/page.dart';
import 'module/employee/bank/page.dart';
import 'module/employee/contact/page.dart';
import 'module/employee/documents/page.dart';
import 'module/employee/education/page.dart';
import 'module/employee/emergency_contacts/page.dart';
import 'module/employee/family/page.dart';
import 'module/employee/information/page.dart';
import 'module/employee/medical/page.dart';
import 'module/employee/skills/page.dart';
import 'module/employee/work_experience/page.dart';
import 'module/master_data/departments/page.dart';
import 'module/master_data/designations/page.dart';
import 'module/master_data/roles/page.dart';
import 'module/organization/teams/page.dart';
import 'module/calendar/page.dart';
import 'module/notifications/page.dart';
import 'module/organization/org_chart/page.dart';
import 'module/organization/org_hierarchy/page.dart';
import 'module/page.dart';
import 'module/projects/details/page.dart';
import 'module/projects/project/page.dart';
import 'module/settings/page.dart';
import 'module/settings/permissions/page.dart';
import 'module/settings/profile/page.dart';
import 'module/task_management/all/page.dart';
import 'module/task_management/assigned/page.dart';
import 'module/task_management/dashboard/page.dart';
import 'module/task_management/my_tasks/page.dart';
import 'module/task_management/reports/page.dart';
import 'module/settings/users/page.dart';

/// Every screen, by the same URL path the web app serves it from. A page lives at
/// `lib/app/<path>/page.dart`, mirroring `src/app/<path>/page.tsx`.
final Map<String, WidgetBuilder> appRoutes = {
  '/auth/signin': (_) => const SignInPage(),
  '/auth/signup': (_) => const SignUpPage(),
  '/auth/forgot-password': (_) => const ForgotPasswordPage(),
  '/module': (_) => const ModulePage(),
  // Employee
  '/module/employee': (_) => const ModuleLandingPage(title: 'Employee', menu: employeeMenu),
  '/module/employee/information': (_) => const EmployeeInformationPage(),
  '/module/employee/contact': (_) => const EmployeeContactPage(),
  '/module/employee/emergency-contacts': (_) => const EmployeeEmergencyContactsPage(),
  '/module/employee/family': (_) => const EmployeeFamilyPage(),
  '/module/employee/education': (_) => const EmployeeEducationPage(),
  '/module/employee/work-experience': (_) => const EmployeeWorkExperiencePage(),
  '/module/employee/skills': (_) => const EmployeeSkillsPage(),
  '/module/employee/medical': (_) => const EmployeeMedicalPage(),
  '/module/employee/bank': (_) => const EmployeeBankPage(),
  '/module/employee/documents': (_) => const EmployeeDocumentsPage(),
  // Master data
  '/module/master-data': (_) => const ModuleLandingPage(title: 'Master Data', menu: masterDataMenu),
  '/module/master-data/roles': (_) => const RolesPage(),
  '/module/master-data/departments': (_) => const DepartmentsPage(),
  '/module/master-data/designations': (_) => const DesignationsPage(),
  // Organization
  '/module/organization': (_) => const ModuleLandingPage(title: 'Organization', menu: organizationMenu),
  '/module/organization/teams': (_) => const TeamsPage(),
  '/module/organization/org-hierarchy': (_) => const OrgHierarchyPage(),
  '/module/organization/org-chart': (_) => const OrgChartPage(),
  // Settings
  '/module/settings': (_) => const SettingsPage(),
  '/module/settings/profile': (_) => const ProfilePage(),
  '/module/settings/users': (_) => const UsersPage(),
  '/module/settings/permissions': (_) => const PermissionsPage(),
  // Task management
  '/module/task-management': (_) => const ModuleLandingPage(title: 'Task Management', menu: taskMenu),
  '/module/task-management/dashboard': (_) => const TaskDashboardPage(),
  '/module/task-management/my-tasks': (_) => const MyTasksPage(),
  '/module/task-management/assigned': (_) => const AssignedTasksPage(),
  '/module/task-management/all': (_) => const AllTasksPage(),
  '/module/task-management/reports': (_) => const TaskReportsPage(),
  // Projects
  '/module/projects': (_) => const ModuleLandingPage(title: 'Projects', menu: projectsMenu),
  '/module/projects/project': (_) => const ProjectPage(),
  '/module/projects/details': (_) => const ProjectDetailsPage(),
  // Calendar & notifications
  '/module/calendar': (_) => const CalendarPage(),
  '/module/notifications': (_) => const NotificationsPage(),
};

Route<dynamic>? onGenerateAppRoute(RouteSettings settings) {
  var name = settings.name ?? '/';
  if (name == '/') return PageRouteBuilder<void>(settings: const RouteSettings(name: '/'), pageBuilder: (_, _, _) => const SplashPage(), transitionDuration: Duration.zero);
  final builder = appRoutes[name];
  if (builder == null) return null;
  final routeSettings = RouteSettings(name: name, arguments: settings.arguments);
  if (name == '/auth/signin') {
    final args = settings.arguments;
    final registered = args is Map && args['registered'] == true;
    return MaterialPageRoute<void>(settings: routeSettings, builder: (_) => SignInPage(justRegistered: registered));
  }
  return MaterialPageRoute<void>(settings: routeSettings, builder: builder);
}

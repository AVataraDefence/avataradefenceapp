import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One entry of a module's side menu (web `SidebarItem`).
class SidebarItem {
  const SidebarItem({required this.id, required this.label, required this.icon, this.href, this.color = const Color(0xFF475569), this.disabled = false});

  final String id;
  final String label;
  final IconData icon;
  final String? href;

  /// Tile colour on the module landing grids.
  final Color color;
  final bool disabled;
}

class SidebarGroup {
  const SidebarGroup({this.group, required this.items});

  final String? group;
  final List<SidebarItem> items;
}

// ── Menus (web `src/app/module/menu-data.json` + each module's menu.ts) ───────────
const employeeMenu = <SidebarGroup>[
  SidebarGroup(group: 'Personal', items: [
    SidebarItem(id: 'information', label: 'Employee Information', icon: LucideIcons.user, href: '/module/employee/information', color: Color(0xFF7C3AED)),
    SidebarItem(id: 'contact', label: 'Contact Details', icon: LucideIcons.phone, href: '/module/employee/contact', color: Color(0xFF0EA5E9)),
    SidebarItem(id: 'emergency-contacts', label: 'Emergency Contacts', icon: LucideIcons.phoneCall, href: '/module/employee/emergency-contacts', color: Color(0xFFE11D48)),
    SidebarItem(id: 'family', label: 'Family Details', icon: LucideIcons.users, href: '/module/employee/family', color: Color(0xFF10B981)),
  ]),
  SidebarGroup(group: 'Professional', items: [
    SidebarItem(id: 'education', label: 'Education', icon: LucideIcons.graduationCap, href: '/module/employee/education', color: Color(0xFF4F46E5)),
    SidebarItem(id: 'work-experience', label: 'Work Experience', icon: LucideIcons.briefcase, href: '/module/employee/work-experience', color: Color(0xFFF97316)),
    SidebarItem(id: 'skills', label: 'Skills & Certifications', icon: LucideIcons.award, href: '/module/employee/skills', color: Color(0xFF0D9488)),
  ]),
  SidebarGroup(group: 'Records', items: [
    SidebarItem(id: 'medical', label: 'Medical Records', icon: LucideIcons.heartPulse, href: '/module/employee/medical', color: Color(0xFFEC4899)),
    SidebarItem(id: 'bank', label: 'Bank Details', icon: LucideIcons.creditCard, href: '/module/employee/bank', color: Color(0xFF059669)),
    SidebarItem(id: 'documents', label: 'Documents', icon: LucideIcons.fileText, href: '/module/employee/documents', color: Color(0xFF475569)),
  ]),
];

const masterDataMenu = <SidebarGroup>[
  SidebarGroup(group: 'Organisation', items: [
    SidebarItem(id: 'roles', label: 'Roles', icon: LucideIcons.userCheck, href: '/module/master-data/roles', color: Color(0xFF7C3AED)),
    SidebarItem(id: 'departments', label: 'Departments', icon: LucideIcons.building2, href: '/module/master-data/departments', color: Color(0xFF4F46E5)),
    SidebarItem(id: 'designations', label: 'Designations', icon: LucideIcons.briefcase, href: '/module/master-data/designations', color: Color(0xFF0EA5E9)),
  ]),
];

const settingsMenu = <SidebarGroup>[
  SidebarGroup(group: 'Account', items: [
    SidebarItem(id: 'general', label: 'General', icon: LucideIcons.settings, href: '/module/settings'),
    SidebarItem(id: 'profile', label: 'Profile', icon: LucideIcons.user, href: '/module/settings/profile'),
  ]),
  SidebarGroup(group: 'System', items: [
    SidebarItem(id: 'users', label: 'Users', icon: LucideIcons.users, href: '/module/settings/users'),
    SidebarItem(id: 'permissions', label: 'Permissions', icon: LucideIcons.keyRound, href: '/module/settings/permissions'),
  ]),
];

const taskMenu = <SidebarGroup>[
  SidebarGroup(group: 'Overview', items: [
    SidebarItem(id: 'dashboard', label: 'Dashboard', icon: LucideIcons.layoutDashboard, href: '/module/task-management/dashboard', color: Color(0xFF374151)),
  ]),
  SidebarGroup(group: 'Tasks', items: [
    SidebarItem(id: 'my-tasks', label: 'My Tasks', icon: LucideIcons.squareCheck, href: '/module/task-management/my-tasks', color: Color(0xFF7C3AED)),
    SidebarItem(id: 'assigned', label: 'Assigned Tasks', icon: LucideIcons.userCheck, href: '/module/task-management/assigned', color: Color(0xFF0EA5E9)),
    SidebarItem(id: 'all-tasks', label: 'All Tasks', icon: LucideIcons.clipboardList, href: '/module/task-management/all', color: Color(0xFF4F46E5)),
  ]),
  SidebarGroup(group: 'Reports', items: [
    SidebarItem(id: 'reports', label: 'Task Reports', icon: LucideIcons.chartColumn, href: '/module/task-management/reports', color: Color(0xFFD97706)),
  ]),
];

const projectsMenu = <SidebarGroup>[
  SidebarGroup(group: 'Projects', items: [
    SidebarItem(id: 'projects', label: 'Project', icon: LucideIcons.squareKanban, href: '/module/projects/project', color: Color(0xFF1D4ED8)),
    SidebarItem(id: 'details', label: 'Project Details', icon: LucideIcons.fileText, href: '/module/projects/details', color: Color(0xFF0F766E)),
  ]),
];

const organizationMenu = <SidebarGroup>[
  SidebarGroup(group: 'Organization', items: [
    SidebarItem(id: 'teams', label: 'Teams', icon: LucideIcons.users, href: '/module/organization/teams', color: Color(0xFF7C3AED)),
    SidebarItem(id: 'org-hierarchy', label: 'Org Hierarchy', icon: LucideIcons.workflow, href: '/module/organization/org-hierarchy', color: Color(0xFF0EA5E9)),
    SidebarItem(id: 'org-chart', label: 'Org Chart', icon: LucideIcons.network, href: '/module/organization/org-chart', color: Color(0xFF0891B2)),
  ]),
];

/// Permission key of a module's menu (web `MODULE_KEY_BY_PATH`).
String? moduleKeyForMenu(List<SidebarGroup> menu) {
  if (identical(menu, employeeMenu)) return 'employee';
  if (identical(menu, masterDataMenu)) return 'masterData';
  if (identical(menu, settingsMenu)) return 'settings';
  if (identical(menu, taskMenu)) return 'taskManagement';
  if (identical(menu, projectsMenu)) return 'projects';
  if (identical(menu, organizationMenu)) return 'organization';
  return null;
}

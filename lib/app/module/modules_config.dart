import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Single source of truth for the module grid (web `src/app/module/modules-config.ts`).
class ModuleConfig {
  const ModuleConfig({required this.id, required this.label, required this.icon, required this.color, this.href, this.enabled = false});

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String? href;
  final bool enabled;
}

const modulesConfig = <ModuleConfig>[
  ModuleConfig(id: 'dashboard', label: 'Dashboard', icon: LucideIcons.layoutDashboard, color: Color(0xFF4F46E5)),
  ModuleConfig(id: 'attendance', label: 'Attendance', icon: LucideIcons.clock, color: Color(0xFF10B981)),
  ModuleConfig(id: 'taskManagement', label: 'Task', icon: LucideIcons.squareCheck, color: Color(0xFF7C3AED), href: '/module/task-management', enabled: true),
  ModuleConfig(id: 'tracking', label: 'Tracking', icon: LucideIcons.mapPin, color: Color(0xFF0EA5E9)),
  ModuleConfig(id: 'purchase', label: 'Purchase', icon: LucideIcons.shoppingCart, color: Color(0xFFF97316)),
  ModuleConfig(id: 'vendor', label: 'Vendor', icon: LucideIcons.handshake, color: Color(0xFF0D9488)),
  ModuleConfig(id: 'travelling', label: 'Travelling', icon: LucideIcons.plane, color: Color(0xFF06B6D4)),
  ModuleConfig(id: 'mom', label: 'MOM', icon: LucideIcons.clipboardList, color: Color(0xFF8B5CF6)),
  ModuleConfig(id: 'inventory', label: 'Inventory', icon: LucideIcons.package, color: Color(0xFFC026D3)),
  ModuleConfig(id: 'reports', label: 'Reports', icon: LucideIcons.chartColumn, color: Color(0xFFD97706)),
  ModuleConfig(id: 'documents', label: 'Documents', icon: LucideIcons.fileText, color: Color(0xFF0F766E)),
  ModuleConfig(id: 'projects', label: 'Projects', icon: LucideIcons.squareKanban, color: Color(0xFF1D4ED8), href: '/module/projects', enabled: true),
  ModuleConfig(id: 'calendar', label: 'Calendar', icon: LucideIcons.calendarDays, color: Color(0xFFF43F5E), href: '/module/calendar'),
  ModuleConfig(id: 'communications', label: 'Communications', icon: LucideIcons.messageSquare, color: Color(0xFFDC2626)),
  ModuleConfig(id: 'notifications', label: 'Notifications', icon: LucideIcons.bell, color: Color(0xFFF59E0B), href: '/module/notifications', enabled: true),
  ModuleConfig(id: 'equipment', label: 'Equipment', icon: LucideIcons.wrench, color: Color(0xFF15803D)),
  ModuleConfig(id: 'leave', label: 'Leave', icon: LucideIcons.clipboardCheck, color: Color(0xFFEA580C)),
  ModuleConfig(id: 'employee', label: 'Employee', icon: LucideIcons.users, color: Color(0xFFE11D48), href: '/module/employee', enabled: true),
  ModuleConfig(id: 'organization', label: 'Organization', icon: LucideIcons.building2, color: Color(0xFF0891B2), href: '/module/organization', enabled: true),
  ModuleConfig(id: 'masterData', label: 'Master Data', icon: LucideIcons.database, color: Color(0xFF0369A1), href: '/module/master-data', enabled: true),
  ModuleConfig(id: 'settings', label: 'Settings', icon: LucideIcons.settings, color: Color(0xFF475569), href: '/module/settings', enabled: true),
];

final activeModulesConfig = modulesConfig.where((m) => m.enabled).toList();

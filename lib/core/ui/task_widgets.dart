import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_avatar.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_display.dart';
import 'app_input.dart';
import 'app_misc.dart';

// ── Task workflow vocabulary (same names / colours as the web Task Management) ──
enum TaskStatus {
  todo('To Do', TwColors.slate700),
  inProgress('In Progress', TwColors.indigo700),
  onHold('On Hold', TwColors.rose700),
  review('Review', TwColors.amber700),
  done('Done', TwColors.green700),
  cancelled('Cancelled', TwColors.red700);

  const TaskStatus(this.label, this.color);
  final String label;
  final Color color;

  bool get isClosed => this == done || this == cancelled;
}

enum TaskPriority {
  low('Low', TwColors.slate400, TwColors.slate500, TwColors.slate100),
  medium('Medium', TwColors.amber400, TwColors.amber700, TwColors.amber50),
  high('High', TwColors.orange700, TwColors.orange700, TwColors.orange50),
  critical('Critical', TwColors.red700, TwColors.red700, TwColors.red50);

  const TaskPriority(this.label, this.dot, this.text, this.background);
  final String label;
  final Color dot;
  final Color text;
  final Color background;
}

enum ProjectStatus {
  planning('Planning', TwColors.slate500),
  active('Active', TwColors.blue700),
  onHold('On Hold', TwColors.amber700),
  completed('Completed', TwColors.green700),
  cancelled('Cancelled', TwColors.red700);

  const ProjectStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// Solid status pill (white text on the status colour) — the column headers / detail badges.
class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) => AppBadge.tinted(status.label, color: Colors.white, background: status.color);
}

/// "• HIGH" pill: coloured dot + label on a tinted background.
class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge(this.priority, {super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.isDark;
    return AppBadge.tinted(
      priority.label,
      color: dark ? Color.lerp(priority.text, Colors.white, 0.35)! : priority.text,
      background: dark ? priority.dot.withValues(alpha: 0.22) : priority.background,
      dotColor: priority.dot,
    );
  }
}

class ProjectStatusBadge extends StatelessWidget {
  const ProjectStatusBadge(this.status, {super.key});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) => AppBadge.tinted(status.label, color: status.color);
}

/// Everything a board card needs; no business logic.
class TaskCardData {
  const TaskCardData({
    required this.code,
    required this.title,
    required this.priority,
    required this.status,
    this.description,
    this.projectName,
    this.assignees = const [],
    this.dueDate,
    this.progress = 0,
  });

  final String code;
  final String title;
  final String? description;
  final String? projectName;
  final TaskPriority priority;
  final TaskStatus status;
  final List<({String name, int? id})> assignees;
  final DateTime? dueDate;

  /// 0–100.
  final double progress;

  bool get overdue =>
      dueDate != null && !status.isClosed && status != TaskStatus.review && dueDate!.isBefore(DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
}

/// Kanban / list card for a task (web My Tasks & Assigned Tasks card).
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap, this.onApprove, this.onReject, this.showStatus = false});

  final TaskCardData task;
  final VoidCallback? onTap;

  /// Shows the status pill (lists that mix statuses; the Kanban columns already say it).
  final bool showStatus;

  /// When both are given, the Approve / Reject strip shows (tasks in Review that
  /// the signed-in user may approve).
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final overdue = task.overdue;
    final first = task.assignees.isEmpty ? null : task.assignees.first.name.split(' ').first;

    return Material(
      color: c.background,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rLg, side: BorderSide(color: c.border.withValues(alpha: 0.7))),
      elevation: 0,
      shadowColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TaskPriorityBadge(task.priority),
                  const Spacer(),
                  if (task.assignees.isNotEmpty) ...[
                    AppAvatarStack(people: [for (final a in task.assignees) (name: a.name, id: a.id, imageUrl: null)], size: AppAvatarSize.xs),
                    const SizedBox(width: 6),
                    Text(task.assignees.length > 1 ? '$first +${task.assignees.length - 1}' : first!, style: t.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              AppMono(task.code, size: 10),
              const SizedBox(height: 2),
              Text(task.title, style: t.titleSmall?.copyWith(fontSize: 14)),
              if (task.description != null && task.description!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall)),
              if (task.projectName != null)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text(task.projectName!, style: t.bodySmall?.copyWith(fontSize: 11))),
              const SizedBox(height: 8),
              AppProgress(value: task.progress, showLabel: true, color: TwColors.indigo500, completeColor: TwColors.green500),
              if (task.dueDate != null || showStatus) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(LucideIcons.calendar, size: 13, color: overdue ? c.destructive : c.mutedForeground),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${overdue ? 'Overdue · ' : ''}${formatAppDate(task.dueDate!)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: overdue ? c.destructive : c.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showStatus) TaskStatusBadge(task.status),
                  ],
                ),
              ],
              if (onApprove != null && onReject != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.6)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(label: 'Approve', icon: LucideIcons.check, size: AppButtonSize.sm, variant: AppButtonVariant.secondary, onPressed: onApprove),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(label: 'Reject', icon: LucideIcons.rotateCcw, size: AppButtonSize.sm, variant: AppButtonVariant.destructive, onPressed: onReject),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/core.dart';

/// Living style guide: every theme token and component, in the current theme.
/// Open it from the app (and flip light / dark in the header) to compare with the web.
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  int _tab = 0;
  int _pillTab = 0;
  int _page = 3;
  int _navIndex = 0;
  bool _check = true;
  bool _switch = true;
  String _radio = 'a';
  String? _select = 'high';
  List<int> _people = [1];
  DateTime? _date = DateTime(2026, 10, 15);
  bool _loading = false;

  static const _priorities = [
    AppOption(value: 'low', label: 'Low'),
    AppOption(value: 'medium', label: 'Medium'),
    AppOption(value: 'high', label: 'High'),
    AppOption(value: 'critical', label: 'Critical'),
  ];

  static const _team = ['Rushikesh Ravtale', 'Purvesh Bagal', 'Rushi Raj', 'Sneha Nair', 'Vikram Patil', 'Arjun Mehta', 'Priya Sharma', 'Karan Joshi'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppHeader(
        title: 'Component gallery',
        onNotifications: () => AppToast.show(context, 'Notifications', description: 'Opens the notification list'),
        unread: 3,
        userName: 'Rushikesh Ravtale',
        userId: 1,
        actions: [
          AppIconButton(
            icon: c.isDark ? LucideIcons.sun : LucideIcons.moon,
            tooltip: 'Toggle theme',
            onPressed: () => ThemeScope.of(context).toggle(context),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _navIndex,
        onChanged: (i) => setState(() => _navIndex = i),
        items: const [
          AppNavItem(icon: LucideIcons.layoutGrid, label: 'Modules'),
          AppNavItem(icon: LucideIcons.squareCheck, label: 'Tasks'),
          AppNavItem(icon: LucideIcons.bell, label: 'Alerts'),
          AppNavItem(icon: LucideIcons.user, label: 'Profile'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Colors', 'Same tokens as globals.css (${c.isDark ? '.dark' : ':root'})', _colors(c)),
          _Section('Typography', 'Poppins · Tailwind scale', _typography(context)),
          _Section('Buttons', 'default · outline · secondary · ghost · destructive · link', _buttons()),
          _Section('Badges', 'variants + task / project chips', _badges()),
          _Section('Inputs', 'Input · Textarea · Password · Search · Select · Date', _inputs()),
          _Section('Selection', 'Checkbox · Switch · Radio', _selection()),
          _Section('Cards', 'Card + task card', _cards(context)),
          _Section('Avatars', 'initials, stacks', _avatars()),
          _Section('Feedback', 'Progress · Skeleton · Alert · Empty', _feedback()),
          _Section('Overlays', 'Toast · Dialog · Sheet · Action sheet', _overlays(context)),
          _Section('Navigation', 'Tabs · Pagination · Accordion · Menu · Module tiles', _navigation()),
          _Section('Table', 'bordered, scrolls sideways on a phone', _table()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── sections ────────────────────────────────────────────────────────────────
  Widget _colors(AppColors c) {
    final swatches = <(String, Color)>[
      ('background', c.background),
      ('foreground', c.foreground),
      ('card', c.card),
      ('primary', c.primary),
      ('primary-fg', c.primaryForeground),
      ('secondary', c.secondary),
      ('muted', c.muted),
      ('muted-fg', c.mutedForeground),
      ('accent', c.accent),
      ('destructive', c.destructive),
      ('border', c.border),
      ('input', c.input),
      ('ring', c.ring),
      ('chart-1', c.chart1),
      ('chart-2', c.chart2),
      ('chart-3', c.chart3),
      ('chart-4', c.chart4),
      ('chart-5', c.chart5),
      ('sidebar', c.sidebar),
      ('sidebar-primary', c.sidebarPrimary),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final s in swatches)
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(color: s.$2, borderRadius: AppRadius.rMd, border: Border.all(color: c.border)),
                ),
                const SizedBox(height: 4),
                Text(s.$1, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _typography(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Page title · text-xl bold', style: t.headlineMedium),
        const SizedBox(height: 6),
        Text('Card title · text-base medium', style: t.titleMedium),
        const SizedBox(height: 6),
        Text('Section title · text-sm semibold', style: t.titleSmall),
        const SizedBox(height: 6),
        Text('Body text · text-sm regular. The quick brown fox jumps over the lazy dog.', style: t.bodyMedium),
        const SizedBox(height: 6),
        Text('Muted caption · text-xs muted-foreground', style: t.bodySmall),
        const SizedBox(height: 6),
        Text('OVERLINE LABEL', style: t.labelSmall),
        const SizedBox(height: 6),
        const AppMono('TSK-017  ·  font-mono'),
      ],
    );
  }

  Widget _buttons() {
    Widget row(AppButtonSize s) => Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(label: 'Default', size: s, onPressed: () {}),
            AppButton(label: 'Outline', size: s, variant: AppButtonVariant.outline, onPressed: () {}),
            AppButton(label: 'Secondary', size: s, variant: AppButtonVariant.secondary, onPressed: () {}),
            AppButton(label: 'Ghost', size: s, variant: AppButtonVariant.ghost, onPressed: () {}),
            AppButton(label: 'Delete', size: s, variant: AppButtonVariant.destructive, onPressed: () {}),
            AppButton(label: 'Link', size: s, variant: AppButtonVariant.link, onPressed: () {}),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(AppButtonSize.md),
        const SizedBox(height: 12),
        row(AppButtonSize.sm),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(label: 'Extra small', size: AppButtonSize.xs, onPressed: () {}),
            AppButton(label: 'Large', size: AppButtonSize.lg, onPressed: () {}),
            AppButton(label: 'With icon', icon: LucideIcons.plus, onPressed: () {}),
            AppButton(label: 'Next', trailingIcon: LucideIcons.chevronRight, variant: AppButtonVariant.outline, onPressed: () {}),
            AppButton(label: _loading ? 'Saving…' : 'Save', loading: _loading, onPressed: () async {
              setState(() => _loading = true);
              await Future<void>.delayed(const Duration(seconds: 1));
              if (mounted) setState(() => _loading = false);
            }),
            const AppButton(label: 'Disabled', onPressed: null),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            AppIconButton(icon: LucideIcons.pencil, onPressed: () {}, tooltip: 'Edit'),
            AppIconButton(icon: LucideIcons.trash2, variant: AppButtonVariant.destructive, onPressed: () {}),
            AppIconButton(icon: LucideIcons.plus, variant: AppButtonVariant.primary, onPressed: () {}),
            AppIconButton(icon: LucideIcons.bell, variant: AppButtonVariant.outline, onPressed: () {}, badge: 7),
          ],
        ),
        const SizedBox(height: 12),
        AppButton(label: 'Full width button', expand: true, onPressed: () {}),
      ],
    );
  }

  Widget _badges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(spacing: 8, runSpacing: 8, children: [
          AppBadge('Default'),
          AppBadge('Secondary', variant: AppBadgeVariant.secondary),
          AppBadge('Destructive', variant: AppBadgeVariant.destructive),
          AppBadge('Outline', variant: AppBadgeVariant.outline),
          AppBadge('Ghost', variant: AppBadgeVariant.ghost),
          AppBadge('Link', variant: AppBadgeVariant.link),
          AppBadge('With icon', icon: LucideIcons.check),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in TaskStatus.values) TaskStatusBadge(s)]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final p in TaskPriority.values) TaskPriorityBadge(p)]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in ProjectStatus.values) ProjectStatusBadge(s)]),
      ],
    );
  }

  Widget _inputs() {
    return Column(
      children: [
        const AppInput(label: 'Task title', hint: 'e.g. Coordinate perimeter sweep', required: true),
        const SizedBox(height: 14),
        const AppInput(label: 'With helper', hint: 'Project name', helper: 'Shown on every report'),
        const SizedBox(height: 14),
        const AppInput(label: 'With error', hint: 'Client', error: 'Client is required'),
        const SizedBox(height: 14),
        const AppInput(label: 'Disabled', hint: 'Not editable', enabled: false),
        const SizedBox(height: 14),
        const AppPasswordInput(label: 'Password', hint: '••••••••'),
        const SizedBox(height: 14),
        const AppSearchField(hint: 'Search tasks…'),
        const SizedBox(height: 14),
        const AppInput.multiline(label: 'Description', hint: 'Describe the task in detail…'),
        const SizedBox(height: 14),
        AppSelect<String>(label: 'Priority', options: _priorities, value: _select, onChanged: (v) => setState(() => _select = v)),
        const SizedBox(height: 14),
        AppMultiSelect<int>(
          label: 'Assign to',
          hint: 'Select assignees…',
          options: [
            for (var i = 0; i < _team.length; i++)
              AppOption(value: i, label: _team[i], subtitle: 'EMP-${(i + 2).toString().padLeft(3, '0')}', leading: AppAvatar(name: _team[i], colorSeed: i, size: AppAvatarSize.xs)),
          ],
          values: _people,
          onChanged: (v) => setState(() => _people = v),
        ),
        const SizedBox(height: 14),
        AppDateField(label: 'Due date', value: _date, onChanged: (d) => setState(() => _date = d)),
      ],
    );
  }

  Widget _selection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCheckbox(value: _check, onChanged: (v) => setState(() => _check = v), label: 'Send me notifications', description: 'New tasks, comments and approvals'),
        const AppCheckbox(value: false, onChanged: null, label: 'Disabled option'),
        const SizedBox(height: 8),
        AppSwitch(value: _switch, onChanged: (v) => setState(() => _switch = v), label: 'Notification sound', description: 'Play a sound for new notifications'),
        const SizedBox(height: 8),
        AppRadioGroup<String>(
          value: _radio,
          onChanged: (v) => setState(() => _radio = v),
          options: const [
            AppOption(value: 'a', label: 'My tasks'),
            AppOption(value: 'b', label: 'Assigned tasks'),
            AppOption(value: 'c', label: 'All tasks', subtitle: 'Needs View All'),
          ],
        ),
      ],
    );
  }

  Widget _cards(BuildContext context) {
    return Column(
      children: [
        AppCard(
          title: 'Task Details',
          description: 'Fill in the details and assign to a team member.',
          action: AppIconButton(icon: LucideIcons.ellipsisVertical, onPressed: () {}, size: AppButtonSize.sm),
          headerDivider: true,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(label: 'Cancel', variant: AppButtonVariant.outline, size: AppButtonSize.sm, onPressed: () {}),
              const SizedBox(width: 8),
              AppButton(label: 'Save', size: AppButtonSize.sm, onPressed: () {}),
            ],
          ),
          child: Text('Cards use a hairline ring instead of a shadow, like the web.', style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 12),
        TaskCard(
          task: TaskCardData(
            code: 'TSK-017',
            title: 'go to mumbai',
            description: 'Site visit and report',
            projectName: 'IMS',
            priority: TaskPriority.high,
            status: TaskStatus.inProgress,
            assignees: const [(name: 'Purvesh Bagal', id: 2), (name: 'Rushi Raj', id: 23)],
            dueDate: DateTime(2026, 10, 11),
            progress: 30,
          ),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        TaskCard(
          task: TaskCardData(
            code: 'TSK-018',
            title: 'Daily Pune Visit',
            projectName: 'IMS',
            priority: TaskPriority.medium,
            status: TaskStatus.review,
            assignees: const [(name: 'Rushi Raj', id: 23)],
            dueDate: DateTime(2026, 9, 20),
            progress: 80,
          ),
          onApprove: () => AppToast.success(context, 'Task approved'),
          onReject: () => AppToast.error(context, 'Task sent back'),
        ),
      ],
    );
  }

  Widget _avatars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final (i, s) in AppAvatarSize.values.indexed) AppAvatar(name: _team[i], colorSeed: i, size: s),
        ]),
        const SizedBox(height: 12),
        AppAvatarStack(people: [for (var i = 0; i < 6; i++) (name: _team[i], id: i, imageUrl: null)], max: 4, size: AppAvatarSize.md),
      ],
    );
  }

  Widget _feedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppProgress(value: 30, showLabel: true),
        const SizedBox(height: 10),
        const AppProgress(value: 80, showLabel: true),
        const SizedBox(height: 10),
        const AppProgress(value: 100, showLabel: true, completeColor: TwColors.green500),
        const SizedBox(height: 16),
        const AppSkeletonCard(),
        const SizedBox(height: 16),
        const Row(children: [AppSpinner(size: 18), SizedBox(width: 10), Text('Loading…')]),
        const SizedBox(height: 16),
        const AppAlert(title: 'Heads up', description: 'This is an informational message.'),
        const SizedBox(height: 8),
        const AppAlert(title: 'Saved', description: 'Your changes were saved.', variant: AppAlertVariant.success),
        const SizedBox(height: 8),
        const AppAlert(title: 'Careful', description: 'This task is overdue.', variant: AppAlertVariant.warning),
        const SizedBox(height: 8),
        const AppAlert(title: 'Failed', description: 'Something went wrong.', variant: AppAlertVariant.destructive),
        const SizedBox(height: 8),
        const AppCard(padding: EdgeInsets.zero, child: AppEmpty(title: 'No notifications yet', description: 'New activity will show up here.', icon: LucideIcons.bell)),
      ],
    );
  }

  Widget _overlays(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppButton(label: 'Toast', variant: AppButtonVariant.outline, onPressed: () => AppToast.show(context, 'Task created', description: 'TSK-019 was assigned')),
        AppButton(label: 'Success', variant: AppButtonVariant.outline, onPressed: () => AppToast.success(context, 'Saved')),
        AppButton(label: 'Error', variant: AppButtonVariant.outline, onPressed: () => AppToast.error(context, 'Could not save', description: 'Check your connection')),
        AppButton(
          label: 'Confirm dialog',
          variant: AppButtonVariant.outline,
          onPressed: () async {
            final ok = await showAppConfirm(context, title: 'Delete task?', description: 'TSK-017 "go to mumbai" will be removed. This cannot be undone.', confirmLabel: 'Delete', destructive: true);
            if (context.mounted && ok) AppToast.success(context, 'Task deleted');
          },
        ),
        AppButton(
          label: 'Dialog',
          variant: AppButtonVariant.outline,
          onPressed: () => showAppDialog<void>(
            context,
            builder: (ctx) => AppDialog(
              title: 'Reject & send back',
              description: "Rushi's task will move back to In Progress.",
              onClose: () => Navigator.pop(ctx),
              actions: [
                AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(ctx)),
                AppButton(label: 'Reject', variant: AppButtonVariant.destructive, onPressed: () => Navigator.pop(ctx)),
              ],
              child: const AppInput.multiline(label: 'Reason (optional)', hint: 'e.g. Missing data on section 3…', minLines: 3),
            ),
          ),
        ),
        AppButton(
          label: 'Bottom sheet',
          variant: AppButtonVariant.outline,
          onPressed: () => showAppSheet<void>(
            context,
            title: 'Filters',
            description: 'Narrow the task list',
            builder: (ctx) => const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [AppInput(label: 'Search', hint: 'Task, project, person…'), SizedBox(height: 12), AppInput(label: 'Project', hint: 'Any')]),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [AppButton(label: 'Apply', onPressed: () {})],
            ),
          ),
        ),
        AppButton(
          label: 'Action sheet',
          variant: AppButtonVariant.outline,
          onPressed: () => showAppActionSheet(
            context,
            title: 'TSK-017',
            actions: [
              AppMenuAction(label: 'Edit task', icon: LucideIcons.pencil, onTap: () {}),
              AppMenuAction(label: 'Open comments', icon: LucideIcons.messageSquare, onTap: () {}),
              AppMenuAction(label: 'Delete', icon: LucideIcons.trash2, destructive: true, onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navigation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTabs(
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
          tabs: const [AppTabItem('Summary'), AppTabItem('Task list', count: 12), AppTabItem('Overdue', count: 3)],
        ),
        const SizedBox(height: 16),
        AppTabs(
          variant: AppTabsVariant.pill,
          index: _pillTab,
          onChanged: (i) => setState(() => _pillTab = i),
          tabs: const [AppTabItem('Mine'), AppTabItem('Assigned'), AppTabItem('All')],
        ),
        const SizedBox(height: 16),
        AppPagination(page: _page, totalPages: 9, onChanged: (p) => setState(() => _page = p)),
        const SizedBox(height: 16),
        const AppAccordion(title: 'Description', subtitle: 'Tap to expand', initiallyExpanded: true, child: Text('Accordion content sits here and animates open and closed.')),
        const SizedBox(height: 16),
        const AppSeparator(label: 'OR'),
        const SizedBox(height: 12),
        const AppMenuSection('Tasks'),
        const AppMenuItem(icon: LucideIcons.squareCheck, label: 'My Tasks', selected: true, count: 4),
        const AppMenuItem(icon: LucideIcons.userCheck, label: 'Assigned Tasks'),
        const AppMenuItem(icon: LucideIcons.clipboardList, label: 'All Tasks'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 18,
          runSpacing: 14,
          children: [
            AppModuleTile(icon: LucideIcons.squareCheck, label: 'Task', color: TwColors.violet600, onTap: () {}),
            AppModuleTile(icon: LucideIcons.folderKanban, label: 'Projects', color: TwColors.indigo700, onTap: () {}),
            AppModuleTile(icon: LucideIcons.bell, label: 'Notifications', color: TwColors.amber500, onTap: () {}),
            AppModuleTile(icon: LucideIcons.users, label: 'Employee', color: TwColors.rose700, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _table() {
    return AppTable(
      headers: const ['Task', 'Assignee', 'Status', 'Due'],
      columnWidths: const [150, 150, 130, 120],
      rows: const [
        [Text('go to mumbai'), Text('Purvesh Bagal'), TaskStatusBadge(TaskStatus.inProgress), Text('11 Oct 2026')],
        [Text('Daily Pune Visit'), Text('Rushi Raj'), TaskStatusBadge(TaskStatus.onHold), Text('31 Oct 2026')],
        [Text('Site survey'), Text('Sneha Nair'), TaskStatusBadge(TaskStatus.done), Text('02 Oct 2026')],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.subtitle, this.child);

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.headlineMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: t.bodySmall),
          const SizedBox(height: 4),
          const AppSeparator(),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/layout/main_content.dart';
import '../../../core/core.dart';

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _tabs = ['Month', 'Week', 'Day', 'Events', 'Meetings', 'Holidays'];

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime _startOfWeek(DateTime d) => _addDays(d, -(d.weekday % 7));
String _hour(int h) => h == 0 ? '12 AM' : h == 12 ? '12 PM' : h < 12 ? '$h AM' : '${h - 12} PM';

/// `/module/calendar` (web `calendar/page.tsx`): Month / Week / Day grids plus empty
/// Events, Meetings and Holidays tabs.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _tab = 0;
  DateTime _anchor = DateTime.now();
  DateTime _selected = DateTime.now();

  void _shift(int dir) => setState(() {
        _anchor = switch (_tab) {
          0 => DateTime(_anchor.year, _anchor.month + dir, 1),
          1 => _addDays(_anchor, 7 * dir),
          _ => _addDays(_anchor, dir),
        };
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final showNav = _tab <= 2;
    final label = _tab == 2 ? '${_dayNames[(_anchor.weekday - 1)]}, ${_months[_anchor.month - 1]} ${_anchor.day}, ${_anchor.year}' : '${_months[_anchor.month - 1]} ${_anchor.year}';
    return MainContent(
      title: 'Calendar',
      backHref: '/module',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calendar', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('View schedules, events, meetings and holidays', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
                const SizedBox(height: 12),
                AppTabs(tabs: [for (final x in _tabs) AppTabItem(x)], index: _tab, onChanged: (i) => setState(() => _tab = i)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (showNav)
            Row(
              children: [
                AppIconButton(icon: LucideIcons.chevronLeft, size: AppButtonSize.sm, tooltip: 'Previous', onPressed: () => _shift(-1)),
                AppIconButton(icon: LucideIcons.chevronRight, size: AppButtonSize.sm, tooltip: 'Next', onPressed: () => _shift(1)),
                const SizedBox(width: 6),
                Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                AppButton(label: 'Today', variant: AppButtonVariant.outline, size: AppButtonSize.sm, onPressed: () => setState(() {
                      _anchor = DateTime.now();
                      _selected = DateTime.now();
                    })),
              ],
            ),
          if (showNav) const SizedBox(height: 12),
          switch (_tab) {
            0 => _month(context),
            1 => _timeGrid(context, [for (var i = 0; i < 7; i++) _addDays(_startOfWeek(_anchor), i)]),
            2 => _timeGrid(context, [_anchor]),
            3 => _empty(context, LucideIcons.calendarDays, 'Events'),
            4 => _empty(context, LucideIcons.users, 'Meetings'),
            _ => _empty(context, LucideIcons.sparkles, 'Holidays'),
          },
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, IconData icon, String label) =>
      AppCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: AppEmpty(title: 'No ${label.toLowerCase()} yet', icon: icon)));

  Widget _month(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final first = DateTime(_anchor.year, _anchor.month, 1);
    final start = DateTime(first.year, first.month, 1 - (first.weekday % 7));
    final days = [for (var i = 0; i < 42; i++) _addDays(start, i)];
    final today = DateTime.now();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(child: Container(height: 36, alignment: Alignment.center, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.6)))), child: Text(w.toUpperCase(), style: t.labelSmall?.copyWith(fontSize: 10)))),
            ],
          ),
          for (var r = 0; r < 6; r++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final d = days[r * 7 + col];
                      final inMonth = d.month == _anchor.month;
                      final isToday = _sameDay(d, today);
                      final isSel = _sameDay(d, _selected);
                      return InkWell(
                        onTap: () => setState(() => _selected = d),
                        child: Container(
                          height: 52,
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: isSel ? c.primary.withValues(alpha: 0.05) : null,
                            border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.5)), right: col < 6 ? BorderSide(color: c.border.withValues(alpha: 0.5)) : BorderSide.none),
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: isToday ? c.primary : null, shape: BoxShape.circle),
                            child: Text(
                              '${d.day}',
                              style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: isToday || isSel ? FontWeight.w600 : FontWeight.w400, color: isToday ? c.primaryForeground : isSel ? c.primary : inMonth ? c.foreground : c.mutedForeground.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _timeGrid(BuildContext context, List<DateTime> days) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final today = DateTime.now();
    final now = today.hour + today.minute / 60;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 52),
              for (final d in days)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: c.border.withValues(alpha: 0.5)), bottom: BorderSide(color: c.border.withValues(alpha: 0.5)))),
                    child: Column(
                      children: [
                        Text(_weekdays[d.weekday % 7].toUpperCase(), style: t.labelSmall?.copyWith(fontSize: 10)),
                        const SizedBox(height: 2),
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: _sameDay(d, today) ? c.primary : null, shape: BoxShape.circle),
                          child: Text('${d.day}', style: t.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: _sameDay(d, today) ? c.primaryForeground : c.foreground)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 420,
            child: ListView.builder(
              itemCount: 24,
              itemExtent: 48,
              itemBuilder: (context, h) => Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 52, child: Padding(padding: const EdgeInsets.only(right: 6, top: 2), child: Text(_hour(h), textAlign: TextAlign.right, style: t.bodySmall?.copyWith(fontSize: 10)))),
                      for (var i = 0; i < days.length; i++)
                        Expanded(child: Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: c.border.withValues(alpha: 0.5)), bottom: BorderSide(color: c.border.withValues(alpha: 0.4)))))),
                    ],
                  ),
                  if (days.any((d) => _sameDay(d, today)) && now >= h && now < h + 1)
                    Positioned(left: 52, right: 0, top: (now - h) * 48, child: Container(height: 2, color: TwColors.red500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

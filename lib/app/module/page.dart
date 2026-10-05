import 'package:flutter/material.dart';

import '../../components/layout/main_content.dart';
import '../../components/layout/module_grid.dart';
import '../../core/core.dart';
import '../../data/session.dart';
import 'modules_config.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/// Follows the phone's clock: 5–12 morning, 12–17 afternoon, 17–21 evening, otherwise night.
String _greeting(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 21) return 'Good evening';
  return 'Good night';
}

/// `/module` — the home grid of enabled modules (web `src/app/module/page.tsx`), under a greeting.
class ModulePage extends StatelessWidget {
  const ModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSession.instance,
      builder: (context, _) {
        final now = DateTime.now();
        final name = AppSession.instance.userName.split(' ').first;
        final first = name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
        return MainContent(
          backgroundImage: 'assets/background/Seamless Tech Defense Doodle Wallpaper.png',
          onRefresh: AppSession.instance.reloadAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Greeting(text: '${_greeting(now)}, $first', date: '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}'),
              const SizedBox(height: 20),
              ModuleTileGrid(
                tiles: [for (final m in activeModulesConfig.where((m) => AppSession.instance.canViewModule(m.id))) (icon: m.icon, label: m.label, color: m.color, href: m.href, disabled: false)],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.text, required this.date});

  final String text;
  final String date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    // Plain text on the page background: bold dark greeting, muted date.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: c.foreground)),
          const SizedBox(height: 2),
          Text(date, style: t.bodySmall?.copyWith(color: c.mutedForeground)),
        ],
      ),
    );
  }
}

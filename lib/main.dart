import 'package:flutter/material.dart';

import 'app/nav.dart';
import 'app/routes.dart';
import 'push/push_service.dart';
import 'core/core.dart';
import 'data/app_api.dart';
import 'data/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.init();
  runApp(const AvataraDefenceApp());
}

class AvataraDefenceApp extends StatefulWidget {
  const AvataraDefenceApp({super.key});

  @override
  State<AvataraDefenceApp> createState() => _AvataraDefenceAppState();
}

class _AvataraDefenceAppState extends State<AvataraDefenceApp> {
  final _theme = ThemeController();

  @override
  void initState() {
    super.initState();
    // Tapping a system popup opens its page (or waits for the splash when the app was closed).
    PushService.onOpenUrl = (url) {
      final nav = AppApi.navigatorKey.currentState;
      if (nav != null && AppSession.instance.signedIn) {
        pushNotificationUrl(nav, url);
      } else {
        PushService.pendingUrl = url;
      }
    };
    // A rejected token (expired / signed out elsewhere) sends the user back to sign in.
    AppSession.instance.onExpired = () => AppApi.navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth/signin', (_) => false);
  }

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp(
          title: 'AVD',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _theme.mode,
          // Same entry as the web: `/` sends you to sign in (or the module grid when signed in).
          navigatorKey: AppApi.navigatorKey,
          initialRoute: '/',
          onGenerateRoute: onGenerateAppRoute,
        ),
      ),
    );
  }
}

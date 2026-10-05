import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avataradefence/app/routes.dart';
import 'package:avataradefence/core/core.dart';
import 'package:avataradefence/data/session.dart';

import 'fake_server.dart';
import 'test_fonts.dart';

const _shots = bool.fromEnvironment('SCREENSHOTS');

/// Every route renders on a phone-sized screen against a fake API without exceptions
/// (overflow included); with `--dart-define=SCREENSHOTS=true --update-goldens` it also
/// writes a PNG per screen.
void main() {
  setUpAll(loadAppFonts);

  late FakeServer server;

  setUp(() {
    server = FakeServer()..install();
  });

  Future<void> show(WidgetTester tester, String path, {ThemeMode mode = ThemeMode.light, bool signedIn = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // The session is a singleton: start every screen from a known state.
    await tester.runAsync(() => AppSession.instance.signOut());
    if (signedIn) await tester.runAsync(() => AppSession.instance.signIn('rushi', 'secret123'));
    final controller = ThemeController(mode);
    await tester.pumpWidget(ThemeScope(
      controller: controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        initialRoute: path,
        onGenerateRoute: onGenerateAppRoute,
      ),
    ));
    // Asset images decode outside the fake clock: load them before the screenshot.
    await tester.runAsync(() => precacheImage(const AssetImage('assets/background/Seamless Tech Defense Doodle Wallpaper.png'), tester.element(find.byType(MaterialApp))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  for (final path in appRoutes.keys) {
    testWidgets('renders $path', (tester) async {
      await show(tester, path, signedIn: !path.startsWith('/auth'));
      expect(tester.takeException(), isNull);
      if (_shots) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/${path.substring(1).replaceAll('/', '_')}.png'));
      }
    });
  }

  testWidgets('sign in validates, rejects a wrong password, then opens the module grid', (tester) async {
    await show(tester, '/auth/signin', signedIn: false);
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Email or Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'rushi');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Incorrect password'), findsOneWidget);
    expect(AppSession.instance.signedIn, isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(AppSession.instance.signedIn, isTrue);
    expect(server.calls, contains('GET /api/auth/permissions'));
    expect(find.text('Employee'), findsWidgets);
  });

  testWidgets('employee bank: lists from the API, validates before posting', (tester) async {
    await show(tester, '/module/employee/bank');
    expect(find.text('Rushikesh Ravtale'), findsWidgets);
    expect(find.text('HDFC Bank'), findsOneWidget);

    await tester.tap(find.text('+ Add Record'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('View Table'), findsOneWidget);
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.pump();
    await tester.tap(find.text('Save Changes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Employee is required'), findsOneWidget);
    expect(find.text('Bank name is required'), findsOneWidget);
    expect(server.calls.where((c) => c == 'POST /api/employee/bank'), isEmpty);
  });

  testWidgets('the module grid shows the modules the role may open', (tester) async {
    await show(tester, '/module');
    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Employee'), findsOneWidget);
  });
}

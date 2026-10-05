
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avataradefence/core/core.dart';
import 'package:avataradefence/features/gallery/component_gallery_page.dart';
import 'package:avataradefence/main.dart';

import 'fake_server.dart';
import 'test_fonts.dart';

Widget app(ThemeMode mode) {
  final controller = ThemeController(mode);
  return ThemeScope(
    controller: controller,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const ComponentGalleryPage(),
    ),
  );
}

const screenshots = bool.fromEnvironment('SCREENSHOTS');

void main() {
  setUpAll(loadAppFonts);

  testWidgets('app starts on the splash, then opens sign in', (tester) async {
    FakeServer().install();
    await tester.pumpWidget(const AvataraDefenceApp());
    await tester.pump();
    expect(find.text('AVATARA DEFENCE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Enter your credentials to continue'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('theme tokens match the web: light primary #432DD7, dark card #1D161E', (tester) async {
    late BuildContext light;
    late BuildContext dark;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(builder: (c) {
        light = c;
        return const SizedBox();
      }),
    ));
    expect(light.colors.primary, const Color(0xFF432DD7));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Builder(builder: (c) {
        dark = c;
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle(); // ThemeData changes animate for 200 ms
    expect(dark.colors.card, const Color(0xFF1D161E));
    expect(Theme.of(dark).brightness, Brightness.dark);
  });

  testWidgets('every gallery section builds without errors in light and dark', (tester) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(app(mode));
      await tester.pumpAndSettle();
      // Scroll through the whole list so every section is laid out at least once.
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 40; i++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  // Screenshots are an on-demand visual check, not a regression gate:
  //   flutter test --dart-define=SCREENSHOTS=true --update-goldens
  group('screenshots (written to test/screenshots)', skip: !screenshots, () {
    for (final (mode, name) in [(ThemeMode.light, 'light'), (ThemeMode.dark, 'dark')]) {
      testWidgets('gallery – $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        await tester.pumpWidget(app(mode));
        await tester.pumpAndSettle();
        // One image per screenful, top to bottom, so every section can be checked by eye.
        for (var i = 1; i <= 14; i++) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile('screenshots/gallery_${name}_${i.toString().padLeft(2, '0')}.png'));
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -640));
          // Not pumpAndSettle: skeletons / spinners animate forever.
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.binding.setSurfaceSize(null);
      });
    }
  });
}

import 'dart:io';

import 'package:flutter/services.dart';

/// Tests render text with a blocky stand-in font unless real fonts are loaded, so load
/// Poppins (from assets) and the Lucide icon font (from the package) like the app does.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Poppins', [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
  ]);

  // The package font lives in the pub cache; find it via package_config.json.
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final m = RegExp(r'"name":\s*"lucide_icons_flutter",\s*"rootUri":\s*"([^"]+)"').firstMatch(config);
  if (m != null) {
    final root = Uri.parse('${m.group(1)!}/');
    await load('packages/lucide_icons_flutter/Lucide', [root.resolve('assets/lucide.ttf').toFilePath()]);
  }
}

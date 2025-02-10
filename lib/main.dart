import 'package:ai_text_editor/app.dart';
import 'package:ai_text_editor/init.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ai_text_editor/src/rust/frb_generated.dart';

import 'isar/database.dart';
import 'utils/font_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final FontsLoader loader = FontsLoader();
  await loader.loadFonts();
  final _ = await APPConfig.init();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    title: APPConfig.appName,
    size: Size(800, 600),
    minimumSize: Size(800, 600),
    backgroundColor: Colors.white,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await IsarDatabase().initialDatabase();

  runApp(const App());
}

import 'package:ai_text_editor/app.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/utils/logger.dart';
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
  final config = await APPConfig.init();
  if (config.openAIInfo != null) {
    GlobalModel.setModel(config.openAIInfo!);
  } else {
    logger.e("Model not found");
  }
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    title: config.appName,
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

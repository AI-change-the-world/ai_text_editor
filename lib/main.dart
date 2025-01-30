import 'package:ai_text_editor/app.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    title: "AI Text Editor",
    size: Size(800, 600),
    minimumSize: Size(800, 600),
    backgroundColor: Colors.white,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  final model = await initOpenAILikeModel();
  if (model != null) {
    GlobalModel.setModel(model);
  } else {
    logger.e("Model not found");
  }

  runApp(const App());
}

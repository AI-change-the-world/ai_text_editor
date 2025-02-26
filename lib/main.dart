import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/objectbox/database.dart';
import 'package:ai_text_editor/routers.dart';
import 'package:ai_text_editor/utils/file_utils.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_to_pdf/markdown_to_pdf.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ai_text_editor/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final regular =
      await FileUtils.loadAsset("assets/fonts/SourceHanSansCN-Regular.ttf");
  final bold =
      await FileUtils.loadAsset("assets/fonts/SourceHanSansCN-Bold.ttf");

  Converter.loadFontFromBytes(regular, (f) => Converter.regularFont = f);
  Converter.loadFontFromBytes(bold, (f) => Converter.boldFont = f);

  final _ = await APPConfig.init();
  logger.d("config loaded, with ${APPConfig.words.length} sentenses");

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    title: APPConfig.appName,
    size: Styles.size,
    minimumSize: Styles.size,
    backgroundColor: Colors.white,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await ObxDatabase.create();

  runApp(App(
    title: APPConfig.appName,
  ));
}

class App extends StatelessWidget {
  const App({super.key, this.title = 'AI Text Editor'});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
        child: ProviderScope(
            child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: Styles.lightTheme,
      title: title,
      routerConfig: router,
    )));
  }
}

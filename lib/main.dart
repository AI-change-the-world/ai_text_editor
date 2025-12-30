import 'dart:io';

import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/data/datasources/objectbox/database.dart';
import 'package:ai_text_editor/features/settings/notifiers/settings_notifier.dart';
import 'package:ai_text_editor/i18n/translations.g.dart';
import 'package:ai_text_editor/routers.dart';
import 'package:ai_text_editor/utils/file_utils.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_to_pdf/markdown_to_pdf.dart';
import 'package:toastification/toastification.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ai_text_editor/src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // 初始化国际化
  await LocaleSettings.useDeviceLocale();

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
    backgroundColor: Platform.isWindows ? null : Colors.white,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化数据库（服务会在首次访问时懒加载）
  await ObxDatabase.create();
  logger.d("Database initialized");

  runApp(TranslationProvider(child: const ProviderScope(child: App())));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final fontFamily = Styles.getFontFamily(settings.fontFamily);
    logger.d("fontfamily: $fontFamily");

    return ToastificationWrapper(
      child: MaterialApp.router(
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        theme: _applyFontToTheme(Styles.lightTheme, fontFamily),
        darkTheme: _applyFontToTheme(Styles.darkTheme, fontFamily),
        themeMode: settings.themeMode,
        title: APPConfig.appName,
        routerConfig: router,
      ),
    );
  }

  ThemeData _applyFontToTheme(ThemeData theme, String? fontFamily) {
    if (fontFamily == null) return theme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
    );
  }
}

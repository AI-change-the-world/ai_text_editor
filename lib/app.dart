import 'package:ai_text_editor/editor.dart';
import 'package:ai_text_editor/markdown_util.dart';
import 'package:ai_text_editor/notifier.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_bar/menu_bar.dart';

import 'file_structure_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Text Editor',
      home: Home(),
    ));
  }
}

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MenuBarWidget(
        menuButtonStyle: ButtonStyle(
            fixedSize: WidgetStateProperty.all(Size.fromHeight(25)),
            padding: WidgetStateProperty.all(
                EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4))),
        barButtonStyle: ButtonStyle(
            alignment: Alignment.center,
            padding: WidgetStateProperty.all(EdgeInsets.all(1)),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ))),
        barStyle: MenuStyle(
            fixedSize: WidgetStateProperty.all(Size.fromHeight(25)),
            padding:
                WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8.0)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
                side: BorderSide.none,
              ),
            )),
        barButtons: [
          BarButton(
              text: Center(
                child: Text("File"),
              ),
              submenu: SubMenu(menuItems: [
                MenuButton(
                    text: Text("Open"),
                    onTap: () async {
                      print("Open");
                      await openFile();
                    },
                    shortcut:
                        SingleActivator(LogicalKeyboardKey.keyO, control: true),
                    shortcutText: "Ctrl+O"),
                MenuButton(
                  text: Text("Save"),
                  shortcutText: "Ctrl+S",
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyS,
                    control: true,
                  ),
                  onTap: () {
                    print("Save");
                    print(ref.read(editorNotifierProvider.notifier).getText());
                  },
                ),
                MenuButton(
                  text: Text("Exit"),
                  shortcutText: "Ctrl+E",
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyE,
                    control: true,
                  ),
                  onTap: () {
                    print("Exit");
                    SystemNavigator.pop();
                  },
                )
              ]))
        ],
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                StreamBuilder(
                    stream: ref
                        .read(editorNotifierProvider.notifier)
                        .quillTextChangeStream,
                    builder: (c, s) {
                      final models = MarkdownUtil.fromMdString(s.data ?? "");
                      return FileStructureView(
                        models: models,
                      );
                    }),
                Expanded(child: Editor())
              ],
            ),
          ),
        ));
  }
}

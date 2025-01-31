import 'package:ai_text_editor/components/editor.dart';
import 'package:ai_text_editor/notifiers/editor_state.dart';
import 'package:ai_text_editor/utils/file_utils.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/markdown_util.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:he/he.dart';

import 'components/ai_widget.dart';
import 'components/file_structure_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
        child: ProviderScope(
            child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Text Editor',
      home: Home(),
    )));
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
                    print(ref.read(editorNotifierProvider.notifier).getText());
                  },
                ),
                MenuButton(
                    text: Text("Save As"),
                    submenu: SubMenu(menuItems: [
                      MenuButton(
                          text: Text("Markdown"),
                          onTap: () async {
                            final mdString = ref
                                .read(editorNotifierProvider.notifier)
                                .getText();
                            FileUtils.saveFileToMarkdown(mdString).then((p) {
                              ToastUtils.sucess(
                                null,
                                title: "File Saved",
                                description: "check $p",
                              );
                            });
                          }),
                      MenuButton(
                        text: Text("Pdf"),
                      ),
                    ])),
                MenuButton(
                  text: Text("Exit"),
                  shortcutText: "Ctrl+E",
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyE,
                    control: true,
                  ),
                  onTap: () {
                    logger.d("Exiting");
                    SystemNavigator.pop();
                  },
                )
              ])),
          BarButton(
              text: Center(
                child: Text("View"),
              ),
              submenu: SubMenu(menuItems: [
                MenuButton(
                  text: Text("Structure"),
                  shortcutText: "Ctrl+P",
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyP,
                    control: true,
                  ),
                  onTap: () {
                    ref.read(editorNotifierProvider.notifier).toggleStructure();
                  },
                ),
                MenuButton(
                  text: Text("Toolbar"),
                  shortcutText: "Ctrl+T",
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyT,
                    control: true,
                  ),
                  onTap: () {
                    ref
                        .read(editorNotifierProvider.notifier)
                        .changeToolbarPosition(ToolbarPosition.top);
                  },
                ),
                MenuButton(
                  text: Text("AI"),
                  onTap: () {
                    ref.read(editorNotifierProvider.notifier).toggleAi(
                        open: !ref.read(editorNotifierProvider).showAI);
                  },
                )
              ]))
        ],
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(5),
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Row(
                    children: [
                      StreamBuilder(
                          stream: ref
                              .read(editorNotifierProvider.notifier)
                              .quillTextChangeStream,
                          builder: (c, s) {
                            final models =
                                MarkdownUtil.fromMdString(s.data ?? "");
                            return FileStructureView(
                              models: models,
                            );
                          }),
                      Expanded(child: Editor()),
                      AiWidget()
                    ],
                  ),
                ),
                if (ref.watch(editorNotifierProvider.select((v) => v.loading)))
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: AnimatedEightTrigrams(size: 50),
                  )
              ],
            ),
          ),
        ));
  }
}

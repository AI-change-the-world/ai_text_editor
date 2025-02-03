import 'dart:io';

import 'package:ai_text_editor/components/editor.dart';
import 'package:ai_text_editor/components/faded_text.dart';
import 'package:ai_text_editor/components/position_widget.dart';
import 'package:ai_text_editor/notifiers/editor_state.dart';
import 'package:ai_text_editor/src/rust/api/converter_api.dart';
import 'package:ai_text_editor/src/rust/messages.dart';
import 'package:ai_text_editor/utils/file_utils.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/markdown_util.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';
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
import 'src/rust/api/message_api.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
        child: ProviderScope(
            child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Styles.lightTheme,
      title: 'AI Text Editor',
      home: Home(),
    )));
  }
}

const XTypeGroup typeGroup = XTypeGroup(
  label: 'delta',
  extensions: <String>['json'],
);

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  late final stream = normalMessageStream();
  @override
  void initState() {
    super.initState();
    stream.listen((v) {
      if (v.$2 == MessageType.error) {
        ToastUtils.error(
          null,
          title: "Error",
          description: v.$1,
        );
      } else {
        ToastUtils.sucess(
          null,
          title: "AI Response",
          description: v.$1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: MenuBarWidget(
            menuButtonStyle: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.grey[200]),
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
                backgroundColor: WidgetStatePropertyAll(Colors.grey[200]),
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
                          await openFile(acceptedTypeGroups: [typeGroup])
                              .then((v) {
                            if (v == null) {
                              return;
                            }
                            File f = File(v.path);
                            ref
                                .read(editorNotifierProvider.notifier)
                                .loadFromFile(f);
                          });
                        },
                        shortcut: SingleActivator(LogicalKeyboardKey.keyO,
                            control: true),
                        shortcutText: "Ctrl+O"),
                    MenuButton(
                      text: Text("Save"),
                      shortcutText: "Ctrl+S",
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyS,
                        control: true,
                      ),
                      onTap: () {
                        final j =
                            ref.read(editorNotifierProvider.notifier).getJson();
                        if (j.isEmpty) {
                          ToastUtils.error(
                            null,
                            title: "Error",
                            description: "Editor is empty",
                          );
                          return;
                        }

                        if (ref.read(editorNotifierProvider).currentFilePath !=
                            null) {
                          FileUtils.updateJsonFile(
                                  j,
                                  ref
                                      .read(editorNotifierProvider)
                                      .currentFilePath!)
                              .then((_) {
                            ToastUtils.sucess(
                              null,
                              title: "File Saved",
                            );
                            ref.read(editorNotifierProvider.notifier).updateDoc(
                                ref
                                    .read(editorNotifierProvider)
                                    .currentFilePath!);
                            ref
                                .read(editorNotifierProvider.notifier)
                                .setLoading(false);
                          });
                        } else {
                          final filename = "${DateTime.now()}.json";
                          FileUtils.saveFileToJson(j, filename: filename)
                              .then((p) {
                            ToastUtils.sucess(
                              null,
                              title: "File Saved",
                              description: "check $p",
                            );
                            ref.read(editorNotifierProvider.notifier).newDoc(p);
                            ref
                                .read(editorNotifierProvider.notifier)
                                .setLoading(false);
                          });
                        }

                        ref
                            .read(editorNotifierProvider.notifier)
                            .changeSavedStatus(true);
                      },
                    ),
                    MenuButton(
                        text: Text("Export As"),
                        submenu: SubMenu(menuItems: [
                          MenuButton(
                              text: Row(
                                children: [
                                  Expanded(child: Text("Markdown")),
                                  Tooltip(
                                    message: "Experimental feature",
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.grey,
                                      size: 15,
                                    ),
                                  )
                                ],
                              ),
                              onTap: () async {
                                final mdString = ref
                                    .read(editorNotifierProvider.notifier)
                                    .getText();
                                if (mdString.isEmpty) {
                                  ToastUtils.error(
                                    null,
                                    title: "Error",
                                    description: "Editor is empty",
                                  );
                                  return;
                                }
                                FileUtils.saveFileToMarkdown(mdString)
                                    .then((p) {
                                  ToastUtils.sucess(
                                    null,
                                    title: "File Saved",
                                    description: "check $p",
                                  );
                                });
                              }),
                          MenuButton(
                            onTap: () {
                              FileUtils.saveFileToPdf(ref
                                      .read(editorNotifierProvider.notifier)
                                      .quillController
                                      .document)
                                  .then((v) {
                                if (v.toString().isNotEmpty) {
                                  ToastUtils.sucess(
                                    null,
                                    title: "File Saved",
                                    description: "check $v",
                                  );
                                } else {
                                  ToastUtils.error(
                                    null,
                                    title: "Error",
                                    description: "Failed to save file",
                                  );
                                }
                              });
                            },
                            text: Row(
                              children: [
                                Expanded(child: Text("Pdf")),
                                Tooltip(
                                  message: "Experimental feature",
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                    size: 15,
                                  ),
                                )
                              ],
                            ),
                          ),
                          MenuButton(
                            onTap: () {
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .getImage()
                                  .then((v) {
                                if (v == null) {
                                  ToastUtils.error(
                                    null,
                                    title: "Error",
                                    description: "Convert failed",
                                  );
                                } else {
                                  FileUtils.saveFileToImage(v).then((p) {
                                    ToastUtils.sucess(
                                      null,
                                      title: "File Saved",
                                      description: "check $p",
                                    );
                                  });
                                }
                              });
                            },
                            text: Row(
                              children: [
                                Expanded(child: Text("Image")),
                              ],
                            ),
                          ),
                          MenuButton(
                            onTap: () async {
                              final filePath =
                                  await FileUtils.getDocxFilepath();
                              final mdString = ref
                                  .read(editorNotifierProvider.notifier)
                                  .getText();
                              markdownToDocx(
                                  markdownText: mdString, filepath: filePath);
                            },
                            text: Row(
                              children: [
                                Expanded(child: Text("Docx")),
                                Tooltip(
                                  message: "Experimental feature",
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                    size: 15,
                                  ),
                                )
                              ],
                            ),
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
                        ref
                            .read(editorNotifierProvider.notifier)
                            .toggleStructure();
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
              body: Row(
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
                  Expanded(child: Editor()),
                  AiWidget()
                ],
              ),
            ),
          ),
        ),
        if (ref.watch(editorNotifierProvider.select((v) => v.loading)))
          Positioned(
            bottom: 10,
            right: 10,
            child: AnimatedEightTrigrams(size: 50),
          ),
        if (ref.watch(savedNotifierProvider))
          Positioned(
            top: 0,
            right: 10,
            child: FadedText(),
          ),
        Positioned(
          right: 100,
          top: 1,
          child: PositionWidget(),
        )
      ],
    );
  }
}

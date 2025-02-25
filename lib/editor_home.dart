import 'dart:io';

import 'package:ai_text_editor/components/dialogs/new_file_dialog.dart';
import 'package:ai_text_editor/components/structures/editor.dart';
import 'package:ai_text_editor/components/others/faded_text.dart';
import 'package:ai_text_editor/components/others/model_settings_widget.dart';
import 'package:ai_text_editor/components/others/position_widget.dart';
import 'package:ai_text_editor/components/structures/spell_check_view.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/notifiers/app_body_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_state.dart';
import 'package:ai_text_editor/notifiers/models_notifier.dart';
import 'package:ai_text_editor/src/rust/api/converter_api.dart';
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
import 'package:go_router/go_router.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:he/he.dart';

import 'components/structures/ai_widget.dart';
import 'components/structures/file_structure_view.dart';

const XTypeGroup typeGroup = XTypeGroup(
  label: 'delta',
  extensions: <String>['json'],
);

class EditorHome extends ConsumerStatefulWidget {
  const EditorHome({super.key});

  @override
  ConsumerState<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends ConsumerState<EditorHome> {
  @override
  void initState() {
    super.initState();

    final model = ref.read(modelsProvider.notifier).getCurrent();
    if (model != null) {
      GlobalModel.setModel(
          OpenAIInfo(model.baseUrl, model.sk, model.modelName));
      logger.i("Model found, set model ${model.modelName}");
    } else {
      logger.i("Model not found, should set model first");
    }
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
                            ref
                                .read(editorNotifierProvider.notifier)
                                .setCurrentFilePath(f.path);
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
                      onTap: () async {
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
                          logger.d(
                              "save file to ${ref.read(editorNotifierProvider).currentFilePath}");
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
                          await showGeneralDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              barrierDismissible: true,
                              barrierLabel: "new-file-dialog",
                              pageBuilder: (c, _, __) {
                                return Center(
                                  child: NewFileDialog(),
                                );
                              }).then((v) {
                            if (v == null) {
                              return;
                            }

                            final filename = "$v.json";
                            FileUtils.saveFileToJson(j, filename: filename)
                                .then((p) {
                              ToastUtils.sucess(
                                null,
                                title: "File Saved",
                                description: "check $p",
                              );
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .setCurrentFilePath(p);
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .newDoc(p);
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .setLoading(false);
                            });
                          });
                        }

                        ref.read(recentFilesProvider.notifier).refresh();

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
                                      size: Styles.menuBarIconSize,
                                    ),
                                  )
                                ],
                              ),
                              onTap: () async {
                                final mdString = ref
                                    .read(editorNotifierProvider.notifier)
                                    .getText();
                                if (mdString.trim().isEmpty) {
                                  ToastUtils.error(
                                    null,
                                    title: "Error",
                                    description: "Editor is empty",
                                  );
                                  return;
                                }

                                await showGeneralDialog(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    barrierColor: Colors.transparent,
                                    barrierDismissible: true,
                                    barrierLabel: "new-file-dialog",
                                    pageBuilder: (c, _, __) {
                                      return Center(
                                        child: NewFileDialog(
                                          ext: ".md",
                                        ),
                                      );
                                    }).then((v) {
                                  if (v == null) {
                                    return;
                                  }
                                  FileUtils.saveFileToMarkdown(mdString,
                                          filename: "$v.md")
                                      .then((p) {
                                    ToastUtils.sucess(
                                      null,
                                      title: "File Saved",
                                      description: "check $p",
                                    );
                                  });
                                });
                              }),
                          MenuButton(
                            onTap: () async {
                              await showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  barrierDismissible: true,
                                  barrierLabel: "new-file-dialog",
                                  pageBuilder: (c, _, __) {
                                    return Center(
                                      child: NewFileDialog(
                                        ext: ".pdf",
                                      ),
                                    );
                                  }).then((v) {
                                if (v == null) {
                                  return;
                                }
                                FileUtils.saveFileToPdf(
                                        ref
                                            .read(
                                                editorNotifierProvider.notifier)
                                            .quillController
                                            .document,
                                        filename: "$v.pdf")
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
                                    size: Styles.menuBarIconSize,
                                  ),
                                )
                              ],
                            ),
                          ),
                          MenuButton(
                            onTap: () async {
                              ref
                                  .read(editorNotifierProvider.notifier)
                                  .changeToolbarPosition(ToolbarPosition.none);

                              await showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  barrierDismissible: true,
                                  barrierLabel: "new-file-dialog",
                                  pageBuilder: (c, _, __) {
                                    return Center(
                                      child: NewFileDialog(
                                        ext: ".png",
                                      ),
                                    );
                                  }).then((v1) {
                                if (v1 == null) {
                                  return;
                                }
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
                                    FileUtils.saveFileToImage(v,
                                            filename: "$v1.png")
                                        .then((p) {
                                      ToastUtils.sucess(
                                        null,
                                        title: "File Saved",
                                        description: "check $p",
                                      );
                                    });
                                  }
                                });
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
                              await showGeneralDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  barrierDismissible: true,
                                  barrierLabel: "new-file-dialog",
                                  pageBuilder: (c, _, __) {
                                    return Center(
                                      child: NewFileDialog(
                                        ext: ".docx",
                                      ),
                                    );
                                  }).then((v) async {
                                if (v == null) {
                                  return;
                                }
                                final filePath =
                                    await FileUtils.getDocxFilepath(
                                        filename: "$v.docx");
                                final mdString = ref
                                    .read(editorNotifierProvider.notifier)
                                    .getText();
                                markdownToDocx(
                                    markdownText: mdString, filepath: filePath);
                              });
                            },
                            text: Row(
                              children: [
                                Expanded(child: Text("Docx")),
                                Tooltip(
                                  message: "Experimental feature",
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                    size: Styles.menuBarIconSize,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ])),
                    MenuButton(
                      text: Text("Back to main"),
                      onTap: () {
                        context.go('/');
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
                        if (ref.read(editorNotifierProvider).toolbarPosition ==
                            ToolbarPosition.none) {
                          ref
                              .read(editorNotifierProvider.notifier)
                              .changeToolbarPosition(ToolbarPosition.top);
                        } else {
                          ref
                              .read(editorNotifierProvider.notifier)
                              .changeToolbarPosition(ToolbarPosition.none);
                        }
                      },
                    ),
                    MenuButton(
                      text: Text("AI"),
                      onTap: () {
                        ref.read(editorNotifierProvider.notifier).toggleAi(
                            open: !ref.read(editorNotifierProvider).showAI);
                      },
                    )
                  ])),
              BarButton(
                  text: Center(
                    child: Text("Tools"),
                  ),
                  submenu: SubMenu(menuItems: [
                    MenuButton(
                      text: Row(
                        spacing: 5,
                        children: [
                          Icon(
                            Icons.spellcheck,
                            size: Styles.menuBarIconSize,
                          ),
                          Text("Spell check")
                        ],
                      ),
                      onTap: () async {
                        ref.read(editorNotifierProvider.notifier).spellCheck();
                      },
                    ),
                  ])),
              BarButton(
                  text: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text("Settings"),
                  ),
                  submenu: SubMenu(menuItems: [
                    MenuButton(
                      onTap: () {
                        showGeneralDialog(
                            barrierColor: Colors.transparent,
                            context: context,
                            pageBuilder: (c, _, __) {
                              return ModelSettingsWidget();
                            });
                      },
                      text: Row(
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.desktop_mac,
                            size: Styles.menuBarIconSize,
                          ),
                          Text("Models")
                        ],
                      ),
                    ),
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
                  AiWidget(),
                  SpellCheckView()
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
        if (!ref.watch(savedNotifierProvider))
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

import 'dart:io';

import 'package:ai_text_editor/components/add_model_dialog.dart';
import 'package:ai_text_editor/components/animated_text.dart';
import 'package:ai_text_editor/components/select_recent_file_dialog.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/notifiers/app_body_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/notifiers/models_notifier.dart';
import 'package:ai_text_editor/objectbox/model.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class AppBody extends ConsumerStatefulWidget {
  const AppBody({super.key});

  @override
  ConsumerState<AppBody> createState() => _AppBodyState();
}

class _AppBodyState extends ConsumerState<AppBody> {
  static List<String> items = ["fullpath", "basename"];
  String selectedItem = items.first;

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(recentFilesProvider);
    final models = ref.watch(modelsProvider);
    logger.d("find files: ${files.length} ,current model ${models.current}");
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Text.rich(TextSpan(
              text: "Welcome to ${APPConfig.appName}\n",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                    text: "Enjoy writing with AI",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.normal))
              ])),
          Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Start",
                    style: TextStyle(fontSize: 24),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        context.go('/editor');
                      },
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.file_present,
                            size: Styles.menuBarIconSize,
                            color: Styles.textButtonColor,
                          ),
                          Text(
                            "New file ...",
                            style: TextStyle(color: Styles.textButtonColor),
                          )
                        ],
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                            barrierLabel: "select-recent-file-dialog",
                            barrierColor: Colors.transparent,
                            barrierDismissible: true,
                            context: context,
                            pageBuilder: (c, _, __) {
                              return Center(
                                child: SelectRecentFileDialog(
                                  files: files,
                                ),
                              );
                            }).then((v) {
                          if (v != null) {
                            ref
                                .read(editorNotifierProvider.notifier)
                                .loadFromFile(v as File)
                                .then((_) {
                              // ignore: use_build_context_synchronously
                              context.go('/editor');
                            });
                          }
                        });
                      },
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(
                            Icons.file_open,
                            size: Styles.menuBarIconSize,
                            color: Styles.textButtonColor,
                          ),
                          Text(
                            "Open file ...",
                            style: TextStyle(color: Styles.textButtonColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )),
          Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(
                    children: [
                      Text(
                        "Recent",
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      SizedBox(
                        width: 125,
                        height: 30,
                        child: DropdownButtonFormField2<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            // Add more decoration..
                          ),
                          customButton: SizedBox(
                            width: 100,
                            height: 30,
                            child: Center(
                              child: Row(
                                spacing: 5,
                                children: [
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(selectedItem),
                                  Spacer(),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black45,
                                  )
                                ],
                              ),
                            ),
                          ),
                          value: selectedItem,
                          items: items
                              .map((item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null || value == selectedItem) {
                              return;
                            }
                            setState(() {
                              selectedItem = value.toString();
                            });
                          },
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.only(right: 8),
                          ),
                          iconStyleData: const IconStyleData(
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black45,
                            ),
                            iconSize: 16,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (c, i) {
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              File f = File(files[i].path);
                              if (f.existsSync()) {
                                ref
                                    .read(editorNotifierProvider.notifier)
                                    .loadFromFile(f)
                                    .then((_) {
                                  // ignore: use_build_context_synchronously
                                  context.go('/editor');
                                });
                              } else {
                                ToastUtils.error(context,
                                    title: "File Not Exists");
                                logger.e("file not exists: ${files[i].path}");
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 5, bottom: 5),
                              child: Row(
                                spacing: 10,
                                children: [
                                  Icon(
                                    Icons.file_open,
                                    size: Styles.menuBarIconSize,
                                    color: Styles.textButtonColor,
                                  ),
                                  Expanded(
                                      child: Text(
                                    selectedItem == "fullpath"
                                        ? files[i].path
                                        : path.basename(files[i].path),
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Styles.textButtonColor),
                                  ))
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: files.length,
                    ),
                  ),
                ],
              )),
          Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(
                    spacing: 10,
                    children: [
                      Text(
                        "Models",
                        style: TextStyle(fontSize: 24),
                      ),
                      InkWell(
                        onTap: () async {
                          showGeneralDialog(
                              barrierColor: Colors.white.withValues(alpha: 0.5),
                              context: context,
                              pageBuilder: (c, _, __) {
                                return Center(
                                  child: AddModelDialog(),
                                );
                              }).then((v) {
                            if (v == null) {
                              return;
                            }
                            ref
                                .read(modelsProvider.notifier)
                                .addModel(v as Model);
                          });
                        },
                        child: Icon(
                          Icons.add_box,
                          color: Colors.green,
                        ),
                      )
                    ],
                  ),
                  Expanded(
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        ...models.models.map((e) => AnimatedText(
                              text: e.modelName +
                                  (models.current == e.tag ? " (in use)" : ""),
                              onTap: () {
                                if (models.current != e.tag) {
                                  ref
                                      .read(modelsProvider.notifier)
                                      .addChangeHistory(e);
                                }
                              },
                            ))
                      ],
                    ),
                  ))
                ],
              ))
        ],
      ),
    );
  }
}

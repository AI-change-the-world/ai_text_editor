import 'dart:io';

import 'package:ai_text_editor/components/select_recent_file_dialog.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/notifiers/app_body_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
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
  bool showFullPath = true;

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(recentFilesProvider);
    logger.d("find files: ${files.length}");
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
              flex: 2,
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
              flex: 4,
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
                        width: 30,
                      ),
                      Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.blueAccent),
                        child: Text(
                          showFullPath ? "fullpath" : "basename",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                            value: showFullPath,
                            onChanged: (s) {
                              setState(() {
                                showFullPath = s;
                              });
                            }),
                      )
                    ],
                  ),
                  ...files.map((e) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            File f = File(e.path);
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
                              logger.e("file not exists: ${e.path}");
                            }
                          },
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
                                showFullPath ? e.path : path.basename(e.path),
                                maxLines: 1,
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Styles.textButtonColor),
                              ))
                            ],
                          ),
                        ),
                      ))
                ],
              ))
        ],
      ),
    );
  }
}

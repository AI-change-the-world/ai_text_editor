import 'package:ai_text_editor/components/select_recent_file_dialog.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/notifiers/app_body_notifier.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// TODO refresh after navigate
class AppBody extends ConsumerWidget {
  const AppBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text(
                    "Recent",
                    style: TextStyle(fontSize: 24),
                  ),
                  ...files.map((e) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {},
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
                                e.path,
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

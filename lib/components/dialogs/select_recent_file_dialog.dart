import 'dart:io';

import 'package:ai_text_editor/objectbox/recent_files.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import '../../utils/logger.dart';

class SelectRecentFileDialog extends StatefulWidget {
  const SelectRecentFileDialog({super.key, required this.files});
  final List<RecentFiles> files;

  @override
  State<SelectRecentFileDialog> createState() => _SelectRecentFileDialogState();
}

class _SelectRecentFileDialogState extends State<SelectRecentFileDialog> {
  bool showFullPath = true;

  @override
  Widget build(BuildContext context) {
    Map<String, List<RecentFiles>> fileMap =
        groupRecentFilesByDay(widget.files);

    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        width: 400,
        height: 300,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: fileMap.entries.map((e) {
                  return Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        ...e.value.map((file) {
                          return GestureDetector(
                            onTap: () {
                              File f = File(file.path);
                              if (f.existsSync()) {
                                Navigator.of(context).pop(f);
                              } else {
                                ToastUtils.error(context,
                                    title: "File Not Exists");
                                logger.e("file not exists: ${file.path}");
                              }
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: SizedBox(
                                height: 30,
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
                                      showFullPath
                                          ? file.path
                                          : path.basename(file.path),
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
                        })
                      ]);
                }).toList(),
              ),
            ),
            Positioned(
                right: 0,
                top: 0,
                child: Row(
                  children: [
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
                      scale: 0.6,
                      child: Switch(
                          value: showFullPath,
                          onChanged: (s) {
                            setState(() {
                              showFullPath = s;
                            });
                          }),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

import 'package:ai_text_editor/objectbox/recent_files.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';

class SelectRecentFileDialog extends StatelessWidget {
  const SelectRecentFileDialog({super.key, required this.files});
  final List<RecentFiles> files;

  @override
  Widget build(BuildContext context) {
    Map<String, List<RecentFiles>> fileMap = groupRecentFilesByDay(files);

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
        child: SingleChildScrollView(
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ...e.value.map((file) {
                      return GestureDetector(
                        onTap: () {},
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
                                  file.path,
                                  maxLines: 1,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      TextStyle(color: Styles.textButtonColor),
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
      ),
    );
  }
}

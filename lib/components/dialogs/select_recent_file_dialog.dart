import 'package:ai_text_editor/data/datasources/objectbox/entities/document_meta.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';

/// 选择最近文档对话框
class SelectRecentDocumentDialog extends StatefulWidget {
  const SelectRecentDocumentDialog({super.key, required this.documents});
  final List<DocumentMeta> documents;

  @override
  State<SelectRecentDocumentDialog> createState() =>
      _SelectRecentDocumentDialogState();
}

class _SelectRecentDocumentDialogState
    extends State<SelectRecentDocumentDialog> {
  bool showUuid = false;

  @override
  Widget build(BuildContext context) {
    // 按最后访问时间分组
    Map<String, List<DocumentMeta>> docMap =
        _groupDocumentsByDay(widget.documents);

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
                children: docMap.entries.map((e) {
                  return Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ...e.value.map((doc) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(doc);
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: SizedBox(
                              height: 30,
                              child: Row(
                                spacing: 10,
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: Styles.menuBarIconSize,
                                    color: Styles.textButtonColor,
                                  ),
                                  Expanded(
                                    child: Text(
                                      showUuid ? doc.uuid : doc.title,
                                      maxLines: 1,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Styles.textButtonColor),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      })
                    ],
                  );
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
                      showUuid ? "uuid" : "title",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: showUuid,
                      onChanged: (s) {
                        setState(() {
                          showUuid = s;
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 按天分组文档
  Map<String, List<DocumentMeta>> _groupDocumentsByDay(
      List<DocumentMeta> docs) {
    Map<String, List<DocumentMeta>> grouped = {};

    for (var doc in docs) {
      String dayKey = GetTimeAgo.parse(
          DateTime.fromMillisecondsSinceEpoch(doc.lastAccessedAt));

      grouped.putIfAbsent(dayKey, () => []).add(doc);
    }

    return grouped;
  }
}

/// @deprecated Use SelectRecentDocumentDialog instead
typedef SelectRecentFileDialog = SelectRecentDocumentDialog;

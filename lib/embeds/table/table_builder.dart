import 'dart:convert';

import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTableEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    // final l = node.value.data.split(",");
    final m = jsonDecode(node.value.data);

    return SizedBox(
      height: 30 * m["colCount"] + 40,
      width: 100,
      child: NonEditableTable(
        rowCount: m["rowCount"],
        colCount: m["colCount"],
        values: m["values"],
        uuid: m["uuid"],
      ),
    );
  }

  @override
  String toPlainText(Embed node) {
    final m = jsonDecode(node.value.data);
    return m['uuid'];
  }

  @override
  String get key => "custom-embed-table";
}

class NonEditableTable extends ConsumerStatefulWidget {
  const NonEditableTable(
      {super.key,
      required this.rowCount,
      required this.colCount,
      required this.values,
      required this.uuid});
  final int rowCount;
  final int colCount;
  final List values;
  final String uuid;

  @override
  ConsumerState<NonEditableTable> createState() => _NonEditableTableState();
}

class _NonEditableTableState extends ConsumerState<NonEditableTable> {
  bool isHover = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  (double, double) _getPosition(GlobalKey key) {
    // 获取当前元素的 RenderBox
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    // 获取元素的在屏幕中的位置
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return (position.dy, size.height);
  }

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        if (!isHover) {
          setState(() {
            isHover = true;
          });
        }
      },
      onExit: (event) {
        if (isHover) {
          setState(() {
            isHover = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          showGeneralDialog(
              barrierColor: Colors.transparent,
              context: context,
              pageBuilder: (c, _, __) {
                final v = _getPosition(_key);
                return Material(
                  color: Colors.white,
                  child: AnimatedDialog(
                    height: v.$2,
                    top: v.$1,
                    rowCount: widget.rowCount,
                    colCount: widget.colCount,
                    values: widget.values,
                  ),
                );
              }).then((v) {
            if (v != null) {
              (v as Map)["uuid"] = widget.uuid;
              ref
                  .read(editorNotifierProvider.notifier)
                  .onEmbedTrigger(widget.uuid);

              ref.read(editorNotifierProvider.notifier).changeTable(v);
            }
          });
        },
        child: Container(
          key: _key,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHover ? Colors.grey[200] : Colors.transparent,
          ),
          child: Table(
            border: TableBorder.all(), // 设置表格边框
            children: List.generate(widget.rowCount, (i) {
              return TableRow(
                children: List.generate(widget.colCount, (j) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        Text(widget.values[i * widget.colCount + j].toString()),
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class AnimatedDialog extends StatefulWidget {
  const AnimatedDialog(
      {super.key,
      required this.height,
      required this.top,
      required this.rowCount,
      required this.colCount,
      required this.values});
  final double height;
  final double top;

  /// data
  final int rowCount;
  final int colCount;
  final List values;

  @override
  State<AnimatedDialog> createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<AnimatedDialog> {
  late double top = widget.top;
  late double height = widget.rowCount * 50 + /*button height*/ 80;
  late double middle = MediaQuery.of(context).size.height / 2 - height / 2;

  bool isMiddle = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((c) {
      setState(() {
        top = middle;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
            top: top,
            duration: Duration(milliseconds: 500),
            child: SizedBox(
              height: height,
              width: MediaQuery.of(context).size.width,
              child: EditableTable(
                rowCount: widget.rowCount,
                colCount: widget.colCount,
                values: widget.values,
                onRowAdd: () {
                  height += 50;
                  setState(() {
                    middle =
                        MediaQuery.of(context).size.height / 2 - height / 2;
                    top = middle;
                  });
                },
                onRowRemove: () {
                  height -= 50;
                  setState(() {
                    middle =
                        MediaQuery.of(context).size.height / 2 - height / 2;
                    top = middle;
                  });
                },
              ),
            ))
      ],
    );
  }
}

class EditableTable extends ConsumerStatefulWidget {
  const EditableTable(
      {super.key,
      required this.rowCount,
      required this.colCount,
      required this.values,
      required this.onRowAdd,
      required this.onRowRemove});
  final int rowCount;
  final int colCount;
  final List values;
  final VoidCallback onRowAdd;
  final VoidCallback onRowRemove;

  @override
  // ignore: library_private_types_in_public_api
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends ConsumerState<EditableTable> {
  List<List<TextEditingController>> controllers = [];
  late int rowCount = widget.rowCount;
  late int colCount = widget.colCount;

  @override
  void initState() {
    super.initState();
    _initializeTable();
  }

  void _initializeTable() {
    controllers = List.generate(
      rowCount,
      (i) => List.generate(
          colCount,
          (j) => TextEditingController()
            ..text = widget.values[i * colCount + j].toString()),
    );
  }

  /// 添加一行
  void _addRow() {
    setState(() {
      controllers.add(List.generate(colCount, (j) => TextEditingController()));
      rowCount++;
    });
    widget.onRowAdd();
  }

  /// 删除最后一行
  void _removeRow() {
    if (rowCount > 1) {
      setState(() {
        for (var controller in controllers.last) {
          controller.dispose();
        }
        controllers.removeLast();
        rowCount--;
      });
      widget.onRowRemove();
    }
  }

  /// 添加一列
  void _addColumn() {
    setState(() {
      for (var row in controllers) {
        row.add(TextEditingController());
      }
      colCount++;
    });
  }

  /// 删除最后一列
  void _removeColumn() {
    if (colCount > 1) {
      setState(() {
        for (var row in controllers) {
          row.last.dispose();
          row.removeLast();
        }
        colCount--;
      });
    }
  }

  @override
  void dispose() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 操作按钮
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                spacing: 20,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6), // 调整按钮大小
                      ),
                      onPressed: _addColumn,
                      child: const Text('➕ 增加列')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6), // 调整按钮大小
                      ),
                      onPressed: _removeColumn,
                      child: const Text('➖ 删除列')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6), // 调整按钮大小
                      ),
                      onPressed: () {
                        List<String> v = [];
                        for (int i = 0; i < rowCount; i++) {
                          for (int j = 0; j < colCount; j++) {
                            v.add(controllers[i][j].text);
                          }
                        }
                        Map data = {
                          "rowCount": rowCount,
                          "colCount": colCount,
                          "values": v,
                        };

                        Navigator.of(context).pop(data);
                      },
                      child: const Text('确定')),
                ],
              ),
            ),

            // 可滚动表格
            Expanded(
              child: Row(
                spacing: 20,
                children: [
                  Expanded(
                      child: Table(
                    border: TableBorder.all(),
                    children: List.generate(rowCount, (i) {
                      return TableRow(
                        children: List.generate(colCount, (j) {
                          return SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controllers[i][j],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }),
                      );
                    }),
                  )),
                  Column(
                    spacing: 20,
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4), // 设置圆角半径
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6), // 调整按钮大小
                          ),
                          onPressed: _addRow,
                          child: const Text('➕ 增加行')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4), // 设置圆角半径
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6), // 调整按钮大小
                          ),
                          onPressed: _removeRow,
                          child: const Text('➖ 删除行')),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

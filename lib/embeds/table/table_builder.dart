import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomTableEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    final l = node.value.data.split(",");
    return SizedBox(
      height: 50 * int.parse(l[1]) + 40,
      width: 100,
      child:
          EditableTable(rowCount: int.parse(l[0]), colCount: int.parse(l[1])),
    );
  }

  @override
  String get key => "custom-embed-table";
}

class EditableTable extends StatefulWidget {
  const EditableTable(
      {super.key, required this.rowCount, required this.colCount});
  final int rowCount;
  final int colCount;

  @override
  // ignore: library_private_types_in_public_api
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  late List<List<TextEditingController>> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      widget.rowCount,
      (i) => List.generate(widget.colCount, (j) => TextEditingController()),
    );
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
    return Scaffold(
      body: Table(
        border: TableBorder.all(), // 设置表格边框
        children: List.generate(widget.rowCount, (i) {
          return TableRow(
            children: List.generate(widget.colCount, (j) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controllers[i][j],
                  decoration: const InputDecoration(
                    border: InputBorder.none, // 移除默认边框
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

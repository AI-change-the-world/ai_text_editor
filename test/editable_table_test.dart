import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editable Table with Add/Remove Rows & Columns',
      home: EditableTable(),
    );
  }
}

class EditableTable extends StatefulWidget {
  const EditableTable({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditableTableState createState() => _EditableTableState();
}

class _EditableTableState extends State<EditableTable> {
  List<List<TextEditingController>> controllers = [];
  int rowCount = 5;
  int colCount = 4;

  @override
  void initState() {
    super.initState();
    _initializeTable();
  }

  void _initializeTable() {
    controllers = List.generate(
      rowCount,
      (i) => List.generate(colCount, (j) => TextEditingController()),
    );
  }

  /// 添加一行
  void _addRow() {
    setState(() {
      controllers.add(List.generate(colCount, (j) => TextEditingController()));
      rowCount++;
    });
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
    return Scaffold(
      appBar: AppBar(
          title: const Text('Editable Table with Dynamic Rows & Columns')),
      body: Column(
        children: [
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _addRow, child: const Text('➕ 增加行')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _removeRow, child: const Text('➖ 删除行')),
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: _addColumn, child: const Text('➕ 增加列')),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _removeColumn, child: const Text('➖ 删除列')),
              ],
            ),
          ),

          // 可滚动表格
          Expanded(
            child: Table(
              border: TableBorder.all(),
              children: List.generate(rowCount, (i) {
                return TableRow(
                  children: List.generate(colCount, (j) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
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
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class SelectOrInputFileUrlDialog extends StatefulWidget {
  const SelectOrInputFileUrlDialog({super.key});

  @override
  State<SelectOrInputFileUrlDialog> createState() =>
      _SelectOrInputFileUrlDialogState();
}

class _SelectOrInputFileUrlDialogState
    extends State<SelectOrInputFileUrlDialog> {
  final TextEditingController _urlController = TextEditingController();
  String _selectedOption = 'url';

  Future<void> _pickImage() async {
    final XTypeGroup typeGroup =
        XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'gif']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      _urlController.text = file.path;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        width: 500,
        height: 140,
        child: Column(
          spacing: 20,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                    child: TextField(
                  enabled: _selectedOption == 'url',
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: _selectedOption == 'url' ? '输入图片 URL' : null,
                    border: OutlineInputBorder(),
                  ),
                )),
                DropdownButton<String>(
                  value: _selectedOption,
                  items: ['local', 'url'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                    });
                    if (_selectedOption == 'local') {
                      _pickImage();
                    }
                  },
                ),
              ],
            ),
            SizedBox(
              height: 30,
              child: Row(
                spacing: 10,
                children: [
                  Spacer(),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6), // 调整按钮大小
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("取消")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // 设置圆角半径
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6), // 调整按钮大小
                      ),
                      onPressed: () {
                        Navigator.of(context).pop({
                          'url': _urlController.text,
                          'type': _selectedOption
                        });
                      },
                      child: Text("确定"))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

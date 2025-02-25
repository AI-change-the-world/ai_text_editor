import 'dart:io';

import 'package:ai_text_editor/utils/file_utils.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';

class NewFileDialog extends StatefulWidget {
  const NewFileDialog({super.key, this.ext = ".json"});
  final String ext;

  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = "${DateTime.now()}";
    _nameController.selection =
        TextSelection(baseOffset: 0, extentOffset: _nameController.text.length);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        width: 300,
        height: 120,
        child: Column(
          spacing: 10,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                    child: TextField(
                        autofocus: true,
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "Input filename",
                          hintStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ))),
                Text(
                  widget.ext,
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
            Spacer(),
            SizedBox(
              height: 30,
              child: Row(spacing: 10, children: [
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14, color: Colors.cyanAccent),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) {
                      return;
                    }
                    final savePath = await FileUtils.savePath;
                    File file = File("$savePath/${_nameController.text}.json");
                    if (file.existsSync()) {
                      _nameController.text =
                          _nameController.text + Uuid().v4().substring(0, 4);
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop(_nameController.text);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 14, color: Colors.cyanAccent),
                  ),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}

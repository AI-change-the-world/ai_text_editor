import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class FormularEditorDialog extends StatefulWidget {
  const FormularEditorDialog({super.key, required this.formular});
  final String formular;

  @override
  State<FormularEditorDialog> createState() => _FormularEditorDialogState();
}

class _FormularEditorDialogState extends State<FormularEditorDialog> {
  late final ValueNotifier<String> _formular = ValueNotifier(widget.formular);
  late final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.formular;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _formular,
        builder: (c, v, _) {
          return Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 600,
              height: 500,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    "Input text :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white),
                      child: TextField(
                        maxLines: null,
                        controller: _controller,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Formular',
                        ),
                        onChanged: (_) {
                          _formular.value = _controller.text;
                        },
                      ),
                    ),
                  ),
                  Text(
                    "Generated formular :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white),
                      child: GptMarkdown(v),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Spacer(),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(4), // 设置圆角半径
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3), // 调整按钮大小
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(_controller.text);
                            },
                            child: Text("Save")),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}

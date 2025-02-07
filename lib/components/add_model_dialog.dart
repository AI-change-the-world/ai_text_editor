import 'package:ai_text_editor/isar/model.dart';
import 'package:flutter/material.dart';

class AddModelDialog extends StatelessWidget {
  AddModelDialog({super.key, this.model});
  final Model? model;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tagController = TextEditingController()
    ..text = model?.tag ?? "";
  late final TextEditingController _baseUrlController = TextEditingController()
    ..text = model?.baseUrl ?? "";
  late final TextEditingController _modelNameController =
      TextEditingController()..text = model?.modelName ?? "";
  late final TextEditingController _skController = TextEditingController()
    ..text = model?.sk ?? "";

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 10,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    labelText: 'Tag',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Base URL';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _modelNameController,
                  decoration: InputDecoration(
                    labelText: 'Model Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _skController,
                  decoration: InputDecoration(
                    labelText: 'Secret Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                Row(
                  spacing: 10,
                  children: [
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style:
                            TextStyle(fontSize: 14, color: Colors.cyanAccent),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Model model = Model()
                            ..baseUrl = _baseUrlController.text
                            ..modelName = _modelNameController.text
                            ..sk = _skController.text
                            ..tag = _tagController.text;
                          Navigator.of(context).pop(model);
                        }
                      },
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            fontSize: 14, color: Colors.lightBlueAccent),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

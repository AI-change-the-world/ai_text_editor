// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';

class ConfigForm extends StatefulWidget {
  const ConfigForm({super.key});

  @override
  _ConfigFormState createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  final _formKey = GlobalKey<FormState>();
  String? tag;
  String? baseUrl;
  String? modelName;
  String? sk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration Form'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tag',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => tag = value,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
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
                    onSaved: (value) => baseUrl = value,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Model Name',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (value) => modelName = value,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Secret Key',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onSaved: (value) => sk = value,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Form Submitted!')),
                        );
                        print(
                            'Tag: $tag, Base URL: $baseUrl, Model Name: $modelName, SK: $sk');
                      }
                    },
                    child: Text(
                      'Submit',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ConfigForm(),
    theme: ThemeData(primarySwatch: Colors.blue),
  ));
}

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  String? _imagePath;
  final TextEditingController _urlController = TextEditingController();
  String _selectedOption = 'Local';

  Future<void> _pickImage() async {
    final XTypeGroup typeGroup =
        XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg']);
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _imagePath = file.path;
      });
    }
  }

  void _loadImageFromUrl() {
    setState(() {
      _imagePath = _urlController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('图片选择器')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedOption,
              items: ['Local', 'URL'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue!;
                });
              },
            ),
            SizedBox(height: 10),
            _selectedOption == 'Local'
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('选择本地图片'),
                  )
                : Column(
                    children: [
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: '输入图片 URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadImageFromUrl,
                        child: Text('加载 URL 图片'),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            _imagePath != null
                ? _imagePath!.startsWith('http')
                    ? ExtendedImage.network(_imagePath!)
                    : Image.asset(_imagePath!)
                : Text('未选择图片'),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get _localPath async {
    Directory directory;
    try {
      directory = (await getDownloadsDirectory())!;
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    return directory.path;
  }

  static Future saveFileToMarkdown(String content,
      {String filename = "example.md"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  static Future saveFileToJson(String content,
      {String filename = "example.json"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  static Future saveFileToImage(Uint8List content,
      {String filename = "example.png"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    await file.writeAsBytes(content);
    return file.path;
  }
}

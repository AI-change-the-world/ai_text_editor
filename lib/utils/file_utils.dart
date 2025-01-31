// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get _localPath async {
    final directory = await getApplicationSupportDirectory(); // 获取应用的支持目录
    return directory.path;
  }

  static Future saveFileToMarkdown(String content,
      {String filename = "example.md"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    await file.writeAsString(content);
    return file.path;
  }
}

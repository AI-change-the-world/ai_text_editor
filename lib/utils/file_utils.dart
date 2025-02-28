// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:markdown_to_pdf/markdown_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get _localPath async {
    Directory directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @Deprecated("unused")
  static Future<String> get _downloadPath async {
    Directory directory;
    try {
      directory = (await getDownloadsDirectory())!;
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    return directory.path;
  }

  static Future<String> getDocxFilepath(
      {String filename = "example.docx"}) async {
    return "${await _localPath}/$filename";
  }

  /// TODO : refactor this method
  static Future saveFileToPdf(String mdString,
      {String filename = "example.pdf"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');

    try {
      final doc = await Converter.convert(mdString);
      await file.writeAsBytes(await doc.save());
      return file.path;
    } catch (e) {
      logger.e(e);
      return "";
    }
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

  static Future<String> get savePath => _localPath;

  static Future updateJsonFile(String content, String filepath) async {
    final file = File(filepath);
    await file.writeAsString(content);
  }

  static Future saveFileToImage(Uint8List content,
      {String filename = "example.png"}) async {
    final path = await _localPath;
    final file = File('$path/$filename');
    await file.writeAsBytes(content);
    return file.path;
  }

  static Future<ByteData> loadAsset(String asset) async {
    final ByteData bytes = await rootBundle.load(asset);
    return bytes;
  }
}

// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:typed_data';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import 'font_loader.dart';

class FileUtils {
  FileUtils._();

  static Future<String> get _localPath async {
    Directory directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> get _downloadPath async {
    Directory directory;
    try {
      directory = (await getDownloadsDirectory())!;
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }
    return directory.path;
  }

  static final PDFPageFormat params = PDFPageFormat.a4;

  static Future<String> getDocxFilepath(
      {String filename = "example.docx"}) async {
    return "${await _downloadPath}/$filename";
  }

  static final FontsLoader loader = FontsLoader();

  static Future saveFileToPdf(Document document,
      {String filename = "example.pdf"}) async {
    final path = await _downloadPath;
    final file = File('$path/$filename');
    PDFConverter pdfConverter = PDFConverter(
      backMatterDelta: null,
      frontMatterDelta: null,
      document: document.toDelta(),
      fallbacks: [...loader.allFonts()],
      onRequestFontFamily: (FontFamilyRequest familyRequest) {
        final normalFont = loader.normalFont();
        final boldFont = loader.boldFont();
        final italicFont = loader.boldFont();

        return FontFamilyResponse(
          fontNormalV: normalFont,
          boldFontV: boldFont,
          italicFontV: italicFont,
          fallbacks: [normalFont, italicFont, boldFont],
        );
      },
      pageFormat: params,
    );

    try {
      final pw.Document? doc = await pdfConverter.createDocument();

      await file.writeAsBytes(await doc!.save());
      return file.path;
    } catch (e) {
      logger.e(e);
      return "";
    }
  }

  static Future saveFileToMarkdown(String content,
      {String filename = "example.md"}) async {
    final path = await _downloadPath;
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
    final path = await _downloadPath;
    final file = File('$path/$filename');
    await file.writeAsBytes(content);
    return file.path;
  }
}

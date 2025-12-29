import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';
import '../src/rust/api/converter_api.dart' as converter;

/// 导出格式枚举
enum ExportFormat {
  pdf,
  markdown,
  html,
  docx,
}

/// 创建文档请求
class CreateDocumentRequest {
  final String title;
  final String? parentFolderId;
  final List<String>? tags;
  final String? initialContent;

  CreateDocumentRequest({
    required this.title,
    this.parentFolderId,
    this.tags,
    this.initialContent,
  });
}

/// 文档内容
class DocumentContentData {
  final String plainText;
  final String? deltaJson;

  DocumentContentData({
    required this.plainText,
    this.deltaJson,
  });
}

/// 文档服务接口
/// Requirements: 1.4, 1.6, 1.7, 2.1
abstract class IDocumentService {
  Future<DocumentMeta> createDocument(
      String workspaceId, CreateDocumentRequest request);
  Future<void> saveDocument(String documentId, DocumentContentData content);
  Future<DocumentMeta> createFolder(
      String workspaceId, String name, String? parentFolderId);
  Future<void> moveDocument(String documentId, String? targetFolderId);
  Future<DocumentMeta> importFile(String workspaceId, File file);
  Future<Uint8List> exportDocument(String documentId, ExportFormat format);
}

/// 文档服务实现
class DocumentService implements IDocumentService {
  final ObxDatabase _db;
  final Uuid _uuid = const Uuid();

  DocumentService(this._db);

  static DocumentService? _instance;

  /// 获取单例实例（懒加载）
  static DocumentService get instance {
    _instance ??= DocumentService(ObxDatabase.db);
    return _instance!;
  }

  Future<Directory> _getDocumentsDirectory(String workspaceId) async {
    final appDir = await getApplicationSupportDirectory();
    final docsDir = Directory(p.join(
        appDir.path, 'AITextEditor', 'workspaces', workspaceId, 'documents'));
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  @override
  Future<DocumentMeta> createDocument(
      String workspaceId, CreateDocumentRequest request) async {
    final docId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final docsDir = await _getDocumentsDirectory(workspaceId);
    final filePath = p.join(docsDir.path, '$docId.json');

    final docMeta = DocumentMeta(
      uuid: docId,
      workspaceId: workspaceId,
      title: request.title,
      parentFolderId: request.parentFolderId,
      filePath: filePath,
      wordCount: 0,
      characterCount: 0,
      isFolder: false,
      sortOrder: await _getNextSortOrder(workspaceId, request.parentFolderId),
      createdAt: now,
      updatedAt: now,
    );

    if (request.tags != null && request.tags!.isNotEmpty) {
      docMeta.tags = request.tags!;
    }

    _db.documentMetaBox.put(docMeta);

    final initialContent = request.initialContent ?? '';
    final file = File(filePath);
    await file.writeAsString(initialContent);

    final docContent = DocumentContent(
      documentId: docId,
      workspaceId: workspaceId,
      title: request.title,
      content: initialContent,
    );
    if (request.tags != null) {
      docContent.tags = request.tags!;
    }
    _db.documentContentBox.put(docContent);

    return docMeta;
  }

  @override
  Future<void> saveDocument(
      String documentId, DocumentContentData content) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final plainText = content.plainText;
    final wordCount = _countWords(plainText);
    final characterCount = plainText.length;

    final updatedMeta = docMeta.copyWith(
      wordCount: wordCount,
      characterCount: characterCount,
      updatedAt: now,
    );
    _db.documentMetaBox.put(updatedMeta);

    final file = File(docMeta.filePath);
    final contentToSave = content.deltaJson ?? content.plainText;
    await file.writeAsString(contentToSave);

    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final existingContent = contentQuery.findFirst();
    contentQuery.close();

    if (existingContent != null) {
      final updatedContent = existingContent.copyWith(
        content: plainText,
        updatedAt: now,
      );
      _db.documentContentBox.put(updatedContent);
    } else {
      final newContent = DocumentContent(
        documentId: documentId,
        workspaceId: docMeta.workspaceId,
        title: docMeta.title,
        content: plainText,
        updatedAt: now,
      );
      _db.documentContentBox.put(newContent);
    }
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
    final chineseCount = chineseRegex.allMatches(text).length;
    final englishText = text.replaceAll(chineseRegex, ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(word))
        .length;
    return chineseCount + englishWords;
  }

  Future<int> _getNextSortOrder(
      String workspaceId, String? parentFolderId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId) &
            (parentFolderId == null
                ? DocumentMeta_.parentFolderId.isNull()
                : DocumentMeta_.parentFolderId.equals(parentFolderId)))
        .order(DocumentMeta_.sortOrder, flags: Order.descending)
        .build();
    final docs = query.find();
    query.close();
    if (docs.isEmpty) return 0;
    return docs.first.sortOrder + 1;
  }

  @override
  Future<DocumentMeta> createFolder(
      String workspaceId, String name, String? parentFolderId) async {
    final folderId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final folder = DocumentMeta(
      uuid: folderId,
      workspaceId: workspaceId,
      title: name,
      parentFolderId: parentFolderId,
      filePath: '',
      wordCount: 0,
      characterCount: 0,
      isFolder: true,
      sortOrder: await _getNextSortOrder(workspaceId, parentFolderId),
      createdAt: now,
      updatedAt: now,
    );

    _db.documentMetaBox.put(folder);
    return folder;
  }

  @override
  Future<void> moveDocument(String documentId, String? targetFolderId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    // 验证目标文件夹存在（如果不是根目录）
    if (targetFolderId != null) {
      final folderQuery = _db.documentMetaBox
          .query(DocumentMeta_.uuid.equals(targetFolderId) &
              DocumentMeta_.isFolder.equals(true))
          .build();
      final folder = folderQuery.findFirst();
      folderQuery.close();

      if (folder == null) {
        throw FolderNotFoundException(targetFolderId);
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSortOrder =
        await _getNextSortOrder(docMeta.workspaceId, targetFolderId);

    final updatedMeta = docMeta.copyWith(
      parentFolderId: targetFolderId,
      sortOrder: newSortOrder,
      updatedAt: now,
    );
    _db.documentMetaBox.put(updatedMeta);
  }

  @override
  Future<DocumentMeta> importFile(String workspaceId, File file) async {
    final extension = p.extension(file.path).toLowerCase();

    String content;
    String title = p.basenameWithoutExtension(file.path);

    switch (extension) {
      case '.md':
      case '.markdown':
      case '.txt':
        content = await file.readAsString();
        break;
      case '.docx':
        final markdown = await _convertDocxToMarkdown(file.path);
        content = markdown ?? '';
        break;
      default:
        throw UnsupportedFileFormatException(extension);
    }

    return createDocument(
      workspaceId,
      CreateDocumentRequest(
        title: title,
        initialContent: content,
      ),
    );
  }

  Future<String?> _convertDocxToMarkdown(String filePath) async {
    try {
      final result = await converter.otherTypeToMarkdown(filePath: filePath);
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List> exportDocument(
      String documentId, ExportFormat format) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    // 读取文档内容
    final file = File(docMeta.filePath);
    if (!await file.exists()) {
      throw DocumentNotFoundException(documentId);
    }
    final content = await file.readAsString();

    switch (format) {
      case ExportFormat.markdown:
        return Uint8List.fromList(content.codeUnits);
      case ExportFormat.html:
        final html = _convertToHtml(content, docMeta.title);
        return Uint8List.fromList(html.codeUnits);
      case ExportFormat.docx:
        return await _exportToDocx(content, docMeta.title);
      case ExportFormat.pdf:
        return await _exportToPdf(content, docMeta.title);
    }
  }

  String _convertToHtml(String content, String title) {
    // 简单的 Markdown 到 HTML 转换
    var html = content
        .replaceAll(RegExp(r'^### (.+)$', multiLine: true), '<h3>\$1</h3>')
        .replaceAll(RegExp(r'^## (.+)$', multiLine: true), '<h2>\$1</h2>')
        .replaceAll(RegExp(r'^# (.+)$', multiLine: true), '<h1>\$1</h1>')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), '<strong>\$1</strong>')
        .replaceAll(RegExp(r'\*(.+?)\*'), '<em>\$1</em>')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('\n', '<br>');

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>$title</title>
</head>
<body>
  <p>$html</p>
</body>
</html>''';
  }

  Future<Uint8List> _exportToDocx(String content, String title) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, '$title.docx');

    await converter.markdownToDocx(
      markdownText: content,
      filepath: tempPath,
    );

    final file = File(tempPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await file.delete();
      return bytes;
    }
    throw ExportFailedException('DOCX export failed');
  }

  Future<Uint8List> _exportToPdf(String content, String title) async {
    // PDF 导出需要额外的库支持，这里返回占位实现
    // 实际实现可以使用 markdown_to_pdf 包
    throw UnimplementedError('PDF export not yet implemented');
  }
}

/// 文档未找到异常
class DocumentNotFoundException implements Exception {
  final String documentId;
  DocumentNotFoundException(this.documentId);
  @override
  String toString() => 'Document not found: $documentId';
}

/// 文件夹未找到异常
class FolderNotFoundException implements Exception {
  final String folderId;
  FolderNotFoundException(this.folderId);
  @override
  String toString() => 'Folder not found: $folderId';
}

/// 不支持的文件格式异常
class UnsupportedFileFormatException implements Exception {
  final String format;
  UnsupportedFileFormatException(this.format);
  @override
  String toString() => 'Unsupported file format: $format';
}

/// 导出失败异常
class ExportFailedException implements Exception {
  final String message;
  ExportFailedException(this.message);
  @override
  String toString() => 'Export failed: $message';
}

// Extension methods for DocumentService to support document tree operations
extension DocumentServiceExtensions on DocumentService {
  /// 获取工作空间的所有文档
  /// Requirements: 1.4
  Future<List<DocumentMeta>> getDocumentsByWorkspace(String workspaceId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId))
        .order(DocumentMeta_.sortOrder)
        .build();
    final documents = query.find();
    query.close();
    return documents;
  }

  /// 获取单个文档
  Future<DocumentMeta?> getDocument(String documentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final document = query.findFirst();
    query.close();
    return document;
  }

  /// 获取文档内容
  Future<String?> getDocumentContent(String documentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null || docMeta.filePath.isEmpty) {
      return null;
    }

    final file = File(docMeta.filePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// 重命名文档
  /// Requirements: 1.4
  Future<void> renameDocument(String documentId, String newTitle) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedMeta = docMeta.copyWith(
      title: newTitle,
      updatedAt: now,
    );
    _db.documentMetaBox.put(updatedMeta);

    // 更新 DocumentContent 中的标题
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final existingContent = contentQuery.findFirst();
    contentQuery.close();

    if (existingContent != null) {
      final updatedContent = existingContent.copyWith(
        title: newTitle,
        updatedAt: now,
      );
      _db.documentContentBox.put(updatedContent);
    }
  }

  /// 删除文档
  /// Requirements: 1.4
  Future<void> deleteDocument(String documentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    // 如果是文件夹，递归删除所有子文档
    if (docMeta.isFolder) {
      await _deleteChildDocuments(documentId);
    }

    // 删除文件
    if (docMeta.filePath.isNotEmpty) {
      final file = File(docMeta.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 删除 DocumentContent
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final content = contentQuery.findFirst();
    contentQuery.close();
    if (content != null) {
      _db.documentContentBox.remove(content.id);
    }

    // 删除 DocumentMeta
    _db.documentMetaBox.remove(docMeta.id);
  }

  /// 递归删除子文档
  Future<void> _deleteChildDocuments(String parentFolderId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.parentFolderId.equals(parentFolderId))
        .build();
    final children = query.find();
    query.close();

    for (final child in children) {
      if (child.isFolder) {
        await _deleteChildDocuments(child.uuid);
      }

      // 删除文件
      if (child.filePath.isNotEmpty) {
        final file = File(child.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 删除 DocumentContent
      final contentQuery = _db.documentContentBox
          .query(DocumentContent_.documentId.equals(child.uuid))
          .build();
      final content = contentQuery.findFirst();
      contentQuery.close();
      if (content != null) {
        _db.documentContentBox.remove(content.id);
      }

      // 删除 DocumentMeta
      _db.documentMetaBox.remove(child.id);
    }
  }

  /// 更新文档排序
  /// Requirements: 1.4
  Future<void> updateDocumentOrder(
      String documentId, int newSortOrder, String? newParentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta == null) {
      throw DocumentNotFoundException(documentId);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedMeta = docMeta.copyWith(
      sortOrder: newSortOrder,
      parentFolderId: newParentId,
      updatedAt: now,
    );
    _db.documentMetaBox.put(updatedMeta);
  }

  /// 获取文件夹的子文档数量
  Future<int> getChildCount(String folderId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.parentFolderId.equals(folderId))
        .build();
    final count = query.count();
    query.close();
    return count;
  }
}

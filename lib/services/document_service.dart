import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';
import '../src/rust/api/converter_api.dart' as converter;
import 'indexing_service.dart';

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
  final String? deltaJson;

  CreateDocumentRequest({
    required this.title,
    this.parentFolderId,
    this.tags,
    this.initialContent,
    this.deltaJson,
  });
}

/// 文档内容数据
class DocumentContentData {
  final String? deltaJson;
  final String? plainText;
  final String? markdown;

  DocumentContentData({
    this.deltaJson,
    this.plainText,
    this.markdown,
  });
}

/// 文档服务接口
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

  @override
  Future<DocumentMeta> createDocument(
      String workspaceId, CreateDocumentRequest request) async {
    final docId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 创建文档元数据
    final docMeta = DocumentMeta(
      uuid: docId,
      workspaceId: workspaceId,
      title: request.title,
      parentFolderId: request.parentFolderId,
      wordCount: 0,
      characterCount: 0,
      isFolder: false,
      sortOrder: await _getNextSortOrder(workspaceId, request.parentFolderId),
      searchModeIndex: SearchMode.fulltext.index,
      isIndexed: false,
      isEmbedded: false,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
    );

    if (request.tags != null && request.tags!.isNotEmpty) {
      docMeta.tags = request.tags!;
    }

    _db.documentMetaBox.put(docMeta);

    // 创建文档内容
    final plainText = request.initialContent ?? '';
    final deltaJson = request.deltaJson ?? _createEmptyDelta();
    final markdown = plainText;

    final docContent = DocumentContent(
      documentId: docId,
      workspaceId: workspaceId,
      deltaJson: deltaJson,
      plainText: plainText,
      markdown: markdown,
      updatedAt: now,
    );
    _db.documentContentBox.put(docContent);

    // 更新字数统计
    if (plainText.isNotEmpty) {
      final wordCount = _countWords(plainText);
      final updatedMeta = docMeta.copyWith(
        wordCount: wordCount,
        characterCount: plainText.length,
      );
      _db.documentMetaBox.put(updatedMeta);
    }

    return docMeta;
  }

  String _createEmptyDelta() {
    return jsonEncode([
      {'insert': '\n'}
    ]);
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
    final plainText = content.plainText ?? '';
    final wordCount = _countWords(plainText);
    final characterCount = plainText.length;

    // 更新元数据
    final updatedMeta = docMeta.copyWith(
      wordCount: wordCount,
      characterCount: characterCount,
      updatedAt: now,
      lastAccessedAt: now,
      // 内容变更后需要重新索引
      isIndexed: false,
      isEmbedded: false,
    );
    _db.documentMetaBox.put(updatedMeta);

    // 更新内容
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final existingContent = contentQuery.findFirst();
    contentQuery.close();

    if (existingContent != null) {
      final updatedContent = existingContent.copyWith(
        deltaJson: content.deltaJson ?? existingContent.deltaJson,
        plainText: plainText,
        markdown: content.markdown ?? plainText,
        updatedAt: now,
      );
      _db.documentContentBox.put(updatedContent);
    } else {
      final newContent = DocumentContent(
        documentId: documentId,
        workspaceId: docMeta.workspaceId,
        deltaJson: content.deltaJson ?? _createEmptyDelta(),
        plainText: plainText,
        markdown: content.markdown ?? plainText,
        updatedAt: now,
      );
      _db.documentContentBox.put(newContent);
    }

    // 删除旧的切片（内容变更后需要重新切片）
    await _deleteDocumentChunks(documentId);

    // 异步触发索引任务
    _queueIndexing(documentId, docMeta.workspaceId);
  }

  /// 异步触发索引任务
  void _queueIndexing(String documentId, String workspaceId) {
    // 将文档添加到索引队列
    IndexingService.instance.queueDocument(
      documentId,
      workspaceId,
      IndexTaskType.update,
    );
  }

  Future<void> _deleteDocumentChunks(String documentId) async {
    final query = _db.documentChunkBox
        .query(DocumentChunk_.documentId.equals(documentId))
        .build();
    final chunks = query.find();
    query.close();

    for (final chunk in chunks) {
      _db.documentChunkBox.remove(chunk.id);
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
      wordCount: 0,
      characterCount: 0,
      isFolder: true,
      sortOrder: await _getNextSortOrder(workspaceId, parentFolderId),
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
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
      case '.doc':
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
    final content = await getDocumentContent(documentId);
    if (content == null) {
      throw DocumentNotFoundException(documentId);
    }

    final docMeta = await getDocument(documentId);
    final title = docMeta?.title ?? 'document';
    final markdown =
        content.markdown.isNotEmpty ? content.markdown : content.plainText;

    switch (format) {
      case ExportFormat.markdown:
        return Uint8List.fromList(utf8.encode(markdown));
      case ExportFormat.html:
        final html = _convertToHtml(markdown, title);
        return Uint8List.fromList(utf8.encode(html));
      case ExportFormat.docx:
        return await _exportToDocx(markdown, title);
      case ExportFormat.pdf:
        return await _exportToPdf(markdown, title);
    }
  }

  String _convertToHtml(String content, String title) {
    var html = content
        .replaceAllMapped(
            RegExp(r'^### (.+)$', multiLine: true), (m) => '<h3>${m[1]}</h3>')
        .replaceAllMapped(
            RegExp(r'^## (.+)$', multiLine: true), (m) => '<h2>${m[1]}</h2>')
        .replaceAllMapped(
            RegExp(r'^# (.+)$', multiLine: true), (m) => '<h1>${m[1]}</h1>')
        .replaceAllMapped(
            RegExp(r'\*\*(.+?)\*\*'), (m) => '<strong>${m[1]}</strong>')
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => '<em>${m[1]}</em>')
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
    throw UnimplementedError('PDF export not yet implemented');
  }

  // ============ 查询方法 ============

  /// 获取工作空间的所有文档
  Future<List<DocumentMeta>> getDocumentsByWorkspace(String workspaceId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId))
        .order(DocumentMeta_.sortOrder)
        .build();
    final documents = query.find();
    query.close();
    return documents;
  }

  /// 获取单个文档元数据
  Future<DocumentMeta?> getDocument(String documentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final document = query.findFirst();
    query.close();
    return document;
  }

  /// 获取文档内容
  Future<DocumentContent?> getDocumentContent(String documentId) async {
    final query = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final content = query.findFirst();
    query.close();
    return content;
  }

  /// 获取文档纯文本内容（兼容旧接口）
  Future<String?> getDocumentPlainText(String documentId) async {
    final content = await getDocumentContent(documentId);
    return content?.plainText;
  }

  /// 获取最近访问的文档
  Future<List<DocumentMeta>> getRecentDocuments({int limit = 10}) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.isFolder.equals(false))
        .order(DocumentMeta_.lastAccessedAt, flags: Order.descending)
        .build();
    query.limit = limit;
    final documents = query.find();
    query.close();
    return documents;
  }

  /// 更新文档访问时间
  Future<void> updateLastAccessed(String documentId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.uuid.equals(documentId))
        .build();
    final docMeta = query.findFirst();
    query.close();

    if (docMeta != null) {
      final updatedMeta = docMeta.copyWith(
        lastAccessedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _db.documentMetaBox.put(updatedMeta);
    }
  }

  /// 重命名文档
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
  }

  /// 删除文档
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

    // 删除 DocumentContent
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final content = contentQuery.findFirst();
    contentQuery.close();
    if (content != null) {
      _db.documentContentBox.remove(content.id);
    }

    // 删除 DocumentChunks
    await _deleteDocumentChunks(documentId);

    // 删除 DocumentMeta
    _db.documentMetaBox.remove(docMeta.id);
  }

  Future<void> _deleteChildDocuments(String parentFolderId) async {
    final query = _db.documentMetaBox
        .query(DocumentMeta_.parentFolderId.equals(parentFolderId))
        .build();
    final children = query.find();
    query.close();

    for (final child in children) {
      await deleteDocument(child.uuid);
    }
  }

  /// 更新文档排序
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

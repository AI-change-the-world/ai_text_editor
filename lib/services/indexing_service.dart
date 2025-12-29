import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';

/// 索引状态
/// Requirements: 4.2
class IndexStatus {
  final int totalDocuments;
  final int indexedDocuments;
  final int pendingDocuments;
  final DateTime lastUpdated;
  final bool isIndexing;

  IndexStatus({
    required this.totalDocuments,
    required this.indexedDocuments,
    required this.pendingDocuments,
    required this.lastUpdated,
    required this.isIndexing,
  });

  /// 创建空状态
  factory IndexStatus.empty() => IndexStatus(
        totalDocuments: 0,
        indexedDocuments: 0,
        pendingDocuments: 0,
        lastUpdated: DateTime.now(),
        isIndexing: false,
      );
}

/// 索引任务
class IndexTask {
  final String documentId;
  final String workspaceId;
  final IndexTaskType type;
  final DateTime createdAt;

  IndexTask({
    required this.documentId,
    required this.workspaceId,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// 索引任务类型
enum IndexTaskType {
  add,
  update,
  remove,
}

/// 文档块
/// 用于向量索引的文档分块
class DocumentChunkData {
  final int index;
  final String text;
  final int startOffset;
  final int endOffset;

  DocumentChunkData({
    required this.index,
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });
}

/// 分块配置
class ChunkingConfig {
  /// 每个块的最大字符数
  final int maxChunkSize;

  /// 块之间的重叠字符数
  final int overlapSize;

  /// 最小块大小 (小于此大小的块会被合并)
  final int minChunkSize;

  const ChunkingConfig({
    this.maxChunkSize = 1000,
    this.overlapSize = 200,
    this.minChunkSize = 100,
  });

  /// 默认配置
  static const ChunkingConfig defaultConfig = ChunkingConfig();
}

/// 索引服务接口
/// Requirements: 4.2, 5.4
abstract class IIndexingService {
  /// 索引单个文档 (全文索引)
  /// Requirements: 4.2, 5.4
  Future<void> indexDocument(DocumentMeta document);

  /// 批量索引文档
  Future<void> indexDocuments(List<DocumentMeta> documents);

  /// 删除文档索引
  /// Requirements: 4.2
  Future<void> removeDocumentIndex(String documentId);

  /// 重建工作空间索引
  Future<void> rebuildWorkspaceIndex(String workspaceId);

  /// 获取索引状态
  Future<IndexStatus> getIndexStatus(String workspaceId);

  /// 将文档添加到索引队列
  void queueDocument(String documentId, String workspaceId, IndexTaskType type);

  /// 启动后台索引处理
  void startBackgroundIndexing();

  /// 停止后台索引处理
  void stopBackgroundIndexing();

  /// 获取队列中待处理的任务数量
  int get pendingTaskCount;

  /// 将文档内容分块
  /// Requirements: 4.2
  List<DocumentChunkData> chunkDocument(String content,
      {ChunkingConfig? config});

  /// 为文档创建向量索引块
  /// Requirements: 4.2
  Future<void> createDocumentChunks(DocumentMeta document,
      {ChunkingConfig? config});
}

/// 索引服务实现
/// Requirements: 4.2, 5.4
class IndexingService implements IIndexingService {
  final ObxDatabase _db;

  /// 后台索引队列
  final Queue<IndexTask> _indexQueue = Queue<IndexTask>();

  /// 是否正在处理索引
  bool _isProcessing = false;

  /// 后台处理定时器
  Timer? _processingTimer;

  /// 索引处理间隔 (毫秒)
  static const int _processingIntervalMs = 500;

  /// 批量处理大小
  static const int _batchSize = 10;

  /// 默认分块配置
  final ChunkingConfig _defaultChunkingConfig;

  IndexingService(this._db, {ChunkingConfig? chunkingConfig})
      : _defaultChunkingConfig = chunkingConfig ?? ChunkingConfig.defaultConfig;

  /// 获取单例实例
  static IndexingService? _instance;

  /// 获取单例实例（懒加载）
  static IndexingService get instance {
    _instance ??= IndexingService(ObxDatabase.db);
    return _instance!;
  }

  @override
  int get pendingTaskCount => _indexQueue.length;

  /// 将文档内容分块
  /// 使用滑动窗口方法，在段落边界处分割以保持语义完整性
  /// Requirements: 4.2
  @override
  List<DocumentChunkData> chunkDocument(String content,
      {ChunkingConfig? config}) {
    final cfg = config ?? _defaultChunkingConfig;
    final chunks = <DocumentChunkData>[];

    if (content.isEmpty) {
      return chunks;
    }

    // 按段落分割
    final paragraphs = _splitIntoParagraphs(content);

    int currentChunkStart = 0;
    int currentChunkEnd = 0;
    final currentChunkText = StringBuffer();
    int chunkIndex = 0;

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];

      // 如果当前块加上新段落超过最大大小
      if (currentChunkText.length + paragraph.text.length > cfg.maxChunkSize &&
          currentChunkText.isNotEmpty) {
        // 保存当前块
        chunks.add(DocumentChunkData(
          index: chunkIndex,
          text: currentChunkText.toString().trim(),
          startOffset: currentChunkStart,
          endOffset: currentChunkEnd,
        ));
        chunkIndex++;

        // 计算重叠部分的起始位置
        final overlapStart = _findOverlapStart(
          currentChunkText.toString(),
          cfg.overlapSize,
        );

        // 开始新块，包含重叠部分
        currentChunkStart = currentChunkEnd - overlapStart;
        currentChunkText.clear();
        if (overlapStart > 0) {
          final overlap = content.substring(
            currentChunkStart,
            currentChunkEnd,
          );
          currentChunkText.write(overlap);
        }
      }

      // 添加段落到当前块
      if (currentChunkText.isEmpty) {
        currentChunkStart = paragraph.startOffset;
      }
      currentChunkText.write(paragraph.text);
      currentChunkEnd = paragraph.endOffset;

      // 如果单个段落超过最大大小，需要进一步分割
      if (paragraph.text.length > cfg.maxChunkSize) {
        final subChunks = _splitLargeParagraph(
          paragraph.text,
          paragraph.startOffset,
          cfg,
          chunkIndex,
        );
        chunks.addAll(subChunks);
        chunkIndex += subChunks.length;
        currentChunkText.clear();
        currentChunkStart = paragraph.endOffset;
        currentChunkEnd = paragraph.endOffset;
      }
    }

    // 保存最后一个块
    if (currentChunkText.isNotEmpty) {
      final text = currentChunkText.toString().trim();
      if (text.length >= cfg.minChunkSize || chunks.isEmpty) {
        chunks.add(DocumentChunkData(
          index: chunkIndex,
          text: text,
          startOffset: currentChunkStart,
          endOffset: currentChunkEnd,
        ));
      } else if (chunks.isNotEmpty) {
        // 合并到前一个块
        final lastChunk = chunks.removeLast();
        chunks.add(DocumentChunkData(
          index: lastChunk.index,
          text: '${lastChunk.text}\n$text',
          startOffset: lastChunk.startOffset,
          endOffset: currentChunkEnd,
        ));
      }
    }

    return chunks;
  }

  /// 按段落分割文本
  List<_ParagraphInfo> _splitIntoParagraphs(String content) {
    final paragraphs = <_ParagraphInfo>[];
    final lines = content.split('\n');
    int offset = 0;

    final currentParagraph = StringBuffer();
    int paragraphStart = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineWithNewline = i < lines.length - 1 ? '$line\n' : line;

      if (line.trim().isEmpty) {
        // 空行表示段落结束
        if (currentParagraph.isNotEmpty) {
          paragraphs.add(_ParagraphInfo(
            text: currentParagraph.toString(),
            startOffset: paragraphStart,
            endOffset: offset,
          ));
          currentParagraph.clear();
        }
        offset += lineWithNewline.length;
        paragraphStart = offset;
      } else {
        if (currentParagraph.isEmpty) {
          paragraphStart = offset;
        }
        currentParagraph.write(lineWithNewline);
        offset += lineWithNewline.length;
      }
    }

    // 添加最后一个段落
    if (currentParagraph.isNotEmpty) {
      paragraphs.add(_ParagraphInfo(
        text: currentParagraph.toString(),
        startOffset: paragraphStart,
        endOffset: offset,
      ));
    }

    return paragraphs;
  }

  /// 分割大段落
  List<DocumentChunkData> _splitLargeParagraph(
    String text,
    int baseOffset,
    ChunkingConfig config,
    int startIndex,
  ) {
    final chunks = <DocumentChunkData>[];
    int index = startIndex;
    int start = 0;

    while (start < text.length) {
      int end = start + config.maxChunkSize;
      if (end >= text.length) {
        end = text.length;
      } else {
        // 尝试在句子边界处分割
        final sentenceEnd = _findSentenceEnd(text, start, end);
        if (sentenceEnd > start) {
          end = sentenceEnd;
        }
      }

      final chunkText = text.substring(start, end).trim();
      if (chunkText.isNotEmpty) {
        chunks.add(DocumentChunkData(
          index: index,
          text: chunkText,
          startOffset: baseOffset + start,
          endOffset: baseOffset + end,
        ));
        index++;
      }

      // 计算下一个块的起始位置（包含重叠）
      start = end - config.overlapSize;
      if (start < 0) start = 0;
      if (start >= text.length) break;
    }

    return chunks;
  }

  /// 查找句子结束位置
  int _findSentenceEnd(String text, int start, int maxEnd) {
    // 从 maxEnd 向前查找句子结束符
    final sentenceEnders = ['. ', '。', '! ', '！', '? ', '？', '\n'];

    for (int i = maxEnd - 1; i > start + 50; i--) {
      for (final ender in sentenceEnders) {
        if (i + ender.length <= text.length &&
            text.substring(i, i + ender.length) == ender) {
          return i + ender.length;
        }
      }
    }

    return maxEnd;
  }

  /// 查找重叠部分的起始位置
  int _findOverlapStart(String text, int overlapSize) {
    if (text.length <= overlapSize) {
      return text.length;
    }

    // 尝试在句子边界处开始重叠
    final startPos = text.length - overlapSize;
    final sentenceStarters = ['. ', '。', '! ', '！', '? ', '？', '\n'];

    for (int i = startPos; i < text.length - 10; i++) {
      for (final starter in sentenceStarters) {
        if (i + starter.length <= text.length &&
            text.substring(i, i + starter.length) == starter) {
          return text.length - (i + starter.length);
        }
      }
    }

    return overlapSize;
  }

  /// 为文档创建向量索引块
  /// Requirements: 4.2
  @override
  Future<void> createDocumentChunks(DocumentMeta document,
      {ChunkingConfig? config}) async {
    if (document.isFolder) {
      return;
    }

    // 获取文档内容
    final content = await _getDocumentContent(document);
    if (content == null || content.isEmpty) {
      return;
    }

    // 删除现有的块
    final existingQuery = _db.documentChunkBox
        .query(DocumentChunk_.documentId.equals(document.uuid))
        .build();
    final existingChunks = existingQuery.find();
    existingQuery.close();

    if (existingChunks.isNotEmpty) {
      _db.documentChunkBox.removeMany(existingChunks.map((c) => c.id).toList());
    }

    // 分块
    final chunks = chunkDocument(content, config: config);

    // 创建 DocumentChunk 实体
    final now = DateTime.now().millisecondsSinceEpoch;
    final chunkEntities = chunks.map((chunk) {
      return DocumentChunk(
        documentId: document.uuid,
        workspaceId: document.workspaceId,
        chunkIndex: chunk.index,
        chunkText: chunk.text,
        // embedding 将由 EmbeddingService 填充
        embedding: null,
        createdAt: now,
      );
    }).toList();

    // 批量保存
    _db.documentChunkBox.putMany(chunkEntities);
  }

  /// 索引单个文档 (全文索引)
  /// 将文档内容存储到 DocumentContent 表中以支持全文搜索
  /// Requirements: 4.2, 5.4
  @override
  Future<void> indexDocument(DocumentMeta document) async {
    if (document.isFolder) {
      // 文件夹不需要索引
      return;
    }

    // 获取文档内容
    final content = await _getDocumentContent(document);
    if (content == null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // 检查是否已存在索引
    final existingQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(document.uuid))
        .build();
    final existing = existingQuery.findFirst();
    existingQuery.close();

    if (existing != null) {
      // 更新现有索引
      final updated = existing.copyWith(
        title: document.title,
        content: content,
        tagsJson: document.tagsJson,
        updatedAt: now,
      );
      _db.documentContentBox.put(updated);
    } else {
      // 创建新索引
      final docContent = DocumentContent(
        documentId: document.uuid,
        workspaceId: document.workspaceId,
        title: document.title,
        content: content,
        tagsJson: document.tagsJson,
        updatedAt: now,
      );
      _db.documentContentBox.put(docContent);
    }
  }

  /// 获取文档内容
  Future<String?> _getDocumentContent(DocumentMeta document) async {
    if (document.filePath.isEmpty) {
      return null;
    }

    try {
      final file = File(document.filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      // 文件读取失败，返回 null
      return null;
    }
  }

  /// 批量索引文档
  @override
  Future<void> indexDocuments(List<DocumentMeta> documents) async {
    for (final document in documents) {
      await indexDocument(document);
    }
  }

  /// 删除文档索引
  /// Requirements: 4.2
  @override
  Future<void> removeDocumentIndex(String documentId) async {
    // 删除全文索引
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.documentId.equals(documentId))
        .build();
    final content = contentQuery.findFirst();
    contentQuery.close();

    if (content != null) {
      _db.documentContentBox.remove(content.id);
    }

    // 删除向量索引 (DocumentChunk)
    final chunkQuery = _db.documentChunkBox
        .query(DocumentChunk_.documentId.equals(documentId))
        .build();
    final chunks = chunkQuery.find();
    chunkQuery.close();

    if (chunks.isNotEmpty) {
      _db.documentChunkBox.removeMany(chunks.map((c) => c.id).toList());
    }
  }

  /// 重建工作空间索引
  @override
  Future<void> rebuildWorkspaceIndex(String workspaceId) async {
    // 删除工作空间的所有索引
    await _clearWorkspaceIndex(workspaceId);

    // 获取工作空间的所有文档
    final docQuery = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId) &
            DocumentMeta_.isFolder.equals(false))
        .build();
    final documents = docQuery.find();
    docQuery.close();

    // 重新索引所有文档
    await indexDocuments(documents);
  }

  /// 清除工作空间的所有索引
  Future<void> _clearWorkspaceIndex(String workspaceId) async {
    // 清除全文索引
    final contentQuery = _db.documentContentBox
        .query(DocumentContent_.workspaceId.equals(workspaceId))
        .build();
    final contents = contentQuery.find();
    contentQuery.close();

    if (contents.isNotEmpty) {
      _db.documentContentBox.removeMany(contents.map((c) => c.id).toList());
    }

    // 清除向量索引
    final chunkQuery = _db.documentChunkBox
        .query(DocumentChunk_.workspaceId.equals(workspaceId))
        .build();
    final chunks = chunkQuery.find();
    chunkQuery.close();

    if (chunks.isNotEmpty) {
      _db.documentChunkBox.removeMany(chunks.map((c) => c.id).toList());
    }
  }

  /// 获取索引状态
  @override
  Future<IndexStatus> getIndexStatus(String workspaceId) async {
    // 获取工作空间的文档总数
    final docQuery = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId) &
            DocumentMeta_.isFolder.equals(false))
        .build();
    final totalDocuments = docQuery.count();
    docQuery.close();

    // 获取已索引的文档数
    final indexedQuery = _db.documentContentBox
        .query(DocumentContent_.workspaceId.equals(workspaceId))
        .build();
    final indexedDocuments = indexedQuery.count();
    indexedQuery.close();

    // 计算待索引的文档数
    final pendingInQueue = _indexQueue
        .where((task) =>
            task.workspaceId == workspaceId &&
            task.type != IndexTaskType.remove)
        .length;

    return IndexStatus(
      totalDocuments: totalDocuments,
      indexedDocuments: indexedDocuments,
      pendingDocuments: pendingInQueue,
      lastUpdated: DateTime.now(),
      isIndexing: _isProcessing,
    );
  }

  /// 将文档添加到索引队列
  /// Requirements: 4.2
  @override
  void queueDocument(
      String documentId, String workspaceId, IndexTaskType type) {
    // 检查是否已在队列中
    final existingIndex = _indexQueue.toList().indexWhere(
        (task) => task.documentId == documentId && task.type == type);

    if (existingIndex == -1) {
      _indexQueue.add(IndexTask(
        documentId: documentId,
        workspaceId: workspaceId,
        type: type,
      ));
    }
  }

  /// 启动后台索引处理
  /// Requirements: 4.2
  @override
  void startBackgroundIndexing() {
    if (_processingTimer != null) {
      return; // 已经在运行
    }

    _processingTimer = Timer.periodic(
      Duration(milliseconds: _processingIntervalMs),
      (_) => _processQueue(),
    );
  }

  /// 停止后台索引处理
  @override
  void stopBackgroundIndexing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// 处理索引队列
  Future<void> _processQueue() async {
    if (_isProcessing || _indexQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      // 批量处理任务
      final tasksToProcess = <IndexTask>[];
      while (_indexQueue.isNotEmpty && tasksToProcess.length < _batchSize) {
        tasksToProcess.add(_indexQueue.removeFirst());
      }

      for (final task in tasksToProcess) {
        await _processTask(task);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 处理单个索引任务
  Future<void> _processTask(IndexTask task) async {
    switch (task.type) {
      case IndexTaskType.add:
      case IndexTaskType.update:
        final docQuery = _db.documentMetaBox
            .query(DocumentMeta_.uuid.equals(task.documentId))
            .build();
        final document = docQuery.findFirst();
        docQuery.close();

        if (document != null) {
          // 创建全文索引
          await indexDocument(document);
          // 创建向量索引块 (embedding 将由 EmbeddingService 填充)
          await createDocumentChunks(document);
        }
        break;

      case IndexTaskType.remove:
        await removeDocumentIndex(task.documentId);
        break;
    }
  }
}

/// 段落信息
class _ParagraphInfo {
  final String text;
  final int startOffset;
  final int endOffset;

  _ParagraphInfo({
    required this.text,
    required this.startOffset,
    required this.endOffset,
  });
}

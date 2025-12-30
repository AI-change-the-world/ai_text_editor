import 'dart:math';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';
import 'embedding_service.dart';

/// 搜索过滤器
/// Requirements: 5.7
class SearchFilters {
  /// 工作空间 ID 列表 (空表示当前工作空间)
  final List<String> workspaceIds;

  /// 日期范围 - 开始时间
  final DateTime? dateFrom;

  /// 日期范围 - 结束时间
  final DateTime? dateTo;

  /// 标签过滤
  final List<String> tags;

  /// 文件类型过滤
  final List<String> fileTypes;

  const SearchFilters({
    this.workspaceIds = const [],
    this.dateFrom,
    this.dateTo,
    this.tags = const [],
    this.fileTypes = const [],
  });

  /// 创建空过滤器
  static const SearchFilters empty = SearchFilters();

  /// 复制并修改
  SearchFilters copyWith({
    List<String>? workspaceIds,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? tags,
    List<String>? fileTypes,
  }) {
    return SearchFilters(
      workspaceIds: workspaceIds ?? this.workspaceIds,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      tags: tags ?? this.tags,
      fileTypes: fileTypes ?? this.fileTypes,
    );
  }
}

/// 搜索结果项
/// Requirements: 5.4, 5.5
class SearchResultItem {
  /// 工作空间 ID
  final String workspaceId;

  /// 工作空间名称
  final String workspaceName;

  /// 文档 ID
  final String documentId;

  /// 文档标题
  final String documentTitle;

  /// 文档路径
  final String documentPath;

  /// 匹配片段
  final String snippet;

  /// 高亮位置列表 [start, end, start, end, ...]
  final List<int> highlightRanges;

  /// 相关性分数
  final double score;

  /// 最后修改时间
  final DateTime lastModified;

  /// 标签
  final List<String> tags;

  SearchResultItem({
    required this.workspaceId,
    required this.workspaceName,
    required this.documentId,
    required this.documentTitle,
    required this.documentPath,
    required this.snippet,
    this.highlightRanges = const [],
    required this.score,
    required this.lastModified,
    this.tags = const [],
  });
}

/// 搜索结果
/// Requirements: 5.4, 5.5
class SearchResult {
  /// 搜索结果项列表
  final List<SearchResultItem> items;

  /// 总结果数
  final int totalCount;

  /// 按工作空间分组的数量
  final Map<String, int> workspaceCounts;

  /// 搜索耗时 (毫秒)
  final int searchTimeMs;

  SearchResult({
    required this.items,
    required this.totalCount,
    required this.workspaceCounts,
    this.searchTimeMs = 0,
  });

  /// 创建空结果
  factory SearchResult.empty() => SearchResult(
        items: [],
        totalCount: 0,
        workspaceCounts: {},
      );
}

/// 搜索建议
class SearchSuggestion {
  /// 建议类型
  final SearchSuggestionType type;

  /// 建议文本
  final String text;

  /// 相关性分数
  final double score;

  SearchSuggestion({
    required this.type,
    required this.text,
    required this.score,
  });
}

/// 搜索建议类型
enum SearchSuggestionType {
  documentTitle,
  tag,
  recentSearch,
}

/// 保存的搜索
class SavedSearchQuery {
  final int id;
  final String name;
  final String query;
  final SearchFilters? filters;
  final DateTime createdAt;
  final int usedCount;
  final DateTime lastUsedAt;

  SavedSearchQuery({
    required this.id,
    required this.name,
    required this.query,
    this.filters,
    required this.createdAt,
    required this.usedCount,
    required this.lastUsedAt,
  });
}

/// 高级搜索查询解析结果
/// Requirements: 5.8
class ParsedSearchQuery {
  /// 必须包含的词 (AND)
  final List<String> mustTerms;

  /// 可选包含的词 (OR)
  final List<String> shouldTerms;

  /// 必须排除的词 (NOT)
  final List<String> mustNotTerms;

  /// 精确匹配短语 (引号内)
  final List<String> phrases;

  /// 工作空间过滤 (workspace:name)
  final List<String> workspaceFilters;

  /// 标签过滤 (tag:name)
  final List<String> tagFilters;

  /// 原始查询
  final String originalQuery;

  /// 是否为高级查询
  final bool isAdvanced;

  ParsedSearchQuery({
    this.mustTerms = const [],
    this.shouldTerms = const [],
    this.mustNotTerms = const [],
    this.phrases = const [],
    this.workspaceFilters = const [],
    this.tagFilters = const [],
    required this.originalQuery,
    this.isAdvanced = false,
  });

  /// 获取所有搜索词 (用于简单搜索)
  List<String> get allTerms => [
        ...mustTerms,
        ...shouldTerms,
        ...phrases,
      ];

  /// 是否为空查询
  bool get isEmpty =>
      mustTerms.isEmpty &&
      shouldTerms.isEmpty &&
      mustNotTerms.isEmpty &&
      phrases.isEmpty;
}

/// 搜索服务接口
/// Requirements: 4.3, 5.4, 5.5, 5.8
abstract class ISearchService {
  /// 全文搜索
  /// Requirements: 5.4
  Future<SearchResult> fullTextSearch(
    String query, {
    List<String> workspaceIds,
    SearchFilters? filters,
    int limit,
    int offset,
  });

  /// 语义搜索 (向量检索)
  /// Requirements: 4.3
  Future<SearchResult> semanticSearch(
    String query, {
    List<String> workspaceIds,
    SearchFilters? filters,
    int limit,
    double similarityThreshold,
  });

  /// 混合搜索 (全文 + 语义)
  /// Requirements: 4.3, 5.4
  Future<SearchResult> hybridSearch(
    String query, {
    List<String> workspaceIds,
    SearchFilters? filters,
    int limit,
    double semanticWeight,
  });

  /// 跨工作空间搜索
  /// Requirements: 4.6, 5.5
  Future<SearchResult> crossWorkspaceSearch(
    String query, {
    required List<String> workspaceIds,
    SearchFilters? filters,
    int limit,
  });

  /// 解析高级搜索语法
  /// Requirements: 5.8
  ParsedSearchQuery parseAdvancedQuery(String query);

  /// 高亮搜索结果
  /// Requirements: 5.4
  String highlightMatches(String text, List<String> terms,
      {String highlightStart, String highlightEnd});

  /// 获取高亮位置
  List<int> getHighlightRanges(String text, List<String> terms);

  /// 获取搜索建议
  Future<List<SearchSuggestion>> getSuggestions(
    String query, {
    String? workspaceId,
    int limit,
  });

  /// 保存搜索查询
  Future<void> saveSearchQuery(String query, String name,
      {SearchFilters? filters});

  /// 获取已保存的搜索
  Future<List<SavedSearchQuery>> getSavedSearches();

  /// 删除已保存的搜索
  Future<void> deleteSavedSearch(int id);
}

/// 搜索服务实现
/// Requirements: 4.3, 5.4, 5.5, 5.8
class SearchService implements ISearchService {
  final ObxDatabase _db;
  final IEmbeddingService _embeddingService;

  /// 工作空间名称缓存
  final Map<String, String> _workspaceNameCache = {};

  SearchService(this._db, this._embeddingService);

  /// 获取单例实例
  static SearchService? _instance;

  /// 获取单例实例（懒加载）
  static SearchService get instance {
    _instance ??= SearchService(ObxDatabase.db, EmbeddingService.instance);
    return _instance!;
  }

  /// 重置单例 (用于测试)
  static void resetInstance() {
    _instance = null;
  }

  /// 获取工作空间名称
  String _getWorkspaceName(String workspaceId) {
    if (_workspaceNameCache.containsKey(workspaceId)) {
      return _workspaceNameCache[workspaceId]!;
    }

    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();
    final workspace = query.findFirst();
    query.close();

    final name = workspace?.name ?? 'Unknown';
    _workspaceNameCache[workspaceId] = name;
    return name;
  }

  /// 清除工作空间名称缓存
  void clearWorkspaceNameCache() {
    _workspaceNameCache.clear();
  }

  /// 全文搜索
  /// Requirements: 5.4
  @override
  Future<SearchResult> fullTextSearch(
    String query, {
    List<String> workspaceIds = const [],
    SearchFilters? filters,
    int limit = 20,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (query.trim().isEmpty) {
      return SearchResult.empty();
    }

    // 解析高级查询语法
    final parsedQuery = parseAdvancedQuery(query);

    // 合并工作空间过滤
    final effectiveWorkspaceIds = {
      ...workspaceIds,
      ...parsedQuery.workspaceFilters,
      ...(filters?.workspaceIds ?? []),
    }.toList();

    // 合并标签过滤
    final effectiveTags = {
      ...parsedQuery.tagFilters,
      ...(filters?.tags ?? []),
    }.toList();

    // 构建查询条件
    QueryBuilder<DocumentContent> queryBuilder;

    if (effectiveWorkspaceIds.isNotEmpty) {
      queryBuilder = _db.documentContentBox
          .query(DocumentContent_.workspaceId.oneOf(effectiveWorkspaceIds));
    } else {
      queryBuilder = _db.documentContentBox.query();
    }

    final dbQuery = queryBuilder.build();
    final allDocs = dbQuery.find();
    dbQuery.close();

    // 获取文档元数据用于标签过滤
    final docMetaMap = <String, DocumentMeta>{};
    for (final doc in allDocs) {
      final metaQuery = _db.documentMetaBox
          .query(DocumentMeta_.uuid.equals(doc.documentId))
          .build();
      final meta = metaQuery.findFirst();
      metaQuery.close();
      if (meta != null) {
        docMetaMap[doc.documentId] = meta;
      }
    }

    // 过滤和评分
    final scoredResults = <_ScoredDocument>[];

    for (final doc in allDocs) {
      final meta = docMetaMap[doc.documentId];

      // 应用标签过滤
      if (effectiveTags.isNotEmpty && meta != null) {
        final docTags = meta.tags;
        if (!effectiveTags.any((tag) => docTags.contains(tag))) {
          continue;
        }
      }

      // 应用日期过滤
      if (filters?.dateFrom != null) {
        final docDate = DateTime.fromMillisecondsSinceEpoch(doc.updatedAt);
        if (docDate.isBefore(filters!.dateFrom!)) {
          continue;
        }
      }
      if (filters?.dateTo != null) {
        final docDate = DateTime.fromMillisecondsSinceEpoch(doc.updatedAt);
        if (docDate.isAfter(filters!.dateTo!)) {
          continue;
        }
      }

      // 计算匹配分数
      final score = _calculateFullTextScore(doc, meta, parsedQuery);

      if (score > 0) {
        scoredResults.add(_ScoredDocument(doc, score));
      }
    }

    // 按分数排序
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    // 计算工作空间分组
    final workspaceCounts = <String, int>{};
    for (final result in scoredResults) {
      final wsId = result.doc.workspaceId;
      workspaceCounts[wsId] = (workspaceCounts[wsId] ?? 0) + 1;
    }

    // 分页
    final totalCount = scoredResults.length;
    final pagedResults = scoredResults.skip(offset).take(limit).toList();

    // 转换为搜索结果项
    final items = pagedResults.map((result) {
      final doc = result.doc;
      final meta = docMetaMap[doc.documentId];
      final searchTerms = parsedQuery.allTerms;

      // 生成摘要片段
      final snippet = _generateSnippet(doc.plainText, searchTerms);
      final highlightRanges = getHighlightRanges(snippet, searchTerms);

      return SearchResultItem(
        workspaceId: doc.workspaceId,
        workspaceName: _getWorkspaceName(doc.workspaceId),
        documentId: doc.documentId,
        documentTitle: meta?.title ?? doc.documentId,
        documentPath: doc.documentId,
        snippet: snippet,
        highlightRanges: highlightRanges,
        score: result.score,
        lastModified: DateTime.fromMillisecondsSinceEpoch(doc.updatedAt),
        tags: meta?.tags ?? [],
      );
    }).toList();

    stopwatch.stop();

    return SearchResult(
      items: items,
      totalCount: totalCount,
      workspaceCounts: workspaceCounts,
      searchTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 计算全文搜索分数
  double _calculateFullTextScore(
      DocumentContent doc, DocumentMeta? meta, ParsedSearchQuery parsedQuery) {
    double score = 0.0;
    final titleLower = (meta?.title ?? '').toLowerCase();
    final contentLower = doc.plainText.toLowerCase();

    // 检查必须排除的词
    for (final term in parsedQuery.mustNotTerms) {
      final termLower = term.toLowerCase();
      if (titleLower.contains(termLower) || contentLower.contains(termLower)) {
        return 0.0; // 包含排除词，分数为 0
      }
    }

    // 检查必须包含的词
    for (final term in parsedQuery.mustTerms) {
      final termLower = term.toLowerCase();
      if (!titleLower.contains(termLower) &&
          !contentLower.contains(termLower)) {
        return 0.0; // 缺少必须词，分数为 0
      }
      // 标题匹配权重更高
      if (titleLower.contains(termLower)) {
        score += 10.0;
      }
      if (contentLower.contains(termLower)) {
        score += 1.0 * _countOccurrences(contentLower, termLower);
      }
    }

    // 检查精确短语
    for (final phrase in parsedQuery.phrases) {
      final phraseLower = phrase.toLowerCase();
      if (titleLower.contains(phraseLower)) {
        score += 20.0;
      }
      if (contentLower.contains(phraseLower)) {
        score += 5.0 * _countOccurrences(contentLower, phraseLower);
      }
    }

    // 检查可选词 (OR)
    for (final term in parsedQuery.shouldTerms) {
      final termLower = term.toLowerCase();
      if (titleLower.contains(termLower)) {
        score += 5.0;
      }
      if (contentLower.contains(termLower)) {
        score += 0.5 * _countOccurrences(contentLower, termLower);
      }
    }

    // 如果没有高级语法，使用简单匹配
    if (!parsedQuery.isAdvanced && parsedQuery.allTerms.isEmpty) {
      final queryLower = parsedQuery.originalQuery.toLowerCase();
      if (titleLower.contains(queryLower)) {
        score += 10.0;
      }
      if (contentLower.contains(queryLower)) {
        score += 1.0 * _countOccurrences(contentLower, queryLower);
      }
    }

    return score;
  }

  /// 计算字符串出现次数
  int _countOccurrences(String text, String pattern) {
    if (pattern.isEmpty) return 0;
    int count = 0;
    int index = 0;
    while ((index = text.indexOf(pattern, index)) != -1) {
      count++;
      index += pattern.length;
    }
    return min(count, 10); // 限制最大计数，避免过度加权
  }

  /// 生成摘要片段
  String _generateSnippet(String content, List<String> terms,
      {int maxLength = 200}) {
    if (content.isEmpty) return '';
    if (terms.isEmpty) {
      return content.length > maxLength
          ? '${content.substring(0, maxLength)}...'
          : content;
    }

    final contentLower = content.toLowerCase();

    // 找到第一个匹配词的位置
    int firstMatchIndex = content.length;
    for (final term in terms) {
      final index = contentLower.indexOf(term.toLowerCase());
      if (index != -1 && index < firstMatchIndex) {
        firstMatchIndex = index;
      }
    }

    if (firstMatchIndex == content.length) {
      // 没有找到匹配，返回开头
      return content.length > maxLength
          ? '${content.substring(0, maxLength)}...'
          : content;
    }

    // 计算摘要的起始和结束位置
    int start = max(0, firstMatchIndex - 50);
    int end = min(content.length, start + maxLength);

    // 调整到词边界
    if (start > 0) {
      final spaceIndex = content.indexOf(' ', start);
      if (spaceIndex != -1 && spaceIndex < start + 20) {
        start = spaceIndex + 1;
      }
    }

    String snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }

  /// 语义搜索 (向量检索)
  /// Requirements: 4.3
  @override
  Future<SearchResult> semanticSearch(
    String query, {
    List<String> workspaceIds = const [],
    SearchFilters? filters,
    int limit = 10,
    double similarityThreshold = 0.7,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (query.trim().isEmpty) {
      return SearchResult.empty();
    }

    // 获取查询的嵌入向量
    List<double> queryEmbedding;
    try {
      queryEmbedding = await _embeddingService.getEmbedding(query);
    } catch (e) {
      // 嵌入服务失败，返回空结果
      return SearchResult.empty();
    }

    // 合并工作空间过滤
    final effectiveWorkspaceIds = {
      ...workspaceIds,
      ...(filters?.workspaceIds ?? []),
    }.toList();

    // 查询向量索引 - 使用 ObjectBox HNSW 向量搜索
    List<DocumentChunk> chunks;

    // 首先使用向量搜索获取候选结果
    final vectorQuery = _db.documentChunkBox
        .query(
          DocumentChunk_.embedding
              .nearestNeighborsF32(queryEmbedding, limit * 3),
        )
        .build();
    final allChunks = vectorQuery.find();
    vectorQuery.close();

    // 然后根据工作空间过滤
    if (effectiveWorkspaceIds.isNotEmpty) {
      chunks = allChunks
          .where((c) => effectiveWorkspaceIds.contains(c.workspaceId))
          .toList();
    } else {
      chunks = allChunks;
    }

    // 计算相似度并过滤
    final scoredChunks = <_ScoredChunk>[];
    for (final chunk in chunks) {
      if (chunk.embedding == null || chunk.embedding!.isEmpty) continue;

      final similarity = _cosineSimilarity(queryEmbedding, chunk.embedding!);
      if (similarity >= similarityThreshold) {
        scoredChunks.add(_ScoredChunk(chunk, similarity));
      }
    }

    // 按相似度排序
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    // 去重 (同一文档只保留最高分的块)
    final seenDocuments = <String>{};
    final uniqueChunks = <_ScoredChunk>[];
    for (final chunk in scoredChunks) {
      if (!seenDocuments.contains(chunk.chunk.documentId)) {
        seenDocuments.add(chunk.chunk.documentId);
        uniqueChunks.add(chunk);
      }
    }

    // 应用过滤器
    final filteredChunks = _applyFiltersToChunks(uniqueChunks, filters);

    // 计算工作空间分组
    final workspaceCounts = <String, int>{};
    for (final chunk in filteredChunks) {
      final wsId = chunk.chunk.workspaceId;
      workspaceCounts[wsId] = (workspaceCounts[wsId] ?? 0) + 1;
    }

    // 限制结果数量
    final limitedChunks = filteredChunks.take(limit).toList();

    // 转换为搜索结果项
    final items = await _chunksToSearchResults(limitedChunks, [query]);

    stopwatch.stop();

    return SearchResult(
      items: items,
      totalCount: filteredChunks.length,
      workspaceCounts: workspaceCounts,
      searchTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 计算余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// 应用过滤器到块结果
  List<_ScoredChunk> _applyFiltersToChunks(
      List<_ScoredChunk> chunks, SearchFilters? filters) {
    if (filters == null) return chunks;

    return chunks.where((chunk) {
      // 日期过滤需要获取文档元数据
      // 这里简化处理，实际应该查询 DocumentMeta
      return true;
    }).toList();
  }

  /// 将块结果转换为搜索结果项
  Future<List<SearchResultItem>> _chunksToSearchResults(
      List<_ScoredChunk> chunks, List<String> searchTerms) async {
    final items = <SearchResultItem>[];

    for (final scoredChunk in chunks) {
      final chunk = scoredChunk.chunk;

      // 获取文档元数据
      final docQuery = _db.documentMetaBox
          .query(DocumentMeta_.uuid.equals(chunk.documentId))
          .build();
      final docMeta = docQuery.findFirst();
      docQuery.close();

      final highlightRanges = getHighlightRanges(chunk.chunkText, searchTerms);

      items.add(SearchResultItem(
        workspaceId: chunk.workspaceId,
        workspaceName: _getWorkspaceName(chunk.workspaceId),
        documentId: chunk.documentId,
        documentTitle: docMeta?.title ?? 'Unknown',
        documentPath: chunk.documentId,
        snippet: chunk.chunkText.length > 200
            ? '${chunk.chunkText.substring(0, 200)}...'
            : chunk.chunkText,
        highlightRanges: highlightRanges,
        score: scoredChunk.score,
        lastModified: docMeta != null
            ? DateTime.fromMillisecondsSinceEpoch(docMeta.updatedAt)
            : DateTime.now(),
        tags: docMeta?.tags ?? [],
      ));
    }

    return items;
  }

  /// 混合搜索 (全文 + 语义)
  /// Requirements: 4.3, 5.4
  @override
  Future<SearchResult> hybridSearch(
    String query, {
    List<String> workspaceIds = const [],
    SearchFilters? filters,
    int limit = 20,
    double semanticWeight = 0.5,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (query.trim().isEmpty) {
      return SearchResult.empty();
    }

    // 并行执行全文搜索和语义搜索
    final fullTextFuture = fullTextSearch(
      query,
      workspaceIds: workspaceIds,
      filters: filters,
      limit: limit * 2,
    );

    final semanticFuture = semanticSearch(
      query,
      workspaceIds: workspaceIds,
      filters: filters,
      limit: limit * 2,
    );

    final results = await Future.wait([fullTextFuture, semanticFuture]);
    final fullTextResult = results[0];
    final semanticResult = results[1];

    // 合并结果
    final mergedScores = <String, _MergedScore>{};

    // 添加全文搜索结果
    for (final item in fullTextResult.items) {
      mergedScores[item.documentId] = _MergedScore(
        item: item,
        fullTextScore: item.score,
        semanticScore: 0.0,
      );
    }

    // 添加语义搜索结果
    for (final item in semanticResult.items) {
      if (mergedScores.containsKey(item.documentId)) {
        mergedScores[item.documentId]!.semanticScore = item.score;
      } else {
        mergedScores[item.documentId] = _MergedScore(
          item: item,
          fullTextScore: 0.0,
          semanticScore: item.score,
        );
      }
    }

    // 计算混合分数
    final sortedResults = mergedScores.values.toList();
    for (final result in sortedResults) {
      result.calculateHybridScore(semanticWeight);
    }
    sortedResults.sort((a, b) => b.hybridScore.compareTo(a.hybridScore));

    // 计算工作空间分组
    final workspaceCounts = <String, int>{};
    for (final result in sortedResults) {
      final wsId = result.item.workspaceId;
      workspaceCounts[wsId] = (workspaceCounts[wsId] ?? 0) + 1;
    }

    // 限制结果数量
    final limitedResults = sortedResults.take(limit).toList();

    // 更新分数为混合分数
    final items = limitedResults.map((result) {
      return SearchResultItem(
        workspaceId: result.item.workspaceId,
        workspaceName: result.item.workspaceName,
        documentId: result.item.documentId,
        documentTitle: result.item.documentTitle,
        documentPath: result.item.documentPath,
        snippet: result.item.snippet,
        highlightRanges: result.item.highlightRanges,
        score: result.hybridScore,
        lastModified: result.item.lastModified,
        tags: result.item.tags,
      );
    }).toList();

    stopwatch.stop();

    return SearchResult(
      items: items,
      totalCount: sortedResults.length,
      workspaceCounts: workspaceCounts,
      searchTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 跨工作空间搜索
  /// Requirements: 4.6, 5.5
  @override
  Future<SearchResult> crossWorkspaceSearch(
    String query, {
    required List<String> workspaceIds,
    SearchFilters? filters,
    int limit = 20,
  }) async {
    if (workspaceIds.isEmpty) {
      // 如果没有指定工作空间，搜索所有工作空间
      final allWorkspacesQuery =
          _db.workspaceBox.query(Workspace_.isArchived.equals(false)).build();
      final allWorkspaces = allWorkspacesQuery.find();
      allWorkspacesQuery.close();

      workspaceIds = allWorkspaces.map((w) => w.uuid).toList();
    }

    // 使用混合搜索进行跨工作空间搜索
    return hybridSearch(
      query,
      workspaceIds: workspaceIds,
      filters: filters,
      limit: limit,
    );
  }

  /// 解析高级搜索语法
  /// 支持: AND, OR, NOT, "精确短语", workspace:name, tag:name
  /// Requirements: 5.8
  @override
  ParsedSearchQuery parseAdvancedQuery(String query) {
    if (query.trim().isEmpty) {
      return ParsedSearchQuery(originalQuery: query);
    }

    final mustTerms = <String>[];
    final shouldTerms = <String>[];
    final mustNotTerms = <String>[];
    final phrases = <String>[];
    final workspaceFilters = <String>[];
    final tagFilters = <String>[];

    bool isAdvanced = false;

    // 提取引号内的精确短语
    final phraseRegex = RegExp(r'"([^"]+)"');
    final phraseMatches = phraseRegex.allMatches(query);
    for (final match in phraseMatches) {
      phrases.add(match.group(1)!);
      isAdvanced = true;
    }

    // 移除已提取的短语
    String remainingQuery = query.replaceAll(phraseRegex, ' ');

    // 提取 workspace: 过滤器
    final workspaceRegex = RegExp(r'workspace:(\S+)', caseSensitive: false);
    final workspaceMatches = workspaceRegex.allMatches(remainingQuery);
    for (final match in workspaceMatches) {
      workspaceFilters.add(match.group(1)!);
      isAdvanced = true;
    }
    remainingQuery = remainingQuery.replaceAll(workspaceRegex, ' ');

    // 提取 tag: 过滤器
    final tagRegex = RegExp(r'tag:(\S+)', caseSensitive: false);
    final tagMatches = tagRegex.allMatches(remainingQuery);
    for (final match in tagMatches) {
      tagFilters.add(match.group(1)!);
      isAdvanced = true;
    }
    remainingQuery = remainingQuery.replaceAll(tagRegex, ' ');

    // 分割剩余的词
    final tokens = remainingQuery.split(RegExp(r'\s+'));

    bool nextIsNot = false;
    bool nextIsOr = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i].trim();
      if (token.isEmpty) continue;

      final tokenUpper = token.toUpperCase();

      if (tokenUpper == 'AND') {
        isAdvanced = true;
        continue;
      }

      if (tokenUpper == 'OR') {
        nextIsOr = true;
        isAdvanced = true;
        continue;
      }

      if (tokenUpper == 'NOT' || token == '-') {
        nextIsNot = true;
        isAdvanced = true;
        continue;
      }

      // 处理 -term 形式的排除
      if (token.startsWith('-') && token.length > 1) {
        mustNotTerms.add(token.substring(1));
        isAdvanced = true;
        continue;
      }

      // 处理 +term 形式的必须包含
      if (token.startsWith('+') && token.length > 1) {
        mustTerms.add(token.substring(1));
        isAdvanced = true;
        continue;
      }

      if (nextIsNot) {
        mustNotTerms.add(token);
        nextIsNot = false;
      } else if (nextIsOr) {
        shouldTerms.add(token);
        nextIsOr = false;
      } else {
        mustTerms.add(token);
      }
    }

    return ParsedSearchQuery(
      mustTerms: mustTerms,
      shouldTerms: shouldTerms,
      mustNotTerms: mustNotTerms,
      phrases: phrases,
      workspaceFilters: workspaceFilters,
      tagFilters: tagFilters,
      originalQuery: query,
      isAdvanced: isAdvanced,
    );
  }

  /// 高亮搜索结果
  /// Requirements: 5.4
  @override
  String highlightMatches(
    String text,
    List<String> terms, {
    String highlightStart = '<mark>',
    String highlightEnd = '</mark>',
  }) {
    if (text.isEmpty || terms.isEmpty) return text;

    String result = text;

    // 按长度降序排序，先匹配长的词
    final sortedTerms = List<String>.from(terms)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final term in sortedTerms) {
      if (term.isEmpty) continue;

      final termLower = term.toLowerCase();
      final regex = RegExp(RegExp.escape(termLower), caseSensitive: false);

      result = result.replaceAllMapped(regex, (match) {
        return '$highlightStart${match.group(0)}$highlightEnd';
      });
    }

    return result;
  }

  /// 获取高亮位置
  /// 返回 [start1, end1, start2, end2, ...] 格式的位置列表
  /// Requirements: 5.4
  @override
  List<int> getHighlightRanges(String text, List<String> terms) {
    if (text.isEmpty || terms.isEmpty) return [];

    final ranges = <int>[];
    final textLower = text.toLowerCase();

    for (final term in terms) {
      if (term.isEmpty) continue;

      final termLower = term.toLowerCase();
      int index = 0;

      while ((index = textLower.indexOf(termLower, index)) != -1) {
        ranges.add(index);
        ranges.add(index + term.length);
        index += term.length;
      }
    }

    // 按起始位置排序
    if (ranges.length >= 2) {
      final pairs = <List<int>>[];
      for (int i = 0; i < ranges.length; i += 2) {
        pairs.add([ranges[i], ranges[i + 1]]);
      }
      pairs.sort((a, b) => a[0].compareTo(b[0]));

      ranges.clear();
      for (final pair in pairs) {
        ranges.addAll(pair);
      }
    }

    return ranges;
  }

  /// 获取搜索建议
  @override
  Future<List<SearchSuggestion>> getSuggestions(
    String query, {
    String? workspaceId,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final suggestions = <SearchSuggestion>[];
    final queryLower = query.toLowerCase();

    // 搜索文档标题 - 从 DocumentMeta 获取
    QueryBuilder<DocumentMeta> metaQueryBuilder;
    if (workspaceId != null) {
      metaQueryBuilder = _db.documentMetaBox.query(
        DocumentMeta_.workspaceId.equals(workspaceId) &
            DocumentMeta_.title.contains(query, caseSensitive: false),
      );
    } else {
      metaQueryBuilder = _db.documentMetaBox.query(
        DocumentMeta_.title.contains(query, caseSensitive: false),
      );
    }

    final metaQuery = metaQueryBuilder.build();
    final docs = metaQuery.find();
    metaQuery.close();

    for (final doc in docs.take(limit ~/ 2)) {
      final titleLower = doc.title.toLowerCase();
      final score = titleLower.startsWith(queryLower) ? 1.0 : 0.5;

      suggestions.add(SearchSuggestion(
        type: SearchSuggestionType.documentTitle,
        text: doc.title,
        score: score,
      ));
    }

    // 搜索标签 - 从 DocumentMeta 获取
    final allTags = <String>{};
    final allMetaQuery = _db.documentMetaBox.query().build();
    final allMetas = allMetaQuery.find();
    allMetaQuery.close();

    for (final meta in allMetas) {
      allTags.addAll(meta.tags);
    }

    for (final tag in allTags) {
      if (tag.toLowerCase().contains(queryLower)) {
        suggestions.add(SearchSuggestion(
          type: SearchSuggestionType.tag,
          text: tag,
          score: tag.toLowerCase().startsWith(queryLower) ? 0.8 : 0.4,
        ));
      }
    }

    // 按分数排序并限制数量
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(limit).toList();
  }

  /// 保存搜索查询
  @override
  Future<void> saveSearchQuery(String query, String name,
      {SearchFilters? filters}) async {
    // 这里需要一个 SavedSearch 实体，暂时使用简单实现
    // 实际应该保存到 ObjectBox
  }

  /// 获取已保存的搜索
  @override
  Future<List<SavedSearchQuery>> getSavedSearches() async {
    // 暂时返回空列表
    return [];
  }

  /// 删除已保存的搜索
  @override
  Future<void> deleteSavedSearch(int id) async {
    // 暂时不实现
  }
}

/// 带分数的文档
class _ScoredDocument {
  final DocumentContent doc;
  final double score;

  _ScoredDocument(this.doc, this.score);
}

/// 带分数的块
class _ScoredChunk {
  final DocumentChunk chunk;
  final double score;

  _ScoredChunk(this.chunk, this.score);
}

/// 合并分数
class _MergedScore {
  final SearchResultItem item;
  double fullTextScore;
  double semanticScore;
  double hybridScore = 0.0;

  _MergedScore({
    required this.item,
    required this.fullTextScore,
    required this.semanticScore,
  });

  void calculateHybridScore(double semanticWeight) {
    // 归一化分数
    final normalizedFullText =
        fullTextScore > 0 ? min(fullTextScore / 100, 1.0) : 0.0;
    final normalizedSemantic = semanticScore; // 已经是 0-1 范围

    hybridScore = (1 - semanticWeight) * normalizedFullText +
        semanticWeight * normalizedSemantic;
  }
}

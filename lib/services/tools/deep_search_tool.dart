/// Deep search tool for the AI Agent system
///
/// This tool enables web search and content extraction capabilities,
/// allowing the AI to search the internet and extract information
/// from web pages.
/// Requirements: 6.1-6.6
library;

import '../deep_search_service.dart';
import '../workspace_service.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Deep search tool implementation.
///
/// Performs web searches and extracts content from web pages:
/// - Search using DuckDuckGo, Google, or Bing
/// - Extract main content from web pages
/// - Save extracted content to knowledge base
/// - Auto research mode for comprehensive research reports
///
/// Requirements: 6.1-6.6
class DeepSearchTool implements ITool {
  final IDeepSearchService _deepSearchService;
  final IWorkspaceService _workspaceService;

  /// Creates a new [DeepSearchTool].
  ///
  /// [deepSearchService] - The deep search service for web operations.
  /// [workspaceService] - The workspace service for context.
  DeepSearchTool({
    required IDeepSearchService deepSearchService,
    required IWorkspaceService workspaceService,
  })  : _deepSearchService = deepSearchService,
        _workspaceService = workspaceService;

  /// Creates a [DeepSearchTool] using singleton services.
  factory DeepSearchTool.withDefaults() {
    return DeepSearchTool(
      deepSearchService: DeepSearchService.instance,
      workspaceService: WorkspaceService.instance,
    );
  }

  @override
  String get name => 'deep_search';

  @override
  String get description => '''
在互联网上进行深度搜索并提取内容：
- 使用搜索引擎 (DuckDuckGo, Google, Bing) 查找相关网页
- 自动访问和提取网页主要内容
- 可选择保存提取的内容到知识库
- 支持自动研究模式：自动访问多个结果并编译研究报告
- 返回搜索结果和提取的内容摘要
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': '搜索查询关键词或问题',
          },
          'max_results': {
            'type': 'integer',
            'default': 5,
            'description': '最大搜索结果数量，默认5条',
          },
          'extract_content': {
            'type': 'boolean',
            'default': true,
            'description': '是否提取网页内容，默认为true',
          },
          'auto_research': {
            'type': 'boolean',
            'default': false,
            'description': '是否启用自动研究模式。启用后将自动访问top-N结果并编译研究报告',
          },
          'save_to_workspace': {
            'type': 'string',
            'description': '保存到指定工作空间ID。如果提供，将把提取的内容保存到该工作空间',
          },
          'engine': {
            'type': 'string',
            'enum': ['duckduckgo', 'google', 'bing'],
            'default': 'duckduckgo',
            'description': '搜索引擎选择，默认使用DuckDuckGo',
          },
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '保存到知识库时添加的标签',
          },
        },
        'required': ['query'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      // Extract parameters
      final query = parameters['query'] as String?;
      if (query == null || query.trim().isEmpty) {
        return ToolResult.failure('搜索查询不能为空');
      }

      final maxResults = (parameters['max_results'] as int?) ?? 5;
      final extractContent = (parameters['extract_content'] as bool?) ?? true;
      final autoResearch = (parameters['auto_research'] as bool?) ?? false;
      final saveToWorkspace = parameters['save_to_workspace'] as String?;
      final engineStr = (parameters['engine'] as String?) ?? 'duckduckgo';
      final tags = (parameters['tags'] as List<dynamic>?)?.cast<String>() ?? [];

      // Parse search engine
      final engine = _parseSearchEngine(engineStr);

      // Use auto research mode if enabled
      if (autoResearch) {
        return await _executeAutoResearch(
          query: query,
          topN: maxResults,
          engine: engine,
          saveToWorkspace: saveToWorkspace,
          tags: tags,
        );
      }

      // Execute regular search
      return await _executeRegularSearch(
        query: query,
        maxResults: maxResults,
        extractContent: extractContent,
        saveToWorkspace: saveToWorkspace,
        engine: engine,
        engineStr: engineStr,
        tags: tags,
      );
    } catch (e) {
      return ToolResult.failure('深度搜索失败: $e');
    }
  }

  /// Execute regular search with optional content extraction
  Future<ToolResult> _executeRegularSearch({
    required String query,
    required int maxResults,
    required bool extractContent,
    required String? saveToWorkspace,
    required SearchEngine engine,
    required String engineStr,
    required List<String> tags,
  }) async {
    // Execute search
    final searchResult = await _deepSearchService.search(
      query,
      engine: engine,
      maxResults: maxResults,
    );

    if (!searchResult.success) {
      return ToolResult.failure('搜索失败: ${searchResult.error}');
    }

    // Build response data
    final responseData = <String, dynamic>{
      'query': query,
      'engine': engineStr,
      'search_time_ms': searchResult.searchTimeMs,
      'result_count': searchResult.items.length,
      'results': <Map<String, dynamic>>[],
    };

    final savedDocuments = <Map<String, dynamic>>[];

    // Process each result
    for (final item in searchResult.items) {
      final resultData = <String, dynamic>{
        'title': item.title,
        'url': item.url,
        'snippet': item.snippet,
        'domain': item.domain,
      };

      // Extract content if requested
      if (extractContent) {
        try {
          final content = await _deepSearchService.extractContent(item.url);
          item.isContentExtracted = true;
          item.extractedContent = content.content;

          resultData['extracted'] = true;
          resultData['content_preview'] = content.content.length > 500
              ? '${content.content.substring(0, 500)}...'
              : content.content;
          resultData['word_count'] = content.wordCount;
          resultData['image_count'] = content.imageUrls.length;

          // Save to workspace if requested
          if (saveToWorkspace != null && saveToWorkspace.isNotEmpty) {
            await _deepSearchService.saveToKnowledgeBase(
              saveToWorkspace,
              content,
              tags: tags,
            );
            savedDocuments.add({
              'title': content.title,
              'url': content.sourceUrl,
              'workspace_id': saveToWorkspace,
            });
          }
        } catch (e) {
          resultData['extracted'] = false;
          resultData['extraction_error'] = e.toString();
        }
      }

      (responseData['results'] as List<Map<String, dynamic>>).add(resultData);
    }

    // Add saved documents info
    if (savedDocuments.isNotEmpty) {
      responseData['saved_documents'] = savedDocuments;
    }

    // Build citations from search results
    final citations = searchResult.items
        .where((item) => item.isContentExtracted)
        .map((item) => SourceCitation(
              workspaceId: saveToWorkspace ?? '',
              workspaceName: saveToWorkspace != null
                  ? _getWorkspaceName(saveToWorkspace)
                  : 'Web',
              documentId: item.url,
              documentTitle: item.title,
              snippet: item.snippet,
            ))
        .toList();

    return ToolResult.success(
      data: responseData,
      citations: citations.isNotEmpty ? citations : null,
    );
  }

  /// Execute auto research mode
  /// Requirements: 6.6
  Future<ToolResult> _executeAutoResearch({
    required String query,
    required int topN,
    required SearchEngine engine,
    required String? saveToWorkspace,
    required List<String> tags,
  }) async {
    // Execute auto research
    final report = await _deepSearchService.autoResearch(
      query,
      topN: topN,
      engine: engine,
    );

    // Build response data
    final responseData = <String, dynamic>{
      'query': query,
      'mode': 'auto_research',
      'topic': report.topic,
      'generated_at': report.generatedAt.toIso8601String(),
      'source_count': report.sources.length,
      'report': report.summary,
      'sources': report.sources
          .map((source) => {
                'title': source.title,
                'url': source.url,
                'snippet': source.snippet,
                'domain': source.domain,
                'content_extracted': source.isContentExtracted,
              })
          .toList(),
    };

    // Save report to workspace if requested
    if (saveToWorkspace != null && saveToWorkspace.isNotEmpty) {
      final reportContent = ExtractedContent(
        title: 'Research Report: $query',
        content: report.summary,
        sourceUrl: 'auto-research://$query',
        extractedAt: report.generatedAt,
        wordCount: _countWords(report.summary),
      );

      await _deepSearchService.saveToKnowledgeBase(
        saveToWorkspace,
        reportContent,
        tags: ['research-report', ...tags],
      );

      responseData['saved_to_workspace'] = saveToWorkspace;
    }

    // Build citations from sources
    final citations = report.sources
        .where((source) => source.isContentExtracted)
        .map((source) => SourceCitation(
              workspaceId: saveToWorkspace ?? '',
              workspaceName: saveToWorkspace != null
                  ? _getWorkspaceName(saveToWorkspace)
                  : 'Web',
              documentId: source.url,
              documentTitle: source.title,
              snippet: source.snippet,
            ))
        .toList();

    return ToolResult.success(
      data: responseData,
      citations: citations.isNotEmpty ? citations : null,
    );
  }

  /// Parse search engine string to enum
  SearchEngine _parseSearchEngine(String engine) {
    switch (engine.toLowerCase()) {
      case 'google':
        return SearchEngine.google;
      case 'bing':
        return SearchEngine.bing;
      case 'duckduckgo':
      default:
        return SearchEngine.duckDuckGo;
    }
  }

  /// Get workspace name by ID
  String _getWorkspaceName(String workspaceId) {
    final workspace = _workspaceService.currentWorkspace;
    if (workspace != null && workspace.uuid == workspaceId) {
      return workspace.name;
    }
    return 'Workspace';
  }

  /// Count words in text
  int _countWords(String text) {
    if (text.isEmpty) return 0;

    // Chinese character count
    final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
    final chineseCount = chineseRegex.allMatches(text).length;

    // English word count
    final englishText = text.replaceAll(chineseRegex, ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(word))
        .length;

    return chineseCount + englishWords;
  }
}

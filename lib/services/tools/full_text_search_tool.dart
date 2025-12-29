/// Full-text search tool for the AI Agent system
///
/// This tool enables keyword-based search across the knowledge base,
/// supporting advanced search syntax and cross-workspace queries.
/// Requirements: 5.4
library;

import '../search_service.dart';
import '../workspace_service.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Full-text search tool implementation.
///
/// Searches the knowledge base using keywords with support for:
/// - Single workspace or cross-workspace search
/// - Advanced search syntax (AND, OR, NOT, quotes, workspace:, tag:)
/// - Result highlighting and snippets
///
/// Requirements: 5.4
class FullTextSearchTool implements ITool {
  final ISearchService _searchService;
  final IWorkspaceService _workspaceService;

  /// Creates a new [FullTextSearchTool].
  ///
  /// [searchService] - The search service for executing queries.
  /// [workspaceService] - The workspace service for context.
  FullTextSearchTool({
    required ISearchService searchService,
    required IWorkspaceService workspaceService,
  })  : _searchService = searchService,
        _workspaceService = workspaceService;

  /// Creates a [FullTextSearchTool] using singleton services.
  factory FullTextSearchTool.withDefaults() {
    return FullTextSearchTool(
      searchService: SearchService.instance,
      workspaceService: WorkspaceService.instance,
    );
  }

  @override
  String get name => 'full_text_search';

  @override
  String get description => '''
在知识库中进行关键词搜索。支持以下功能：
- 在当前工作空间或指定工作空间中搜索
- 支持 AND、OR、NOT 等高级搜索语法
- 支持 "精确短语" 匹配
- 支持 workspace:name 和 tag:name 过滤
- 返回匹配的文档片段和来源信息
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': '搜索关键词或查询语句。支持高级语法：'
                'AND (默认)、OR、NOT、"精确短语"、'
                'workspace:name、tag:name、-排除词',
          },
          'workspace_ids': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '要搜索的工作空间ID列表。为空则搜索当前工作空间。',
          },
          'limit': {
            'type': 'integer',
            'default': 10,
            'description': '返回结果数量上限，默认10条。',
          },
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '按标签过滤结果。',
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

      final workspaceIds =
          (parameters['workspace_ids'] as List<dynamic>?)?.cast<String>() ?? [];
      final limit = (parameters['limit'] as int?) ?? 10;
      final tags = (parameters['tags'] as List<dynamic>?)?.cast<String>() ?? [];

      // Determine effective workspace IDs
      List<String> effectiveWorkspaceIds = workspaceIds;
      if (effectiveWorkspaceIds.isEmpty) {
        // Use current workspace if no workspace specified
        final currentWorkspace = _workspaceService.currentWorkspace;
        if (currentWorkspace != null) {
          effectiveWorkspaceIds = [currentWorkspace.uuid];
        }
      }

      // Build filters
      final filters = SearchFilters(
        workspaceIds: effectiveWorkspaceIds,
        tags: tags,
      );

      // Execute search
      final result = await _searchService.fullTextSearch(
        query,
        workspaceIds: effectiveWorkspaceIds,
        filters: filters,
        limit: limit,
      );

      // Convert to tool result with citations
      final citations = result.items.map((item) {
        return SourceCitation(
          workspaceId: item.workspaceId,
          workspaceName: item.workspaceName,
          documentId: item.documentId,
          documentTitle: item.documentTitle,
          snippet: item.snippet,
          score: item.score,
        );
      }).toList();

      // Build response data
      final responseData = {
        'total_count': result.totalCount,
        'returned_count': result.items.length,
        'search_time_ms': result.searchTimeMs,
        'workspace_counts': result.workspaceCounts,
        'results': result.items
            .map((item) => {
                  'workspace_id': item.workspaceId,
                  'workspace_name': item.workspaceName,
                  'document_id': item.documentId,
                  'document_title': item.documentTitle,
                  'snippet': item.snippet,
                  'score': item.score,
                  'tags': item.tags,
                  'last_modified': item.lastModified.toIso8601String(),
                })
            .toList(),
      };

      return ToolResult.success(
        data: responseData,
        citations: citations,
      );
    } catch (e) {
      return ToolResult.failure('搜索失败: $e');
    }
  }
}

/// Vector search tool for the AI Agent system
///
/// This tool enables semantic search across the knowledge base using
/// vector embeddings to find content by meaning rather than keywords.
/// Requirements: 4.3
library;

import '../search_service.dart';
import '../workspace_service.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Vector search tool implementation.
///
/// Performs semantic search in the knowledge base based on meaning:
/// - Understands the semantic meaning of queries
/// - Finds related documents even without exact keyword matches
/// - Ideal for Q&A, concept lookup, and finding similar content
///
/// Requirements: 4.3
class VectorSearchTool implements ITool {
  final ISearchService _searchService;
  final IWorkspaceService _workspaceService;

  /// Creates a new [VectorSearchTool].
  ///
  /// [searchService] - The search service for executing queries.
  /// [workspaceService] - The workspace service for context.
  VectorSearchTool({
    required ISearchService searchService,
    required IWorkspaceService workspaceService,
  })  : _searchService = searchService,
        _workspaceService = workspaceService;

  /// Creates a [VectorSearchTool] using singleton services.
  factory VectorSearchTool.withDefaults() {
    return VectorSearchTool(
      searchService: SearchService.instance,
      workspaceService: WorkspaceService.instance,
    );
  }

  @override
  String get name => 'vector_search';

  @override
  String get description => '''
在知识库中进行语义搜索。基于文本含义而非关键词匹配：
- 理解查询的语义含义
- 找到语义相关的文档，即使没有完全匹配的关键词
- 适合问答、概念查找等场景
- 返回相似度分数和来源引用
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'query': {
            'type': 'string',
            'description': '自然语言查询。描述你想要查找的内容或问题。',
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
          'similarity_threshold': {
            'type': 'number',
            'default': 0.7,
            'description': '相似度阈值 (0-1)，只返回高于此阈值的结果。默认0.7。',
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
      final similarityThreshold =
          (parameters['similarity_threshold'] as num?)?.toDouble() ?? 0.7;

      // Determine effective workspace IDs
      List<String> effectiveWorkspaceIds = workspaceIds;
      if (effectiveWorkspaceIds.isEmpty) {
        // Use current workspace if no workspace specified
        final currentWorkspace = _workspaceService.currentWorkspace;
        if (currentWorkspace != null) {
          effectiveWorkspaceIds = [currentWorkspace.uuid];
        }
      }

      // Execute semantic search
      final result = await _searchService.semanticSearch(
        query,
        workspaceIds: effectiveWorkspaceIds,
        limit: limit,
        similarityThreshold: similarityThreshold,
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
        'similarity_threshold': similarityThreshold,
        'results': result.items
            .map((item) => {
                  'workspace_id': item.workspaceId,
                  'workspace_name': item.workspaceName,
                  'document_id': item.documentId,
                  'document_title': item.documentTitle,
                  'snippet': item.snippet,
                  'similarity_score': item.score,
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
      return ToolResult.failure('语义搜索失败: $e');
    }
  }
}

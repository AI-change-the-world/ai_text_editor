/// Document operation tool for the AI Agent system
///
/// This tool enables document operations including create, read, update,
/// and get info operations on documents in the knowledge base.
/// Requirements: 2.1
library;

import '../document_service.dart';
import '../workspace_service.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Document action types
enum DocumentAction {
  create,
  read,
  update,
  getInfo,
}

/// Document tool implementation.
///
/// Performs document operations:
/// - Create new documents
/// - Read document content
/// - Update existing documents
/// - Get document metadata
///
/// Requirements: 2.1
class DocumentTool implements ITool {
  final DocumentService _documentService;
  final IWorkspaceService _workspaceService;

  /// Creates a new [DocumentTool].
  ///
  /// [documentService] - The document service for operations.
  /// [workspaceService] - The workspace service for context.
  DocumentTool({
    required DocumentService documentService,
    required IWorkspaceService workspaceService,
  })  : _documentService = documentService,
        _workspaceService = workspaceService;

  /// Creates a [DocumentTool] using singleton services.
  factory DocumentTool.withDefaults() {
    return DocumentTool(
      documentService: DocumentService.instance,
      workspaceService: WorkspaceService.instance,
    );
  }

  @override
  String get name => 'document_operation';

  @override
  String get description => '''
对文档进行操作：
- create: 创建新文档
- read: 读取文档内容
- update: 更新文档内容
- get_info: 获取文档元信息（标题、字数、标签等）
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['create', 'read', 'update', 'get_info'],
            'description': '操作类型：create/read/update/get_info',
          },
          'document_id': {
            'type': 'string',
            'description': '文档ID (read/update/get_info 时必需)',
          },
          'workspace_id': {
            'type': 'string',
            'description': '工作空间ID (create 时必需，不提供则使用当前工作空间)',
          },
          'title': {
            'type': 'string',
            'description': '文档标题 (create 时必需)',
          },
          'content': {
            'type': 'string',
            'description': '文档内容 (create/update 时使用)',
          },
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '文档标签 (create 时可选)',
          },
          'parent_folder_id': {
            'type': 'string',
            'description': '父文件夹ID (create 时可选)',
          },
        },
        'required': ['action'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      final actionStr = parameters['action'] as String?;
      if (actionStr == null) {
        return ToolResult.failure('操作类型不能为空');
      }

      final action = _parseAction(actionStr);
      if (action == null) {
        return ToolResult.failure('无效的操作类型: $actionStr');
      }

      switch (action) {
        case DocumentAction.create:
          return await _createDocument(parameters);
        case DocumentAction.read:
          return await _readDocument(parameters);
        case DocumentAction.update:
          return await _updateDocument(parameters);
        case DocumentAction.getInfo:
          return await _getDocumentInfo(parameters);
      }
    } catch (e) {
      return ToolResult.failure('文档操作失败: $e');
    }
  }

  DocumentAction? _parseAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return DocumentAction.create;
      case 'read':
        return DocumentAction.read;
      case 'update':
        return DocumentAction.update;
      case 'get_info':
      case 'getinfo':
        return DocumentAction.getInfo;
      default:
        return null;
    }
  }

  /// Create a new document
  Future<ToolResult> _createDocument(Map<String, dynamic> parameters) async {
    final title = parameters['title'] as String?;
    if (title == null || title.trim().isEmpty) {
      return ToolResult.failure('创建文档需要提供标题');
    }

    // Determine workspace ID
    String? workspaceId = parameters['workspace_id'] as String?;
    if (workspaceId == null || workspaceId.isEmpty) {
      final currentWorkspace = _workspaceService.currentWorkspace;
      if (currentWorkspace == null) {
        return ToolResult.failure('未指定工作空间且没有当前活动工作空间');
      }
      workspaceId = currentWorkspace.uuid;
    }

    final content = parameters['content'] as String?;
    final tags = (parameters['tags'] as List<dynamic>?)?.cast<String>();
    final parentFolderId = parameters['parent_folder_id'] as String?;

    final request = CreateDocumentRequest(
      title: title,
      initialContent: content,
      tags: tags,
      parentFolderId: parentFolderId,
    );

    final document =
        await _documentService.createDocument(workspaceId, request);

    return ToolResult.success(
      data: {
        'document_id': document.uuid,
        'title': document.title,
        'workspace_id': document.workspaceId,
        'created_at': DateTime.fromMillisecondsSinceEpoch(document.createdAt)
            .toIso8601String(),
        'message': '文档创建成功',
      },
    );
  }

  /// Read document content
  Future<ToolResult> _readDocument(Map<String, dynamic> parameters) async {
    final documentId = parameters['document_id'] as String?;
    if (documentId == null || documentId.isEmpty) {
      return ToolResult.failure('读取文档需要提供文档ID');
    }

    final document = await _documentService.getDocument(documentId);
    if (document == null) {
      return ToolResult.failure('文档不存在: $documentId');
    }

    final contentData = await _documentService.getDocumentContent(documentId);
    final content = contentData?.plainText ?? '';

    return ToolResult.success(
      data: {
        'document_id': document.uuid,
        'title': document.title,
        'content': content,
        'word_count': document.wordCount,
        'character_count': document.characterCount,
        'tags': document.tags,
        'last_modified': DateTime.fromMillisecondsSinceEpoch(document.updatedAt)
            .toIso8601String(),
      },
      citations: [
        SourceCitation(
          workspaceId: document.workspaceId,
          workspaceName: '', // Would need workspace lookup
          documentId: document.uuid,
          documentTitle: document.title,
          snippet: content.length > 200
              ? '${content.substring(0, 200)}...'
              : content,
        ),
      ],
    );
  }

  /// Update document content
  Future<ToolResult> _updateDocument(Map<String, dynamic> parameters) async {
    final documentId = parameters['document_id'] as String?;
    if (documentId == null || documentId.isEmpty) {
      return ToolResult.failure('更新文档需要提供文档ID');
    }

    final content = parameters['content'] as String?;
    if (content == null) {
      return ToolResult.failure('更新文档需要提供内容');
    }

    // Verify document exists
    final document = await _documentService.getDocument(documentId);
    if (document == null) {
      return ToolResult.failure('文档不存在: $documentId');
    }

    await _documentService.saveDocument(
      documentId,
      DocumentContentData(plainText: content),
    );

    return ToolResult.success(
      data: {
        'document_id': documentId,
        'message': '文档更新成功',
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get document metadata
  Future<ToolResult> _getDocumentInfo(Map<String, dynamic> parameters) async {
    final documentId = parameters['document_id'] as String?;
    if (documentId == null || documentId.isEmpty) {
      return ToolResult.failure('获取文档信息需要提供文档ID');
    }

    final document = await _documentService.getDocument(documentId);
    if (document == null) {
      return ToolResult.failure('文档不存在: $documentId');
    }

    return ToolResult.success(
      data: {
        'document_id': document.uuid,
        'title': document.title,
        'workspace_id': document.workspaceId,
        'parent_folder_id': document.parentFolderId,
        'is_folder': document.isFolder,
        'word_count': document.wordCount,
        'character_count': document.characterCount,
        'tags': document.tags,
        'created_at': DateTime.fromMillisecondsSinceEpoch(document.createdAt)
            .toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(document.updatedAt)
            .toIso8601String(),
      },
    );
  }
}

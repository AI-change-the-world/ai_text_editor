import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/document_meta.dart';
import '../../../services/document_service.dart';
import '../../workspace/notifiers/workspace_notifier.dart';

/// 文档树节点模型
class DocumentTreeNode {
  final DocumentMeta document;
  final List<DocumentTreeNode> children;
  final int depth;
  bool isExpanded;

  DocumentTreeNode({
    required this.document,
    this.children = const [],
    this.depth = 0,
    this.isExpanded = true,
  });

  DocumentTreeNode copyWith({
    DocumentMeta? document,
    List<DocumentTreeNode>? children,
    int? depth,
    bool? isExpanded,
  }) {
    return DocumentTreeNode(
      document: document ?? this.document,
      children: children ?? this.children,
      depth: depth ?? this.depth,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// 文档树状态
class DocumentTreeState {
  final List<DocumentTreeNode> rootNodes;
  final String? selectedDocumentId;
  final bool isLoading;
  final String? error;
  final Set<String> expandedFolderIds;

  const DocumentTreeState({
    this.rootNodes = const [],
    this.selectedDocumentId,
    this.isLoading = false,
    this.error,
    this.expandedFolderIds = const {},
  });

  DocumentTreeState copyWith({
    List<DocumentTreeNode>? rootNodes,
    String? selectedDocumentId,
    bool? isLoading,
    String? error,
    Set<String>? expandedFolderIds,
    bool clearSelectedDocument = false,
  }) {
    return DocumentTreeState(
      rootNodes: rootNodes ?? this.rootNodes,
      selectedDocumentId: clearSelectedDocument
          ? null
          : (selectedDocumentId ?? this.selectedDocumentId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      expandedFolderIds: expandedFolderIds ?? this.expandedFolderIds,
    );
  }
}

/// 文档树状态管理
/// Requirements: 1.4
class DocumentTreeNotifier extends Notifier<DocumentTreeState> {
  late final DocumentService _documentService;

  @override
  DocumentTreeState build() {
    _documentService = DocumentService.instance;

    // 监听工作空间变化
    ref.listen(workspaceProvider, (previous, next) {
      // 当 workspace 从 loading 变为 loaded，或者切换了 workspace 时重新加载
      if (previous?.isLoading == true && next.isLoading == false) {
        loadDocuments();
      } else if (previous?.currentWorkspace?.uuid !=
          next.currentWorkspace?.uuid) {
        loadDocuments();
      }
    });

    // 使用 Future.microtask 延迟加载，确保 state 已初始化
    Future.microtask(() => loadDocuments());
    return const DocumentTreeState(isLoading: true);
  }

  /// 加载当前工作空间的文档
  Future<void> loadDocuments() async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) {
      state = const DocumentTreeState(rootNodes: [], isLoading: false);
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final documents =
          await _documentService.getDocumentsByWorkspace(currentWorkspace.uuid);
      final rootNodes = _buildTree(documents, null, 0);
      state = state.copyWith(
        rootNodes: rootNodes,
        isLoading: false,
        expandedFolderIds: state.expandedFolderIds,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 构建文档树
  List<DocumentTreeNode> _buildTree(
    List<DocumentMeta> documents,
    String? parentId,
    int depth,
  ) {
    final children =
        documents.where((doc) => doc.parentFolderId == parentId).toList()
          ..sort((a, b) {
            // 文件夹优先
            if (a.isFolder != b.isFolder) {
              return a.isFolder ? -1 : 1;
            }
            // 按排序顺序
            return a.sortOrder.compareTo(b.sortOrder);
          });

    return children.map((doc) {
      final childNodes = doc.isFolder
          ? _buildTree(documents, doc.uuid, depth + 1)
          : <DocumentTreeNode>[];

      return DocumentTreeNode(
        document: doc,
        children: childNodes,
        depth: depth,
        isExpanded: state.expandedFolderIds.contains(doc.uuid),
      );
    }).toList();
  }

  /// 选择文档
  void selectDocument(String documentId) {
    state = state.copyWith(selectedDocumentId: documentId);
  }

  /// 清除选择
  void clearSelection() {
    state = state.copyWith(clearSelectedDocument: true);
  }

  /// 切换文件夹展开状态
  void toggleFolderExpansion(String folderId) {
    final newExpandedIds = Set<String>.from(state.expandedFolderIds);
    if (newExpandedIds.contains(folderId)) {
      newExpandedIds.remove(folderId);
    } else {
      newExpandedIds.add(folderId);
    }
    state = state.copyWith(expandedFolderIds: newExpandedIds);
    // 重新构建树以更新展开状态
    loadDocuments();
  }

  /// 创建新文档
  Future<DocumentMeta?> createDocument(String title,
      {String? parentFolderId}) async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) return null;

    try {
      final document = await _documentService.createDocument(
        currentWorkspace.uuid,
        CreateDocumentRequest(title: title, parentFolderId: parentFolderId),
      );
      await loadDocuments();
      selectDocument(document.uuid);
      return document;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 创建带内容的新文档（用于导入）
  Future<DocumentMeta?> createDocumentWithContent(String title, String content,
      {String? parentFolderId}) async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) return null;

    try {
      final document = await _documentService.createDocument(
        currentWorkspace.uuid,
        CreateDocumentRequest(
          title: title,
          parentFolderId: parentFolderId,
          initialContent: content,
        ),
      );
      await loadDocuments();
      selectDocument(document.uuid);
      return document;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 创建新文件夹
  Future<DocumentMeta?> createFolder(String name,
      {String? parentFolderId}) async {
    final workspaceState = ref.read(workspaceProvider);
    final currentWorkspace = workspaceState.currentWorkspace;

    if (currentWorkspace == null) return null;

    try {
      final folder = await _documentService.createFolder(
        currentWorkspace.uuid,
        name,
        parentFolderId,
      );
      // 自动展开新创建的文件夹
      final newExpandedIds = Set<String>.from(state.expandedFolderIds)
        ..add(folder.uuid);
      state = state.copyWith(expandedFolderIds: newExpandedIds);
      await loadDocuments();
      return folder;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// 移动文档
  Future<void> moveDocument(String documentId, String? targetFolderId) async {
    try {
      await _documentService.moveDocument(documentId, targetFolderId);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 重命名文档
  Future<void> renameDocument(String documentId, String newTitle) async {
    try {
      await _documentService.renameDocument(documentId, newTitle);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除文档
  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      if (state.selectedDocumentId == documentId) {
        state = state.copyWith(clearSelectedDocument: true);
      }
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新文档排序
  Future<void> reorderDocuments(
      String documentId, int newSortOrder, String? newParentId) async {
    try {
      await _documentService.updateDocumentOrder(
          documentId, newSortOrder, newParentId);
      await loadDocuments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// 文档树 Provider
final documentTreeProvider =
    NotifierProvider<DocumentTreeNotifier, DocumentTreeState>(
        DocumentTreeNotifier.new);

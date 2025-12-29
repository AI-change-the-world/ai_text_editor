import 'package:uuid/uuid.dart';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';

/// 创建工作空间请求
class CreateWorkspaceRequest {
  final String name;
  final String? description;
  final String? icon;
  final String? colorTheme;
  final String? category;

  CreateWorkspaceRequest({
    required this.name,
    this.description,
    this.icon,
    this.colorTheme,
    this.category,
  });
}

/// 更新工作空间请求
class UpdateWorkspaceRequest {
  final String? name;
  final String? description;
  final String? icon;
  final String? colorTheme;
  final String? category;

  UpdateWorkspaceRequest({
    this.name,
    this.description,
    this.icon,
    this.colorTheme,
    this.category,
  });
}

/// 工作空间统计信息
class WorkspaceStats {
  final int documentCount;
  final int totalWords;
  final int assetCount;
  final int storageUsageBytes;

  WorkspaceStats({
    required this.documentCount,
    required this.totalWords,
    required this.assetCount,
    required this.storageUsageBytes,
  });
}

/// 工作空间服务接口
/// Requirements: 1.1, 1.2, 1.3, 1.8, 1.9, 1.10
abstract class IWorkspaceService {
  /// 获取所有工作空间
  /// Requirements: 1.1
  Future<List<Workspace>> getAllWorkspaces();

  /// 创建新工作空间
  /// Requirements: 1.2
  Future<Workspace> createWorkspace(CreateWorkspaceRequest request);

  /// 切换当前工作空间
  /// Requirements: 1.3
  Future<void> switchWorkspace(String workspaceId);

  /// 获取当前活动工作空间
  Workspace? get currentWorkspace;

  /// 更新工作空间信息
  Future<void> updateWorkspace(String id, UpdateWorkspaceRequest request);

  /// 归档工作空间
  /// Requirements: 1.10
  Future<void> archiveWorkspace(String workspaceId);

  /// 置顶/取消置顶工作空间
  /// Requirements: 1.9
  Future<void> togglePinWorkspace(String workspaceId);

  /// 获取工作空间统计信息
  /// Requirements: 1.8
  Future<WorkspaceStats> getWorkspaceStats(String workspaceId);
}

/// 工作空间服务实现
/// Requirements: 1.1, 1.2, 1.3, 1.8, 1.9, 1.10
class WorkspaceService implements IWorkspaceService {
  final ObxDatabase _db;
  final Uuid _uuid = const Uuid();

  Workspace? _currentWorkspace;

  WorkspaceService(this._db);

  /// 单例实例
  static WorkspaceService? _instance;

  /// 获取单例实例（懒加载）
  static WorkspaceService get instance {
    _instance ??= WorkspaceService(ObxDatabase.db);
    return _instance!;
  }

  @override
  Workspace? get currentWorkspace => _currentWorkspace;

  /// 获取所有工作空间
  /// 返回按置顶状态和最后访问时间排序的工作空间列表
  /// 置顶的工作空间排在前面，未归档的工作空间优先
  /// Requirements: 1.1
  @override
  Future<List<Workspace>> getAllWorkspaces() async {
    final query = _db.workspaceBox
        .query(Workspace_.isArchived.equals(false))
        .order(Workspace_.isPinned, flags: Order.descending)
        .order(Workspace_.lastAccessedAt, flags: Order.descending)
        .build();

    final workspaces = query.find();
    query.close();
    return workspaces;
  }

  /// 获取所有工作空间（包括已归档）
  Future<List<Workspace>> getAllWorkspacesIncludingArchived() async {
    final query = _db.workspaceBox
        .query()
        .order(Workspace_.isPinned, flags: Order.descending)
        .order(Workspace_.lastAccessedAt, flags: Order.descending)
        .build();

    final workspaces = query.find();
    query.close();
    return workspaces;
  }

  /// 创建新工作空间
  /// 生成唯一 UUID，设置可配置的名称、图标、颜色主题、描述和分类
  /// Requirements: 1.2
  @override
  Future<Workspace> createWorkspace(CreateWorkspaceRequest request) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final workspace = Workspace(
      uuid: _uuid.v4(),
      name: request.name,
      description: request.description,
      icon: request.icon,
      colorTheme: request.colorTheme,
      category: request.category,
      isPinned: false,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
      lastAccessedAt: now,
    );

    _db.workspaceBox.put(workspace);
    return workspace;
  }

  /// 切换当前工作空间
  /// 加载工作空间内容并设置为 AI 和搜索的活动上下文
  /// Requirements: 1.3
  @override
  Future<void> switchWorkspace(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    // 更新最后访问时间
    workspace.lastAccessedAt = DateTime.now().millisecondsSinceEpoch;
    _db.workspaceBox.put(workspace);

    _currentWorkspace = workspace;
  }

  /// 更新工作空间信息
  @override
  Future<void> updateWorkspace(
      String id, UpdateWorkspaceRequest request) async {
    final query = _db.workspaceBox.query(Workspace_.uuid.equals(id)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(id);
    }

    final updatedWorkspace = workspace.copyWith(
      name: request.name ?? workspace.name,
      description: request.description ?? workspace.description,
      icon: request.icon ?? workspace.icon,
      colorTheme: request.colorTheme ?? workspace.colorTheme,
      category: request.category ?? workspace.category,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.workspaceBox.put(updatedWorkspace);

    // 如果更新的是当前工作空间，同步更新引用
    if (_currentWorkspace?.uuid == id) {
      _currentWorkspace = updatedWorkspace;
    }
  }

  /// 归档工作空间
  /// 将工作空间标记为已归档，从活动列表中移除
  /// Requirements: 1.10
  @override
  Future<void> archiveWorkspace(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    final updatedWorkspace = workspace.copyWith(
      isArchived: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.workspaceBox.put(updatedWorkspace);

    // 如果归档的是当前工作空间，清除当前工作空间引用
    if (_currentWorkspace?.uuid == workspaceId) {
      _currentWorkspace = null;
    }
  }

  /// 置顶/取消置顶工作空间
  /// 置顶的工作空间显示在列表顶部以便快速访问
  /// Requirements: 1.9
  @override
  Future<void> togglePinWorkspace(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    final updatedWorkspace = workspace.copyWith(
      isPinned: !workspace.isPinned,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.workspaceBox.put(updatedWorkspace);

    // 如果更新的是当前工作空间，同步更新引用
    if (_currentWorkspace?.uuid == workspaceId) {
      _currentWorkspace = updatedWorkspace;
    }
  }

  /// 获取工作空间统计信息
  /// 返回文档数量、总字数、资产数量和存储使用量
  /// Requirements: 1.8
  @override
  Future<WorkspaceStats> getWorkspaceStats(String workspaceId) async {
    // 验证工作空间存在
    final wsQuery =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();
    final workspace = wsQuery.findFirst();
    wsQuery.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    // 统计文档数量和总字数
    final docQuery = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId) &
            DocumentMeta_.isFolder.equals(false))
        .build();
    final documents = docQuery.find();
    docQuery.close();

    final documentCount = documents.length;
    final totalWords =
        documents.fold<int>(0, (sum, doc) => sum + doc.wordCount);

    // 统计资产数量和存储使用量
    final assetQuery =
        _db.assetBox.query(Asset_.workspaceId.equals(workspaceId)).build();
    final assets = assetQuery.find();
    assetQuery.close();

    final assetCount = assets.length;
    final storageUsageBytes =
        assets.fold<int>(0, (sum, asset) => sum + asset.fileSize);

    return WorkspaceStats(
      documentCount: documentCount,
      totalWords: totalWords,
      assetCount: assetCount,
      storageUsageBytes: storageUsageBytes,
    );
  }

  /// 根据 UUID 获取工作空间
  Future<Workspace?> getWorkspaceById(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();
    return workspace;
  }

  /// 取消归档工作空间
  Future<void> unarchiveWorkspace(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    final updatedWorkspace = workspace.copyWith(
      isArchived: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.workspaceBox.put(updatedWorkspace);
  }

  /// 删除工作空间（永久删除）
  Future<void> deleteWorkspace(String workspaceId) async {
    final query =
        _db.workspaceBox.query(Workspace_.uuid.equals(workspaceId)).build();

    final workspace = query.findFirst();
    query.close();

    if (workspace == null) {
      throw WorkspaceNotFoundException(workspaceId);
    }

    // 删除关联的文档
    final docQuery = _db.documentMetaBox
        .query(DocumentMeta_.workspaceId.equals(workspaceId))
        .build();
    final docs = docQuery.find();
    docQuery.close();
    _db.documentMetaBox.removeMany(docs.map((d) => d.id).toList());

    // 删除关联的资产
    final assetQuery =
        _db.assetBox.query(Asset_.workspaceId.equals(workspaceId)).build();
    final assets = assetQuery.find();
    assetQuery.close();
    _db.assetBox.removeMany(assets.map((a) => a.id).toList());

    // 删除工作空间
    _db.workspaceBox.remove(workspace.id);

    // 如果删除的是当前工作空间，清除引用
    if (_currentWorkspace?.uuid == workspaceId) {
      _currentWorkspace = null;
    }
  }
}

/// 工作空间未找到异常
class WorkspaceNotFoundException implements Exception {
  final String workspaceId;

  WorkspaceNotFoundException(this.workspaceId);

  @override
  String toString() => 'Workspace not found: $workspaceId';
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../../services/workspace_service.dart';

/// 工作空间状态
class WorkspaceState {
  final List<Workspace> workspaces;
  final Workspace? currentWorkspace;
  final bool isLoading;
  final String? error;

  const WorkspaceState({
    this.workspaces = const [],
    this.currentWorkspace,
    this.isLoading = false,
    this.error,
  });

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    Workspace? currentWorkspace,
    bool? isLoading,
    String? error,
    bool clearCurrentWorkspace = false,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      currentWorkspace: clearCurrentWorkspace
          ? null
          : (currentWorkspace ?? this.currentWorkspace),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 工作空间状态管理
/// Requirements: 1.1, 1.2, 1.3, 1.9, 1.10
class WorkspaceNotifier extends Notifier<WorkspaceState> {
  late final WorkspaceService _service;

  @override
  WorkspaceState build() {
    _service = WorkspaceService.instance;
    // 使用 Future.microtask 延迟加载，确保 state 已初始化
    Future.microtask(() => _loadWorkspaces());
    return const WorkspaceState(isLoading: true);
  }

  /// 加载所有工作空间
  Future<void> _loadWorkspaces() async {
    try {
      final workspaces = await _service.getAllWorkspaces();
      state = state.copyWith(
        workspaces: workspaces,
        currentWorkspace: _service.currentWorkspace,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 刷新工作空间列表
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadWorkspaces();
  }

  /// 创建新工作空间
  /// Requirements: 1.2
  Future<Workspace?> createWorkspace(CreateWorkspaceRequest request) async {
    try {
      state = state.copyWith(isLoading: true);
      final workspace = await _service.createWorkspace(request);
      await _loadWorkspaces();
      return workspace;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 切换工作空间
  /// Requirements: 1.3
  Future<void> switchWorkspace(String workspaceId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _service.switchWorkspace(workspaceId);
      state = state.copyWith(
        currentWorkspace: _service.currentWorkspace,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 置顶/取消置顶工作空间
  /// Requirements: 1.9
  Future<void> togglePinWorkspace(String workspaceId) async {
    try {
      await _service.togglePinWorkspace(workspaceId);
      await _loadWorkspaces();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 归档工作空间
  /// Requirements: 1.10
  Future<void> archiveWorkspace(String workspaceId) async {
    try {
      await _service.archiveWorkspace(workspaceId);
      // 如果归档的是当前工作空间，清除当前工作空间
      if (state.currentWorkspace?.uuid == workspaceId) {
        state = state.copyWith(clearCurrentWorkspace: true);
      }
      await _loadWorkspaces();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 更新工作空间
  Future<void> updateWorkspace(
      String id, UpdateWorkspaceRequest request) async {
    try {
      await _service.updateWorkspace(id, request);
      await _loadWorkspaces();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 删除工作空间
  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      await _service.deleteWorkspace(workspaceId);
      // 如果删除的是当前工作空间，清除当前工作空间
      if (state.currentWorkspace?.uuid == workspaceId) {
        state = state.copyWith(clearCurrentWorkspace: true);
      }
      await _loadWorkspaces();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 获取工作空间统计信息
  /// Requirements: 1.8
  Future<WorkspaceStats?> getWorkspaceStats(String workspaceId) async {
    try {
      return await _service.getWorkspaceStats(workspaceId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

/// 工作空间 Provider
final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(WorkspaceNotifier.new);

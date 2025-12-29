import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/workspace_notifier.dart';
import 'workspace_card.dart';

/// 工作空间选择器组件 (侧边栏)
/// 显示所有工作空间列表，支持切换、创建、置顶等操作
/// Requirements: 1.1
class WorkspaceSelector extends ConsumerWidget {
  final VoidCallback? onCreateWorkspace;
  final Function(String workspaceId)? onSettingsPressed;

  const WorkspaceSelector({
    super.key,
    this.onCreateWorkspace,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(context),
          const Divider(height: 1),
          // 工作空间列表
          Expanded(
            child: workspaceState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : workspaceState.workspaces.isEmpty
                    ? _buildEmptyState(context)
                    : _buildWorkspaceList(context, ref, workspaceState),
          ),
          // 底部操作栏
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.workspaces,
            size: 20,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          const Text(
            '工作空间',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: onCreateWorkspace,
            tooltip: '创建工作空间',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无工作空间',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方 + 按钮创建第一个工作空间',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceList(
    BuildContext context,
    WidgetRef ref,
    WorkspaceState workspaceState,
  ) {
    // 分离置顶和非置顶工作空间
    final pinnedWorkspaces =
        workspaceState.workspaces.where((w) => w.isPinned).toList();
    final unpinnedWorkspaces =
        workspaceState.workspaces.where((w) => !w.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 置顶工作空间
        if (pinnedWorkspaces.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '置顶',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          ...pinnedWorkspaces.map((workspace) => WorkspaceCard(
                workspace: workspace,
                isSelected:
                    workspaceState.currentWorkspace?.uuid == workspace.uuid,
                onTap: () => _onWorkspaceTap(ref, workspace.uuid),
                onPinToggle: () => _onPinToggle(ref, workspace.uuid),
                onSettings: () => onSettingsPressed?.call(workspace.uuid),
                onArchive: () => _onArchive(context, ref, workspace),
              )),
          if (unpinnedWorkspaces.isNotEmpty) const SizedBox(height: 8),
        ],
        // 非置顶工作空间
        if (unpinnedWorkspaces.isNotEmpty) ...[
          if (pinnedWorkspaces.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '全部',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ...unpinnedWorkspaces.map((workspace) => WorkspaceCard(
                workspace: workspace,
                isSelected:
                    workspaceState.currentWorkspace?.uuid == workspace.uuid,
                onTap: () => _onWorkspaceTap(ref, workspace.uuid),
                onPinToggle: () => _onPinToggle(ref, workspace.uuid),
                onSettings: () => onSettingsPressed?.call(workspace.uuid),
                onArchive: () => _onArchive(context, ref, workspace),
              )),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    // 底部区域已简化，创建工作空间入口只保留顶部的 + 按钮
    // AI 助手入口只保留右下角悬浮按钮
    return const SizedBox.shrink();
  }

  void _onWorkspaceTap(WidgetRef ref, String workspaceId) {
    ref.read(workspaceProvider.notifier).switchWorkspace(workspaceId);
  }

  void _onPinToggle(WidgetRef ref, String workspaceId) {
    ref.read(workspaceProvider.notifier).togglePinWorkspace(workspaceId);
  }

  void _onArchive(BuildContext context, WidgetRef ref, workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档工作空间'),
        content: Text('确定要归档工作空间 "${workspace.name}" 吗？\n归档后可在设置中恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(workspaceProvider.notifier)
                  .archiveWorkspace(workspace.uuid);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('归档'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';
import '../../settings/views/settings_page.dart';
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
    final colors = context.colors;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.sidebarBackground,
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(context, colors),
          Divider(height: 1, color: colors.divider),
          // 工作空间列表
          Expanded(
            child: workspaceState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : workspaceState.workspaces.isEmpty
                    ? _buildEmptyState(context, colors)
                    : _buildWorkspaceList(context, ref, workspaceState, colors),
          ),
          // 底部操作栏
          _buildFooter(context, ref, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.workspaces, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            '工作空间',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: colors.textSecondary),
            onPressed: onCreateWorkspace,
            tooltip: '创建工作空间',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: colors.textHint),
            const SizedBox(height: 16),
            Text(
              '暂无工作空间',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方 + 按钮创建第一个工作空间',
              style: TextStyle(fontSize: 12, color: colors.textHint),
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
    AppColors colors,
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
                color: colors.textHint,
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
                  color: colors.textHint,
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

  Widget _buildFooter(BuildContext context, WidgetRef ref, AppColors colors) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 12, right: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: InkWell(
        onTap: () => showSettingsPage(context),
        borderRadius: BorderRadius.circular(8),
        hoverColor: colors.sidebarItemHover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.settings_outlined,
                  size: 20, color: colors.textSecondary),
              const SizedBox(width: 10),
              Text(
                '设置',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onWorkspaceTap(WidgetRef ref, String workspaceId) {
    ref.read(workspaceProvider.notifier).switchWorkspace(workspaceId);
  }

  void _onPinToggle(WidgetRef ref, String workspaceId) {
    ref.read(workspaceProvider.notifier).togglePinWorkspace(workspaceId);
  }

  void _onArchive(BuildContext context, WidgetRef ref, workspace) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.dialogBackground,
        title: Text('归档工作空间', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          '确定要归档工作空间 "${workspace.name}" 吗？\n归档后可在设置中恢复。',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(workspaceProvider.notifier)
                  .archiveWorkspace(workspace.uuid);
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('归档'),
          ),
        ],
      ),
    );
  }
}

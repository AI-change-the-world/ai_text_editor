import 'package:flutter/material.dart';

import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../../utils/app_theme.dart';

/// 工作空间卡片组件
/// 显示工作空间的图标、名称、描述和最近活动
/// Requirements: 1.1
class WorkspaceCard extends StatelessWidget {
  final Workspace workspace;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onSettings;
  final VoidCallback? onArchive;

  const WorkspaceCard({
    super.key,
    required this.workspace,
    this.isSelected = false,
    this.onTap,
    this.onPinToggle,
    this.onSettings,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorTheme = _parseColorTheme(workspace.colorTheme);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorTheme.withValues(alpha: 0.15)
                : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colorTheme : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 工作空间图标
              _buildIcon(colorTheme),
              const SizedBox(width: 12),
              // 工作空间信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workspace.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? colorTheme : colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (workspace.isPinned)
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: colors.warning,
                          ),
                      ],
                    ),
                    if (workspace.description != null &&
                        workspace.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        workspace.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatLastAccessed(workspace.lastAccessedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // 操作按钮
              _buildActionMenu(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color colorTheme) {
    // 如果有 emoji 图标
    if (workspace.icon != null && workspace.icon!.isNotEmpty) {
      // 检查是否是 emoji（简单判断：长度较短且不是路径）
      if (workspace.icon!.length <= 4 && !workspace.icon!.contains('/')) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorTheme.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              workspace.icon!,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      }
    }

    // 默认使用首字母图标
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorTheme.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : 'W',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorTheme,
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, AppColors colors) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: 18,
        color: colors.textSecondary,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: colors.dialogBackground,
      onSelected: (value) {
        switch (value) {
          case 'pin':
            onPinToggle?.call();
            break;
          case 'settings':
            onSettings?.call();
            break;
          case 'archive':
            onArchive?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          height: 36,
          child: Row(
            children: [
              Icon(
                workspace.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                size: 16,
                color: colors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                workspace.isPinned ? '取消置顶' : '置顶',
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          height: 36,
          child: Row(
            children: [
              Icon(
                Icons.settings,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '设置',
                style: TextStyle(fontSize: 13, color: colors.textPrimary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'archive',
          height: 36,
          child: Row(
            children: [
              Icon(
                Icons.archive,
                size: 16,
                color: colors.error,
              ),
              const SizedBox(width: 8),
              Text(
                '归档',
                style: TextStyle(fontSize: 13, color: colors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColorTheme(String? colorTheme) {
    if (colorTheme == null || colorTheme.isEmpty) {
      return Colors.blue;
    }
    try {
      // 支持 #RRGGBB 或 RRGGBB 格式
      final hex = colorTheme.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatLastAccessed(int timestamp) {
    final now = DateTime.now();
    final lastAccessed = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(lastAccessed);

    if (difference.inMinutes < 1) {
      return '刚刚访问';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${lastAccessed.month}/${lastAccessed.day}';
    }
  }
}

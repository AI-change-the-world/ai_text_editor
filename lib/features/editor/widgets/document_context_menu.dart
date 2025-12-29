import 'package:flutter/material.dart';

import '../../../data/datasources/objectbox/entities/document_meta.dart';

/// 文档右键菜单组件
/// 提供文档和文件夹的上下文操作
/// Requirements: 1.4, 1.7
class DocumentContextMenu {
  /// 构建菜单项列表
  static List<PopupMenuEntry<String>> buildMenuItems({
    required BuildContext context,
    required DocumentMeta document,
    VoidCallback? onRename,
    VoidCallback? onDelete,
    VoidCallback? onNewDocument,
    VoidCallback? onNewFolder,
    VoidCallback? onExport,
    VoidCallback? onMoveToRoot,
    VoidCallback? onDuplicate,
    VoidCallback? onCopyPath,
  }) {
    final items = <PopupMenuEntry<String>>[];

    // 文件夹特有操作
    if (document.isFolder) {
      if (onNewDocument != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'new_document',
            height: 36,
            onTap: onNewDocument,
            child: const _MenuItemContent(
              icon: Icons.note_add,
              iconColor: Colors.blue,
              label: '新建文档',
            ),
          ),
        );
      }

      if (onNewFolder != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'new_folder',
            height: 36,
            onTap: onNewFolder,
            child: _MenuItemContent(
              icon: Icons.create_new_folder,
              iconColor: Colors.amber.shade700,
              label: '新建子文件夹',
            ),
          ),
        );
      }

      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider(height: 1));
      }
    }

    // 通用操作
    if (onRename != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'rename',
          height: 36,
          onTap: onRename,
          child: const _MenuItemContent(
            icon: Icons.edit,
            iconColor: Colors.grey,
            label: '重命名',
          ),
        ),
      );
    }

    // 文档特有操作
    if (!document.isFolder) {
      if (onDuplicate != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'duplicate',
            height: 36,
            onTap: onDuplicate,
            child: const _MenuItemContent(
              icon: Icons.copy,
              iconColor: Colors.grey,
              label: '复制',
            ),
          ),
        );
      }

      if (onExport != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'export',
            height: 36,
            onTap: onExport,
            child: const _MenuItemContent(
              icon: Icons.download,
              iconColor: Colors.green,
              label: '导出',
            ),
          ),
        );
      }
    }

    // 移动到根目录
    if (onMoveToRoot != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'move_to_root',
          height: 36,
          onTap: onMoveToRoot,
          child: const _MenuItemContent(
            icon: Icons.drive_file_move,
            iconColor: Colors.orange,
            label: '移动到根目录',
          ),
        ),
      );
    }

    // 复制路径
    if (onCopyPath != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'copy_path',
          height: 36,
          onTap: onCopyPath,
          child: const _MenuItemContent(
            icon: Icons.link,
            iconColor: Colors.grey,
            label: '复制路径',
          ),
        ),
      );
    }

    // 删除操作
    if (onDelete != null) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider(height: 1));
      }
      items.add(
        PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          onTap: onDelete,
          child: const _MenuItemContent(
            icon: Icons.delete,
            iconColor: Colors.red,
            label: '删除',
            labelColor: Colors.red,
          ),
        ),
      );
    }

    return items;
  }

  /// 显示上下文菜单
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required DocumentMeta document,
    VoidCallback? onRename,
    VoidCallback? onDelete,
    VoidCallback? onNewDocument,
    VoidCallback? onNewFolder,
    VoidCallback? onExport,
    VoidCallback? onMoveToRoot,
    VoidCallback? onDuplicate,
    VoidCallback? onCopyPath,
  }) {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: buildMenuItems(
        context: context,
        document: document,
        onRename: onRename,
        onDelete: onDelete,
        onNewDocument: onNewDocument,
        onNewFolder: onNewFolder,
        onExport: onExport,
        onMoveToRoot: onMoveToRoot,
        onDuplicate: onDuplicate,
        onCopyPath: onCopyPath,
      ),
    );
  }
}

/// 菜单项内容组件
class _MenuItemContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;

  const _MenuItemContent({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

/// 导出格式选择对话框
class ExportFormatDialog extends StatelessWidget {
  final DocumentMeta document;
  final Function(String format) onExport;

  const ExportFormatDialog({
    super.key,
    required this.document,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出文档'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('选择导出格式：${document.title}'),
          const SizedBox(height: 16),
          _buildFormatOption(
            context,
            icon: Icons.code,
            label: 'Markdown (.md)',
            format: 'markdown',
          ),
          _buildFormatOption(
            context,
            icon: Icons.html,
            label: 'HTML (.html)',
            format: 'html',
          ),
          _buildFormatOption(
            context,
            icon: Icons.description,
            label: 'Word (.docx)',
            format: 'docx',
          ),
          _buildFormatOption(
            context,
            icon: Icons.picture_as_pdf,
            label: 'PDF (.pdf)',
            format: 'pdf',
            enabled: false, // PDF 导出暂未实现
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String format,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        label,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      enabled: enabled,
      onTap: enabled
          ? () {
              Navigator.of(context).pop();
              onExport(format);
            }
          : null,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../data/datasources/objectbox/entities/document_meta.dart';

/// 文档树项组件
/// 显示单个文档或文件夹的树节点
/// Requirements: 1.4
class DocumentTreeItem extends StatefulWidget {
  final DocumentMeta document;
  final int depth;
  final bool isSelected;
  final bool isExpanded;
  final bool isDragTarget;
  final bool hasChildren;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onExpandToggle;

  const DocumentTreeItem({
    super.key,
    required this.document,
    this.depth = 0,
    this.isSelected = false,
    this.isExpanded = false,
    this.isDragTarget = false,
    this.hasChildren = false,
    this.onTap,
    this.onDoubleTap,
    this.onExpandToggle,
  });

  @override
  State<DocumentTreeItem> createState() => _DocumentTreeItemState();
}

class _DocumentTreeItemState extends State<DocumentTreeItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final indentWidth = 16.0 * widget.depth + 8.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: EdgeInsets.only(
            left: indentWidth,
            right: 8,
            top: 6,
            bottom: 6,
          ),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(4),
            border: widget.isDragTarget
                ? Border.all(color: Colors.blue.shade400, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // 展开/折叠按钮
              _buildExpandButton(),
              const SizedBox(width: 4),
              // 图标
              _buildIcon(),
              const SizedBox(width: 8),
              // 标题
              Expanded(
                child: Text(
                  widget.document.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isSelected
                        ? Colors.blue.shade700
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 文档信息
              if (!widget.document.isFolder && _isHovered) ...[
                const SizedBox(width: 4),
                _buildDocumentInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isDragTarget) {
      return Colors.blue.shade50;
    }
    if (widget.isSelected) {
      return Colors.blue.shade100;
    }
    if (_isHovered) {
      return Colors.grey.shade100;
    }
    return Colors.transparent;
  }

  Widget _buildExpandButton() {
    if (!widget.document.isFolder) {
      return const SizedBox(width: 16);
    }

    if (!widget.hasChildren) {
      return const SizedBox(width: 16);
    }

    return GestureDetector(
      onTap: widget.onExpandToggle,
      child: AnimatedRotation(
        turns: widget.isExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          Icons.chevron_right,
          size: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.document.isFolder) {
      return Icon(
        widget.isExpanded ? Icons.folder_open : Icons.folder,
        size: 16,
        color: Colors.amber.shade600,
      );
    }

    // 根据文档类型显示不同图标
    return Icon(
      Icons.description,
      size: 16,
      color: Colors.blue.shade400,
    );
  }

  Widget _buildDocumentInfo() {
    final wordCount = widget.document.wordCount;
    if (wordCount == 0) return const SizedBox.shrink();

    return Text(
      _formatWordCount(wordCount),
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade500,
      ),
    );
  }

  String _formatWordCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万字';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}千字';
    }
    return '$count字';
  }
}

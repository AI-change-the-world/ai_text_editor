import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/asset.dart';
import '../../../data/datasources/objectbox/entities/document_meta.dart';
import '../../../services/document_service.dart';
import '../../workspace/widgets/asset_section.dart';
import '../notifiers/document_tree_notifier.dart';
import 'document_tree_item.dart';
import 'document_context_menu.dart';

/// 文档树组件
/// 显示工作空间中的文档和文件夹层级结构
/// Requirements: 1.4, 1.5
class DocumentTree extends ConsumerStatefulWidget {
  final Function(DocumentMeta document)? onDocumentSelected;
  final Function(DocumentMeta document)? onDocumentOpen;
  final Function(Asset asset)? onAssetSelected;
  final Function(Asset asset)? onAssetOpen;
  final VoidCallback? onCreateDocument;
  final VoidCallback? onCreateFolder;
  final bool showAssets;

  const DocumentTree({
    super.key,
    this.onDocumentSelected,
    this.onDocumentOpen,
    this.onAssetSelected,
    this.onAssetOpen,
    this.onCreateDocument,
    this.onCreateFolder,
    this.showAssets = true,
  });

  @override
  ConsumerState<DocumentTree> createState() => _DocumentTreeState();
}

class _DocumentTreeState extends ConsumerState<DocumentTree> {
  String? _dragTargetId;
  String? _dropInsertBeforeId;
  bool _dropAtRoot = false;

  @override
  Widget build(BuildContext context) {
    final treeState = ref.watch(documentTreeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: treeState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: treeState.rootNodes.isEmpty
                            ? _buildEmptyState(context)
                            : _buildTree(context, treeState),
                      ),
                      // 资产区域
                      if (widget.showAssets)
                        AssetSection(
                          onAssetSelected: widget.onAssetSelected,
                          onAssetOpen: widget.onAssetOpen,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.folder_open,
            size: 18,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '文档',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildAddMenu(context),
        ],
      ),
    );
  }

  Widget _buildAddMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.add,
        size: 18,
        color: Colors.grey.shade600,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 140),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tooltip: '新建',
      onSelected: (value) {
        switch (value) {
          case 'document':
            _showCreateDocumentDialog(context);
            break;
          case 'folder':
            _showCreateFolderDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'document',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.blue.shade400),
              const SizedBox(width: 8),
              const Text('新建文档', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'folder',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.folder, size: 16, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text('新建文件夹', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
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
              Icons.note_add,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无文档',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方 + 按钮创建第一个文档',
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

  Widget _buildTree(BuildContext context, DocumentTreeState treeState) {
    return DragTarget<DocumentMeta>(
      onWillAcceptWithDetails: (details) {
        // 允许拖拽到根目录
        return true;
      },
      onAcceptWithDetails: (details) {
        if (_dropAtRoot) {
          ref.read(documentTreeProvider.notifier).moveDocument(
                details.data.uuid,
                null,
              );
        }
        setState(() {
          _dropAtRoot = false;
          _dropInsertBeforeId = null;
        });
      },
      onMove: (details) {
        // 检查是否在列表底部空白区域
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(details.offset);
          // 如果在底部空白区域，设置为根目录拖放
          if (localPosition.dy > renderBox.size.height - 50) {
            setState(() {
              _dropAtRoot = true;
              _dragTargetId = null;
            });
          }
        }
      },
      onLeave: (data) {
        setState(() {
          _dropAtRoot = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: treeState.rootNodes.length + 1, // +1 for drop zone at end
          itemBuilder: (context, index) {
            if (index == treeState.rootNodes.length) {
              // 底部拖放区域
              return _buildDropZone(context, null, treeState);
            }
            return _buildTreeNodeWithDropZone(
              context,
              treeState.rootNodes[index],
              treeState,
              index,
              treeState.rootNodes.length,
            );
          },
        );
      },
    );
  }

  Widget _buildDropZone(
    BuildContext context,
    String? insertBeforeId,
    DocumentTreeState treeState,
  ) {
    final isActive =
        _dropInsertBeforeId == insertBeforeId && insertBeforeId != null;

    return DragTarget<DocumentMeta>(
      onWillAcceptWithDetails: (details) {
        return details.data.uuid != insertBeforeId;
      },
      onAcceptWithDetails: (details) {
        // 计算新的排序位置
        _handleReorder(details.data, insertBeforeId, null, treeState);
        setState(() {
          _dropInsertBeforeId = null;
        });
      },
      onMove: (details) {
        setState(() {
          _dropInsertBeforeId = insertBeforeId;
        });
      },
      onLeave: (data) {
        setState(() {
          _dropInsertBeforeId = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isActive ? 4 : 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade400 : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  Widget _buildTreeNodeWithDropZone(
    BuildContext context,
    DocumentTreeNode node,
    DocumentTreeState treeState,
    int index,
    int totalCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTreeNode(context, node, treeState),
      ],
    );
  }

  void _handleReorder(
    DocumentMeta draggedDoc,
    String? insertBeforeId,
    String? targetFolderId,
    DocumentTreeState treeState,
  ) {
    // 找到目标位置的排序值
    int newSortOrder = 0;

    if (insertBeforeId != null) {
      // 找到 insertBeforeId 的文档
      final targetDoc =
          _findDocumentInTree(treeState.rootNodes, insertBeforeId);
      if (targetDoc != null) {
        newSortOrder = targetDoc.sortOrder;
        targetFolderId = targetDoc.parentFolderId;
      }
    }

    ref.read(documentTreeProvider.notifier).reorderDocuments(
          draggedDoc.uuid,
          newSortOrder,
          targetFolderId,
        );
  }

  DocumentMeta? _findDocumentInTree(List<DocumentTreeNode> nodes, String uuid) {
    for (final node in nodes) {
      if (node.document.uuid == uuid) {
        return node.document;
      }
      if (node.children.isNotEmpty) {
        final found = _findDocumentInTree(node.children, uuid);
        if (found != null) return found;
      }
    }
    return null;
  }

  Widget _buildTreeNode(
    BuildContext context,
    DocumentTreeNode node,
    DocumentTreeState treeState,
  ) {
    final isSelected = treeState.selectedDocumentId == node.document.uuid;
    final isDragTarget = _dragTargetId == node.document.uuid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 拖拽目标包装
        DragTarget<DocumentMeta>(
          onWillAcceptWithDetails: (details) {
            final data = details.data;
            // 不能拖拽到自己或自己的子文件夹
            if (data.uuid == node.document.uuid) return false;
            // 只有文件夹可以接收拖拽
            if (!node.document.isFolder) return false;
            // 不能拖拽到自己的子文件夹
            if (_isDescendant(data.uuid, node.document.uuid, treeState)) {
              return false;
            }
            return true;
          },
          onAcceptWithDetails: (details) {
            final data = details.data;
            ref.read(documentTreeProvider.notifier).moveDocument(
                  data.uuid,
                  node.document.uuid,
                );
            setState(() {
              _dragTargetId = null;
            });
          },
          onMove: (details) {
            if (node.document.isFolder) {
              setState(() {
                _dragTargetId = node.document.uuid;
              });
            }
          },
          onLeave: (data) {
            setState(() {
              _dragTargetId = null;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Draggable<DocumentMeta>(
              data: node.document,
              onDragStarted: () {
                // Drag started
              },
              onDragEnd: (details) {
                setState(() {
                  _dragTargetId = null;
                });
              },
              feedback: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        node.document.isFolder
                            ? Icons.folder
                            : Icons.description,
                        size: 16,
                        color: node.document.isFolder
                            ? Colors.amber.shade600
                            : Colors.blue.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        node.document.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: _buildTreeItemContent(
                  context,
                  node,
                  isSelected,
                  isDragTarget,
                  treeState,
                ),
              ),
              child: _buildTreeItemContent(
                context,
                node,
                isSelected,
                isDragTarget,
                treeState,
              ),
            );
          },
        ),
        // 子节点
        if (node.document.isFolder && node.isExpanded)
          ...node.children
              .map((child) => _buildTreeNode(context, child, treeState)),
      ],
    );
  }

  Widget _buildTreeItemContent(
    BuildContext context,
    DocumentTreeNode node,
    bool isSelected,
    bool isDragTarget,
    DocumentTreeState treeState,
  ) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition, node.document);
      },
      child: DocumentTreeItem(
        document: node.document,
        depth: node.depth,
        isSelected: isSelected,
        isExpanded: node.isExpanded,
        isDragTarget: isDragTarget,
        hasChildren: node.children.isNotEmpty,
        onTap: () => _onItemTap(node),
        onDoubleTap: () => _onItemDoubleTap(node),
        onExpandToggle: node.document.isFolder
            ? () => ref
                .read(documentTreeProvider.notifier)
                .toggleFolderExpansion(node.document.uuid)
            : null,
      ),
    );
  }

  bool _isDescendant(String parentId, String childId, DocumentTreeState state) {
    // 检查 childId 是否是 parentId 的后代
    for (final node in state.rootNodes) {
      if (_findAndCheckDescendant(node, parentId, childId)) {
        return true;
      }
    }
    return false;
  }

  bool _findAndCheckDescendant(
    DocumentTreeNode node,
    String parentId,
    String childId,
  ) {
    if (node.document.uuid == parentId) {
      return _containsNode(node, childId);
    }
    for (final child in node.children) {
      if (_findAndCheckDescendant(child, parentId, childId)) {
        return true;
      }
    }
    return false;
  }

  bool _containsNode(DocumentTreeNode node, String targetId) {
    if (node.document.uuid == targetId) return true;
    for (final child in node.children) {
      if (_containsNode(child, targetId)) return true;
    }
    return false;
  }

  void _onItemTap(DocumentTreeNode node) {
    ref.read(documentTreeProvider.notifier).selectDocument(node.document.uuid);
    widget.onDocumentSelected?.call(node.document);

    // 如果是文件夹，切换展开状态
    if (node.document.isFolder) {
      ref
          .read(documentTreeProvider.notifier)
          .toggleFolderExpansion(node.document.uuid);
    }
  }

  void _onItemDoubleTap(DocumentTreeNode node) {
    if (!node.document.isFolder) {
      widget.onDocumentOpen?.call(node.document);
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    DocumentMeta document,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: DocumentContextMenu.buildMenuItems(
        context: context,
        document: document,
        onRename: () => _showRenameDialog(context, document),
        onDelete: () => _showDeleteConfirmDialog(context, document),
        onNewDocument: document.isFolder
            ? () => _showCreateDocumentDialog(context,
                parentFolderId: document.uuid)
            : null,
        onNewFolder: document.isFolder
            ? () =>
                _showCreateFolderDialog(context, parentFolderId: document.uuid)
            : null,
        onExport: !document.isFolder
            ? () => _showExportDialog(context, document)
            : null,
        onMoveToRoot: document.parentFolderId != null
            ? () => ref
                .read(documentTreeProvider.notifier)
                .moveDocument(document.uuid, null)
            : null,
      ),
    );
  }

  void _showCreateDocumentDialog(BuildContext context,
      {String? parentFolderId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文档'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文档名称',
            hintText: '请输入文档名称',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              ref.read(documentTreeProvider.notifier).createDocument(
                    value,
                    parentFolderId: parentFolderId,
                  );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop();
                ref.read(documentTreeProvider.notifier).createDocument(
                      controller.text,
                      parentFolderId: parentFolderId,
                    );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, {String? parentFolderId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            hintText: '请输入文件夹名称',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              ref.read(documentTreeProvider.notifier).createFolder(
                    value,
                    parentFolderId: parentFolderId,
                  );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop();
                ref.read(documentTreeProvider.notifier).createFolder(
                      controller.text,
                      parentFolderId: parentFolderId,
                    );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, DocumentMeta document) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重命名${document.isFolder ? "文件夹" : "文档"}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '名称',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              ref.read(documentTreeProvider.notifier).renameDocument(
                    document.uuid,
                    value,
                  );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.of(context).pop();
                ref.read(documentTreeProvider.notifier).renameDocument(
                      document.uuid,
                      controller.text,
                    );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DocumentMeta document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除${document.isFolder ? "文件夹" : "文档"}'),
        content: Text(
          document.isFolder
              ? '确定要删除文件夹 "${document.title}" 及其所有内容吗？此操作不可撤销。'
              : '确定要删除文档 "${document.title}" 吗？此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(documentTreeProvider.notifier)
                  .deleteDocument(document.uuid);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, DocumentMeta document) {
    showDialog(
      context: context,
      builder: (context) => ExportFormatDialog(
        document: document,
        onExport: (format) async {
          try {
            final documentService = DocumentService.instance;
            final exportFormat = _parseExportFormat(format);
            final bytes = await documentService.exportDocument(
                document.uuid, exportFormat);

            // 保存文件
            await _saveExportedFile(context, document.title, format, bytes);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('导出失败: $e')),
              );
            }
          }
        },
      ),
    );
  }

  ExportFormat _parseExportFormat(String format) {
    switch (format) {
      case 'markdown':
        return ExportFormat.markdown;
      case 'html':
        return ExportFormat.html;
      case 'docx':
        return ExportFormat.docx;
      case 'pdf':
        return ExportFormat.pdf;
      default:
        return ExportFormat.markdown;
    }
  }

  Future<void> _saveExportedFile(
    BuildContext context,
    String title,
    String format,
    Uint8List bytes,
  ) async {
    // 使用 file_selector 保存文件
    try {
      final extension = format == 'markdown' ? 'md' : format;
      final suggestedName = '$title.$extension';

      // 简单实现：显示成功消息
      // 实际实现需要使用 file_selector 包来选择保存位置
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('文档已导出: $suggestedName (${bytes.length} bytes)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

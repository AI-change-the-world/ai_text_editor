import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/datasources/objectbox/entities/document_meta.dart';
import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../editor/notifiers/document_tree_notifier.dart';
import '../notifiers/workspace_notifier.dart';
import '../widgets/create_workspace_dialog.dart';
import '../widgets/workspace_selector.dart';
import '../widgets/workspace_settings_dialog.dart';

/// 工作空间主页视图
/// Requirements: 1.1, 1.3, 1.4
class WorkspaceHomeView extends ConsumerStatefulWidget {
  final Widget? child;

  const WorkspaceHomeView({super.key, this.child});

  @override
  ConsumerState<WorkspaceHomeView> createState() => _WorkspaceHomeViewState();
}

class _WorkspaceHomeViewState extends ConsumerState<WorkspaceHomeView> {
  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);

    return Scaffold(
      body: Row(
        children: [
          WorkspaceSelector(
            onCreateWorkspace: () => _showCreateWorkspaceDialog(context),
            onSettingsPressed: (id) => _showWorkspaceSettings(context, id),
          ),
          Expanded(
            child: widget.child ?? _buildMainContent(workspaceState),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(WorkspaceState workspaceState) {
    if (workspaceState.currentWorkspace == null) {
      return _buildNoWorkspaceSelected();
    }
    return _buildWorkspaceContent(workspaceState.currentWorkspace!);
  }

  Widget _buildNoWorkspaceSelected() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspaces_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '选择一个工作空间开始',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '从左侧选择或点击 + 创建工作空间',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(Workspace workspace) {
    final colorTheme = _parseColorTheme(workspace.colorTheme);
    final treeState = ref.watch(documentTreeProvider);

    return Column(
      children: [
        // 顶部工具栏
        _buildToolbar(workspace, colorTheme),
        // 文档列表区域
        Expanded(
          child: treeState.isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : treeState.rootNodes.isEmpty
                  ? _buildEmptyDocuments(colorTheme)
                  : _buildDocumentGrid(treeState, colorTheme),
        ),
      ],
    );
  }

  Widget _buildToolbar(Workspace workspace, Color colorTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // 工作空间图标和名称
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorTheme.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: workspace.icon != null && workspace.icon!.isNotEmpty
                  ? Text(workspace.icon!, style: const TextStyle(fontSize: 18))
                  : Text(
                      workspace.name.isNotEmpty
                          ? workspace.name[0].toUpperCase()
                          : 'W',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorTheme,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            workspace.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // 新建按钮
          _buildAddButton(colorTheme),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                size: 20, color: Colors.grey.shade600),
            onPressed: () => _showWorkspaceSettings(context, workspace.uuid),
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color colorTheme) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        if (value == 'document') {
          _showCreateDocumentDialog(context);
        } else if (value == 'folder') {
          _showCreateFolderDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'document',
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: Colors.blue.shade400),
              const SizedBox(width: 10),
              const Text('新建文档'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'folder',
          child: Row(
            children: [
              Icon(Icons.folder_outlined,
                  size: 18, color: Colors.amber.shade600),
              const SizedBox(width: 10),
              const Text('新建文件夹'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorTheme,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: Colors.white),
            SizedBox(width: 6),
            Text('新建',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDocuments(Color colorTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorTheme.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.note_add_outlined,
                size: 40, color: colorTheme.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            '还没有文档',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方「新建」按钮创建第一个文档',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid(DocumentTreeState treeState, Color colorTheme) {
    // 扁平化显示所有文档和文件夹
    final items = <_DocumentItem>[];
    _flattenTree(treeState.rootNodes, items);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildDocumentCard(item, colorTheme, treeState);
        },
      ),
    );
  }

  void _flattenTree(List<DocumentTreeNode> nodes, List<_DocumentItem> items) {
    for (final node in nodes) {
      items.add(_DocumentItem(node.document, node.depth));
      if (node.document.isFolder && node.isExpanded) {
        _flattenTree(node.children, items);
      }
    }
  }

  Widget _buildDocumentCard(
      _DocumentItem item, Color colorTheme, DocumentTreeState treeState) {
    final doc = item.document;
    final isSelected = treeState.selectedDocumentId == doc.uuid;

    return GestureDetector(
      onTap: () {
        ref.read(documentTreeProvider.notifier).selectDocument(doc.uuid);
        if (doc.isFolder) {
          ref
              .read(documentTreeProvider.notifier)
              .toggleFolderExpansion(doc.uuid);
        }
      },
      onDoubleTap: () {
        if (!doc.isFolder) {
          context.push('/editor', extra: doc);
        }
      },
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, details.globalPosition, doc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? colorTheme.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorTheme : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    doc.isFolder ? Colors.amber.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                doc.isFolder ? Icons.folder_rounded : Icons.description_rounded,
                size: 28,
                color:
                    doc.isFolder ? Colors.amber.shade600 : Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                doc.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (!doc.isFolder) ...[
              const SizedBox(height: 4),
              Text(
                '${doc.wordCount} 字',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
      BuildContext context, Offset position, DocumentMeta doc) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        if (!doc.isFolder)
          PopupMenuItem(
            onTap: () => context.push('/editor', extra: doc),
            child: const Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 10),
                Text('编辑'),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () => _showRenameDialog(context, doc),
          child: const Row(
            children: [
              Icon(Icons.drive_file_rename_outline, size: 18),
              SizedBox(width: 10),
              Text('重命名'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => _showDeleteDialog(context, doc),
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
              const SizedBox(width: 10),
              Text('删除', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateDocumentDialog(BuildContext context) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => _buildInputDialog(
        title: '新建文档',
        hint: '输入文档名称',
        controller: controller,
        onConfirm: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.pop(context);
            ref
                .read(documentTreeProvider.notifier)
                .createDocument(controller.text.trim());
          }
        },
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => _buildInputDialog(
        title: '新建文件夹',
        hint: '输入文件夹名称',
        controller: controller,
        onConfirm: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.pop(context);
            ref
                .read(documentTreeProvider.notifier)
                .createFolder(controller.text.trim());
          }
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, DocumentMeta doc) {
    final controller = TextEditingController(text: doc.title);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => _buildInputDialog(
        title: '重命名',
        hint: '输入新名称',
        controller: controller,
        onConfirm: () {
          if (controller.text.trim().isNotEmpty) {
            Navigator.pop(context);
            ref
                .read(documentTreeProvider.notifier)
                .renameDocument(doc.uuid, controller.text.trim());
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DocumentMeta doc) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  '确定删除「${doc.title}」？',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  doc.isFolder ? '文件夹内的所有内容也会被删除' : '此操作不可撤销',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(documentTreeProvider.notifier)
                              .deleteDocument(doc.uuid);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('删除'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onConfirm,
  }) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onSubmitted: (_) => onConfirm(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Spacer(),
                  SizedBox(
                    width: 80,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context) async {
    final result = await showCreateWorkspaceDialog(context);
    if (result != null && result is Workspace) {
      ref.read(workspaceProvider.notifier).switchWorkspace(result.uuid);
    }
  }

  Future<void> _showWorkspaceSettings(
      BuildContext context, String workspaceId) async {
    final workspaceState = ref.read(workspaceProvider);
    final workspace = workspaceState.workspaces.firstWhere(
      (w) => w.uuid == workspaceId,
      orElse: () => Workspace.empty(),
    );
    if (workspace.uuid.isEmpty) return;
    await showWorkspaceSettingsDialog(context, workspace);
  }

  Color _parseColorTheme(String? colorTheme) {
    if (colorTheme == null || colorTheme.isEmpty) return Colors.blue;
    try {
      final hex = colorTheme.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class _DocumentItem {
  final DocumentMeta document;
  final int depth;
  _DocumentItem(this.document, this.depth);
}

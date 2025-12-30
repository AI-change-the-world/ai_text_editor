import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xml/xml.dart';

import '../../../data/datasources/objectbox/entities/document_meta.dart';
import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/name_to_icon.dart';
import '../../editor/notifiers/document_tree_notifier.dart';
import '../notifiers/workspace_notifier.dart';
import '../widgets/create_workspace_dialog.dart';
import '../widgets/welcome_dialog.dart';
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
  static bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    // 首次启动时显示欢迎弹窗
    if (!_hasShownWelcome) {
      _hasShownWelcome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showWelcomeDialog(context);
      });
    }
  }

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
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspaces_outline, size: 64, color: colors.textHint),
          const SizedBox(height: 16),
          Text(
            '选择一个工作空间开始',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '从左侧选择或点击 + 创建工作空间',
            style: TextStyle(fontSize: 14, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceContent(Workspace workspace) {
    final colors = context.colors;
    final colorTheme = _parseColorTheme(workspace.colorTheme);
    final treeState = ref.watch(documentTreeProvider);

    return Column(
      children: [
        // 顶部工具栏
        _buildToolbar(workspace, colorTheme, colors),
        // 文档列表区域
        Expanded(
          child: treeState.isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : treeState.rootNodes.isEmpty
                  ? _buildEmptyDocuments(colorTheme, colors)
                  : _buildDocumentGrid(treeState, colorTheme, colors),
        ),
      ],
    );
  }

  Widget _buildToolbar(
      Workspace workspace, Color colorTheme, AppColors colors) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // 工作空间图标和名称
          _buildWorkspaceIcon(workspace, colorTheme),
          const SizedBox(width: 12),
          Text(
            workspace.name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary),
          ),
          const Spacer(),
          // 新建按钮
          _buildAddButton(colorTheme, colors),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                size: 20, color: colors.textSecondary),
            onPressed: () => _showWorkspaceSettings(context, workspace.uuid),
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color colorTheme, AppColors colors) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colors.dialogBackground,
      onSelected: (value) {
        if (value == 'document') {
          _showCreateDocumentDialog(context);
        } else if (value == 'import') {
          _importDocument(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'document',
          child: Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Text('新建文档', style: TextStyle(color: colors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_upload_outlined, size: 18, color: colors.success),
              const SizedBox(width: 10),
              Text('导入文档', style: TextStyle(color: colors.textPrimary)),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: colors.dialogBackground),
            const SizedBox(width: 6),
            Text('新建',
                style: TextStyle(
                    color: colors.dialogBackground,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDocuments(Color colorTheme, AppColors colors) {
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
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方「新建」按钮创建第一个文档',
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid(
      DocumentTreeState treeState, Color colorTheme, AppColors colors) {
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
          return _buildDocumentCard(item, colorTheme, treeState, colors);
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

  Widget _buildDocumentCard(_DocumentItem item, Color colorTheme,
      DocumentTreeState treeState, AppColors colors) {
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
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorTheme : colors.border,
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
                color: doc.isFolder
                    ? colors.warning.withValues(alpha: 0.1)
                    : colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                doc.isFolder ? Icons.folder_rounded : Icons.description_rounded,
                size: 28,
                color: doc.isFolder ? colors.warning : colors.primary,
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
                  color: colors.textPrimary,
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
                style: TextStyle(fontSize: 11, color: colors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContextMenu(
      BuildContext context, Offset position, DocumentMeta doc) {
    final colors = context.colors;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colors.dialogBackground,
      items: [
        if (!doc.isFolder)
          PopupMenuItem(
            onTap: () => context.push('/editor', extra: doc),
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: colors.textSecondary),
                const SizedBox(width: 10),
                Text('编辑', style: TextStyle(color: colors.textPrimary)),
              ],
            ),
          ),
        PopupMenuItem(
          onTap: () => _showRenameDialog(context, doc),
          child: Row(
            children: [
              Icon(Icons.drive_file_rename_outline,
                  size: 18, color: colors.textSecondary),
              const SizedBox(width: 10),
              Text('重命名', style: TextStyle(color: colors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => _showDeleteDialog(context, doc),
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: colors.error),
              const SizedBox(width: 10),
              Text('删除', style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateDocumentDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = context.colors;
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
        colors: colors,
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

  Future<void> _importDocument(BuildContext context) async {
    const typeGroup = XTypeGroup(
      label: '文档',
      extensions: ['txt', 'md', 'markdown', 'docx', 'doc'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      try {
        String content = '';
        final filePath = file.path;
        final extension = filePath.split('.').last.toLowerCase();

        if (extension == 'txt' ||
            extension == 'md' ||
            extension == 'markdown') {
          // 纯文本和 Markdown 文件直接读取
          content = await File(filePath).readAsString();
        } else if (extension == 'docx' || extension == 'doc') {
          // Word 文档需要解析
          content = await _parseDocxFile(filePath);
        }

        if (content.isNotEmpty && mounted) {
          // 使用文件名（不含扩展名）作为文档标题
          final fileName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          await ref
              .read(documentTreeProvider.notifier)
              .createDocumentWithContent(fileName, content);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<String> _parseDocxFile(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 查找 word/document.xml
      final documentFile = archive.files.firstWhere(
        (file) => file.name == 'word/document.xml',
        orElse: () => throw Exception('无效的 docx 文件'),
      );

      final xmlContent = utf8.decode(documentFile.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      // 提取所有文本内容
      final buffer = StringBuffer();
      final paragraphs = document.findAllElements('w:p');

      for (final p in paragraphs) {
        final texts = p.findAllElements('w:t');
        for (final t in texts) {
          buffer.write(t.innerText);
        }
        buffer.writeln();
      }

      return buffer.toString().trim();
    } catch (e) {
      throw Exception('解析 Word 文档失败: $e');
    }
  }

  void _showRenameDialog(BuildContext context, DocumentMeta doc) {
    final controller = TextEditingController(text: doc.title);
    final colors = context.colors;
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
        colors: colors,
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
    final colors = context.colors;
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
              color: colors.dialogBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  '确定删除「${doc.title}」？',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  doc.isFolder ? '文件夹内的所有内容也会被删除' : '此操作不可撤销',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('取消',
                            style: TextStyle(color: colors.textSecondary)),
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
                          backgroundColor: colors.error,
                          foregroundColor: colors.dialogBackground,
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
    required AppColors colors,
    required VoidCallback onConfirm,
  }) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.dialogBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: colors.textHint),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onSubmitted: (_) => onConfirm(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: 80,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消',
                          style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.dialogBackground,
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

  Widget _buildWorkspaceIcon(Workspace workspace, Color colorTheme) {
    // 如果有 emoji 图标
    if (workspace.icon != null && workspace.icon!.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorTheme.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(workspace.icon!, style: const TextStyle(fontSize: 18)),
        ),
      );
    }

    // 使用 Identicon 生成图标
    final iconData = Identicon.generate(workspace.name, size: 128);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        iconData,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
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

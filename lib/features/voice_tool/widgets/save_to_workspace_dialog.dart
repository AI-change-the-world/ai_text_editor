import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../../utils/app_theme.dart';
import '../../workspace/notifiers/workspace_notifier.dart';

/// 保存到工作空间弹窗
/// 选择目标工作空间并保存内容
class SaveToWorkspaceDialog extends ConsumerStatefulWidget {
  final String content;
  final String? summary;
  final String sourceType;
  final String? sourceUrl;
  final String? audioFileName;

  const SaveToWorkspaceDialog({
    super.key,
    required this.content,
    this.summary,
    required this.sourceType,
    this.sourceUrl,
    this.audioFileName,
  });

  @override
  ConsumerState<SaveToWorkspaceDialog> createState() =>
      _SaveToWorkspaceDialogState();
}

class _SaveToWorkspaceDialogState extends ConsumerState<SaveToWorkspaceDialog> {
  final TextEditingController _titleController = TextEditingController();
  String? _selectedWorkspaceId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 生成默认标题
    _titleController.text = _generateDefaultTitle();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    switch (widget.sourceType) {
      case 'transcription':
        return '语音转录 $dateStr $timeStr';
      case 'deep-search':
        return '搜索结果 $dateStr $timeStr';
      default:
        return '新文档 $dateStr $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final workspaceState = ref.watch(workspaceProvider);
    final workspaces = workspaceState.workspaces;

    // 默认选择当前工作空间
    _selectedWorkspaceId ??= workspaceState.currentWorkspace?.uuid;

    return Dialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            _buildHeader(colors),
            const SizedBox(height: 20),
            // 文档标题输入
            _buildTitleInput(colors),
            const SizedBox(height: 16),
            // 工作空间选择
            _buildWorkspaceSelector(workspaces, colors),
            const SizedBox(height: 16),
            // 内容预览
            _buildContentPreview(colors),
            const SizedBox(height: 20),
            // 操作按钮
            _buildActionButtons(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Row(
      children: [
        Icon(Icons.save, color: colors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          '保存到工作空间',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.close, color: colors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTitleInput(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文档标题',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '输入文档标题',
            hintStyle: TextStyle(color: colors.textHint),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceSelector(List<Workspace> workspaces, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择工作空间',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWorkspaceId,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              dropdownColor: colors.dialogBackground,
              borderRadius: BorderRadius.circular(8),
              items: workspaces.map((workspace) {
                return DropdownMenuItem<String>(
                  value: workspace.uuid,
                  child: Row(
                    children: [
                      if (workspace.icon != null && workspace.icon!.isNotEmpty)
                        Text(workspace.icon!,
                            style: const TextStyle(fontSize: 16))
                      else
                        Icon(Icons.folder,
                            size: 18, color: colors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          workspace.name,
                          style: TextStyle(color: colors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWorkspaceId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentPreview(AppColors colors) {
    final previewText = widget.content.length > 200
        ? '${widget.content.substring(0, 200)}...'
        : widget.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '内容预览',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.content.length} 字',
              style: TextStyle(
                fontSize: 12,
                color: colors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: SingleChildScrollView(
            child: Text(
              previewText,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        if (widget.summary != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: colors.primary),
                const SizedBox(width: 4),
                Text(
                  '包含摘要',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isSaving || _selectedWorkspaceId == null
              ? null
              : _saveToWorkspace,
          icon: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.dialogBackground,
                  ),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? '保存中...' : '保存'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.dialogBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _saveToWorkspace() async {
    if (_selectedWorkspaceId == null || _titleController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: 调用实际的保存服务
      // 这里先模拟
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存到工作空间'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }
}

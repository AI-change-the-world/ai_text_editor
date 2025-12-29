import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/objectbox/entities/workspace.dart';
import '../../../services/workspace_service.dart';
import '../notifiers/workspace_notifier.dart';

/// 预定义的颜色主题
const List<Color> _predefinedColors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.amber,
  Colors.cyan,
];

/// 预定义的 emoji 图标
const List<String> _predefinedEmojis = [
  '📚',
  '💼',
  '🎯',
  '💡',
  '🔬',
  '📝',
  '🎨',
  '🚀',
  '⭐',
  '🏠',
  '📊',
  '🔧',
  '🎵',
  '📷',
  '🌍',
];

/// 工作空间设置对话框
/// 支持编辑名称、图标、颜色主题、描述和分类
/// Requirements: 1.2
class WorkspaceSettingsDialog extends ConsumerStatefulWidget {
  final Workspace workspace;

  const WorkspaceSettingsDialog({
    super.key,
    required this.workspace,
  });

  @override
  ConsumerState<WorkspaceSettingsDialog> createState() =>
      _WorkspaceSettingsDialogState();
}

class _WorkspaceSettingsDialogState
    extends ConsumerState<WorkspaceSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;

  late String? _selectedEmoji;
  late Color _selectedColor;
  bool _isSaving = false;
  bool _hasChanges = false;

  WorkspaceStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspace.name);
    _descriptionController =
        TextEditingController(text: widget.workspace.description ?? '');
    _categoryController =
        TextEditingController(text: widget.workspace.category ?? '');

    _selectedEmoji = widget.workspace.icon;
    _selectedColor = _parseColorTheme(widget.workspace.colorTheme);

    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _categoryController.addListener(_onFieldChanged);

    _loadStats();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _categoryController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await ref
        .read(workspaceProvider.notifier)
        .getWorkspaceStats(widget.workspace.uuid);
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Color _parseColorTheme(String? colorTheme) {
    if (colorTheme == null || colorTheme.isEmpty) {
      return Colors.blue;
    }
    try {
      final hex = colorTheme.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            _buildHeader(),
            const Divider(height: 1),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 统计信息
                      _buildStatsSection(),
                      const SizedBox(height: 24),

                      // 图标选择
                      _buildIconSection(),
                      const SizedBox(height: 20),

                      // 名称输入
                      _buildNameField(),
                      const SizedBox(height: 16),

                      // 描述输入
                      _buildDescriptionField(),
                      const SizedBox(height: 16),

                      // 分类输入
                      _buildCategoryField(),
                      const SizedBox(height: 20),

                      // 颜色选择
                      _buildColorSection(),
                      const SizedBox(height: 24),

                      // 危险操作区域
                      _buildDangerZone(),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 操作按钮
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.settings, color: _selectedColor),
          const SizedBox(width: 8),
          const Text(
            '工作空间设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _isLoadingStats
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.description,
                  label: '文档',
                  value: '${_stats?.documentCount ?? 0}',
                ),
                _buildStatItem(
                  icon: Icons.text_fields,
                  label: '字数',
                  value: _formatNumber(_stats?.totalWords ?? 0),
                ),
                _buildStatItem(
                  icon: Icons.attachment,
                  label: '资产',
                  value: '${_stats?.assetCount ?? 0}',
                ),
                _buildStatItem(
                  icon: Icons.storage,
                  label: '存储',
                  value: _formatBytes(_stats?.storageUsageBytes ?? 0),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildIconSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图标',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标预览
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _selectedColor.withValues(alpha: 0.3)),
              ),
              child: _buildIconPreview(),
            ),
            const SizedBox(width: 16),
            // Emoji 选择器
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildEmojiButton(null, isSelected: _selectedEmoji == null),
                  ..._predefinedEmojis.map(
                    (emoji) => _buildEmojiButton(
                      emoji,
                      isSelected: _selectedEmoji == emoji,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    if (_selectedEmoji != null && _selectedEmoji!.isNotEmpty) {
      return Center(
        child: Text(
          _selectedEmoji!,
          style: const TextStyle(fontSize: 28),
        ),
      );
    }
    return Center(
      child: Text(
        _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : 'W',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _selectedColor,
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String? emoji, {required bool isSelected}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedEmoji = emoji;
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedColor.withValues(alpha: 0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: emoji != null
              ? Text(emoji, style: const TextStyle(fontSize: 16))
              : Icon(
                  Icons.text_fields,
                  size: 16,
                  color: isSelected ? _selectedColor : Colors.grey.shade500,
                ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: '名称 *',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入工作空间名称';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: '描述',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '主题色',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _predefinedColors.map((color) {
            final isSelected = _selectedColor.toARGB32() == color.toARGB32();
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                  _hasChanges = true;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black54 : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                '危险操作',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '归档工作空间',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '归档后将从列表中隐藏，可在设置中恢复',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _archiveWorkspace,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                child: const Text('归档'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '删除工作空间',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '永久删除，包括所有文档和资产，无法恢复',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _deleteWorkspace,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: (_isSaving || !_hasChanges) ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final colorHex =
          '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      final request = UpdateWorkspaceRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        icon: _selectedEmoji,
        colorTheme: colorHex,
        category: _categoryController.text.trim().isNotEmpty
            ? _categoryController.text.trim()
            : null,
      );

      await ref
          .read(workspaceProvider.notifier)
          .updateWorkspace(widget.workspace.uuid, request);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _archiveWorkspace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('归档工作空间'),
        content: Text('确定要归档工作空间 "${widget.workspace.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('归档'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(workspaceProvider.notifier)
          .archiveWorkspace(widget.workspace.uuid);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _deleteWorkspace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除工作空间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要永久删除工作空间 "${widget.workspace.name}" 吗？'),
            const SizedBox(height: 8),
            Text(
              '此操作将删除所有文档和资产，无法恢复！',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(workspaceProvider.notifier)
          .deleteWorkspace(widget.workspace.uuid);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

/// 显示工作空间设置对话框
Future<bool?> showWorkspaceSettingsDialog(
  BuildContext context,
  Workspace workspace,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => WorkspaceSettingsDialog(workspace: workspace),
  );
}

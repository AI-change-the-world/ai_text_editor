import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/workspace_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/name_to_icon.dart';
import '../notifiers/workspace_notifier.dart';

/// 预定义的颜色主题
const List<Color> _predefinedColors = [
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFF8B5CF6), // Purple
  Color(0xFFEF4444), // Red
  Color(0xFF14B8A6), // Teal
  Color(0xFF6366F1), // Indigo
  Color(0xFFEC4899), // Pink
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
];

/// 显示创建工作空间对话框
/// Requirements: 1.2
Future<dynamic> showCreateWorkspaceDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _CreateWorkspaceDialogContent();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ).drive(Tween(begin: 0.9, end: 1.0)),
          child: child,
        ),
      );
    },
  );
}

class _CreateWorkspaceDialogContent extends ConsumerStatefulWidget {
  const _CreateWorkspaceDialogContent();

  @override
  ConsumerState<_CreateWorkspaceDialogContent> createState() =>
      _CreateWorkspaceDialogContentState();
}

class _CreateWorkspaceDialogContentState
    extends ConsumerState<_CreateWorkspaceDialogContent> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedEmoji;
  Color _selectedColor = _predefinedColors.first;
  Uint8List? _generatedIcon;
  bool _isCreating = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_selectedEmoji == null && _nameController.text.isNotEmpty) {
      setState(() {
        _generatedIcon = Identicon.generate(_nameController.text, size: 64);
        _nameError = null;
      });
    } else if (_nameController.text.isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.dialogBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(colors),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIconSection(colors),
                      const SizedBox(height: 24),
                      _buildNameField(colors),
                      const SizedBox(height: 16),
                      _buildDescriptionField(colors),
                      const SizedBox(height: 24),
                      _buildColorSection(colors),
                      const SizedBox(height: 28),
                      _buildActions(colors),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.workspaces_rounded,
              color: _selectedColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '新建工作空间',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildIconSection(AppColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图标预览
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _selectedColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedColor.withValues(alpha: 0.2),
            ),
          ),
          child: _buildIconPreview(),
        ),
        const SizedBox(width: 16),
        // Emoji 选择器
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择图标',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildEmojiButton(null,
                      isSelected: _selectedEmoji == null, colors: colors),
                  ..._predefinedEmojis.map(
                    (emoji) => _buildEmojiButton(
                      emoji,
                      isSelected: _selectedEmoji == emoji,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    if (_selectedEmoji != null) {
      return Center(
        child: Text(_selectedEmoji!, style: const TextStyle(fontSize: 36)),
      );
    } else if (_generatedIcon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _generatedIcon!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'W',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: _selectedColor,
          ),
        ),
      );
    }
  }

  Widget _buildEmojiButton(String? emoji,
      {required bool isSelected, required AppColors colors}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmoji = emoji;
          if (emoji == null && _nameController.text.isNotEmpty) {
            _generatedIcon = Identicon.generate(_nameController.text, size: 64);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? _selectedColor.withValues(alpha: 0.15)
              : colors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _selectedColor : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: emoji != null
              ? Text(emoji, style: const TextStyle(fontSize: 18))
              : Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: isSelected ? _selectedColor : colors.textHint,
                ),
        ),
      ),
    );
  }

  Widget _buildNameField(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '名称',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: TextStyle(fontSize: 15, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '输入工作空间名称',
            hintStyle: TextStyle(color: colors.textHint),
            filled: true,
            fillColor: colors.inputBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: BorderSide(color: _selectedColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.error),
            ),
            errorText: _nameError,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '描述（可选）',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          style: TextStyle(fontSize: 15, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '简要描述这个工作空间',
            hintStyle: TextStyle(color: colors.textHint),
            filled: true,
            fillColor: colors.inputBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              borderSide: BorderSide(color: _selectedColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主题色',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _predefinedColors.map((color) {
            final isSelected = _selectedColor == color;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colors.dialogBackground
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          size: 16, color: colors.dialogBackground)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colors.border),
              ),
            ),
            child: Text(
              '取消',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createWorkspace,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: colors.dialogBackground,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isCreating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          colors.dialogBackground),
                    ),
                  )
                : const Text(
                    '创建工作空间',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _createWorkspace() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = '请输入工作空间名称');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final colorHex =
          '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      final request = CreateWorkspaceRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        icon: _selectedEmoji,
        colorTheme: colorHex,
      );

      final workspace =
          await ref.read(workspaceProvider.notifier).createWorkspace(request);

      if (mounted) {
        Navigator.of(context).pop(workspace);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}

/// 兼容旧的 Dialog 组件调用方式
class CreateWorkspaceDialog extends ConsumerWidget {
  const CreateWorkspaceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 直接返回内容组件，用于 showDialog 调用
    return const _CreateWorkspaceDialogContent();
  }
}

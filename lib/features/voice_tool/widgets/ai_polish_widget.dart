import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';

/// AI 润色风格
enum PolishStyle {
  formal('正式', '适合商务、学术场景'),
  casual('口语化', '更自然、易读'),
  concise('精简', '去除冗余，保留核心'),
  academic('学术', '严谨、专业的表达');

  final String label;
  final String description;
  const PolishStyle(this.label, this.description);
}

/// AI 优化组件
/// 显示原文和优化后文本对比
class AIPolishWidget extends ConsumerStatefulWidget {
  final String originalText;

  const AIPolishWidget({
    super.key,
    required this.originalText,
  });

  @override
  ConsumerState<AIPolishWidget> createState() => _AIPolishWidgetState();
}

class _AIPolishWidgetState extends ConsumerState<AIPolishWidget> {
  PolishStyle _selectedStyle = PolishStyle.formal;
  String? _polishedText;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            _buildHeader(colors),
            const SizedBox(height: 16),
            // 风格选择
            _buildStyleSelector(colors),
            const SizedBox(height: 16),
            // 对比区域
            Expanded(
              child: _buildComparisonArea(colors),
            ),
            const SizedBox(height: 16),
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
        Icon(Icons.auto_fix_high, color: colors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          'AI 优化',
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

  Widget _buildStyleSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择优化风格',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PolishStyle.values.map((style) {
            final isSelected = _selectedStyle == style;
            return ChoiceChip(
              label: Text(style.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStyle = style;
                    _polishedText = null; // 重置结果
                  });
                }
              },
              selectedColor: colors.primaryLight,
              backgroundColor: colors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildComparisonArea(AppColors colors) {
    return Row(
      children: [
        // 原文
        Expanded(
          child: _buildTextPanel(
            title: '原文',
            text: widget.originalText,
            colors: colors,
            isOriginal: true,
          ),
        ),
        const SizedBox(width: 16),
        // 优化后
        Expanded(
          child: _buildTextPanel(
            title: '优化后',
            text: _polishedText,
            colors: colors,
            isOriginal: false,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildTextPanel({
    required String title,
    required String? text,
    required AppColors colors,
    required bool isOriginal,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOriginal
              ? colors.border
              : colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOriginal ? colors.surface : colors.primaryLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  isOriginal ? Icons.text_fields : Icons.auto_awesome,
                  size: 16,
                  color: isOriginal ? colors.textSecondary : colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isOriginal ? colors.textSecondary : colors.primary,
                  ),
                ),
              ],
            ),
          ),
          // 内容区
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '正在优化...',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : text == null
                    ? Center(
                        child: Text(
                          '点击"开始优化"生成结果',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textHint,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return Row(
      children: [
        // 开始优化按钮
        if (_polishedText == null)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _startPolish,
            icon: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.dialogBackground,
                    ),
                  )
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(_isLoading ? '优化中...' : '开始优化'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.dialogBackground,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        // 重新优化按钮
        if (_polishedText != null)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _startPolish,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重新优化'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        const Spacer(),
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: 12),
        // 应用按钮
        ElevatedButton(
          onPressed: _polishedText != null
              ? () => Navigator.of(context).pop(_polishedText)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.success,
            foregroundColor: colors.dialogBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('应用'),
        ),
      ],
    );
  }

  Future<void> _startPolish() async {
    setState(() {
      _isLoading = true;
      _polishedText = null;
    });

    // TODO: 调用实际的 AI 服务进行润色
    // 这里先模拟
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _polishedText = _simulatePolish(widget.originalText, _selectedStyle);
      });
    }
  }

  String _simulatePolish(String text, PolishStyle style) {
    // 模拟不同风格的润色结果
    switch (style) {
      case PolishStyle.formal:
        return '【正式版】$text\n\n经过优化，文本更加正式、专业。';
      case PolishStyle.casual:
        return '【口语版】$text\n\n经过优化，文本更加自然、易读。';
      case PolishStyle.concise:
        return '【精简版】${text.substring(0, (text.length * 0.7).toInt())}...';
      case PolishStyle.academic:
        return '【学术版】$text\n\n经过优化，文本更加严谨、专业。';
    }
  }
}

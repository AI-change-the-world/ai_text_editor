import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';

/// 摘要长度
enum SummaryLength {
  brief('简短', '约 50 字'),
  standard('标准', '约 150 字'),
  detailed('详细', '约 300 字');

  final String label;
  final String description;
  const SummaryLength(this.label, this.description);
}

/// 摘要生成组件
/// 从转录文本生成摘要
class SummaryGeneratorWidget extends ConsumerStatefulWidget {
  final String sourceText;

  const SummaryGeneratorWidget({
    super.key,
    required this.sourceText,
  });

  @override
  ConsumerState<SummaryGeneratorWidget> createState() =>
      _SummaryGeneratorWidgetState();
}

class _SummaryGeneratorWidgetState
    extends ConsumerState<SummaryGeneratorWidget> {
  SummaryLength _selectedLength = SummaryLength.standard;
  String? _summary;
  List<String>? _keyPoints;
  List<String>? _actionItems;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            _buildHeader(colors),
            const SizedBox(height: 16),
            // 长度选择
            _buildLengthSelector(colors),
            const SizedBox(height: 16),
            // 生成结果
            if (_isLoading)
              _buildLoadingState(colors)
            else if (_summary != null)
              _buildResultSection(colors)
            else
              _buildEmptyState(colors),
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
        Icon(Icons.summarize, color: colors.warning, size: 24),
        const SizedBox(width: 12),
        Text(
          '生成摘要',
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

  Widget _buildLengthSelector(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '摘要长度',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: SummaryLength.values.map((length) {
            final isSelected = _selectedLength == length;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLength = length;
                    _summary = null;
                    _keyPoints = null;
                    _actionItems = null;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: length != SummaryLength.detailed ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryLight
                        : colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        length.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? colors.primary : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        length.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppColors colors) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              '正在生成摘要...',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 36, color: colors.textHint),
            const SizedBox(height: 12),
            Text(
              '点击"生成摘要"开始',
              style: TextStyle(
                fontSize: 14,
                color: colors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(AppColors colors) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 摘要
            _buildResultCard(
              title: '摘要',
              icon: Icons.short_text,
              content: _summary!,
              colors: colors,
            ),
            // 要点
            if (_keyPoints != null && _keyPoints!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildResultCard(
                title: '要点',
                icon: Icons.list,
                content: _keyPoints!.map((p) => '• $p').join('\n'),
                colors: colors,
              ),
            ],
            // 行动项
            if (_actionItems != null && _actionItems!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildResultCard(
                title: '行动项',
                icon: Icons.check_circle_outline,
                content: _actionItems!.map((a) => '☐ $a').join('\n'),
                colors: colors,
                accentColor: colors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required String content,
    required AppColors colors,
    Color? accentColor,
  }) {
    final color = accentColor ?? colors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return Row(
      children: [
        // 生成按钮
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateSummary,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.dialogBackground,
                  ),
                )
              : Icon(
                  _summary != null ? Icons.refresh : Icons.auto_awesome,
                  size: 18,
                ),
          label: Text(_summary != null ? '重新生成' : '生成摘要'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.warning,
            foregroundColor: colors.dialogBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
        const Spacer(),
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: 12),
        // 使用按钮
        ElevatedButton(
          onPressed: _summary != null
              ? () => Navigator.of(context).pop(_buildFullSummary())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.dialogBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('使用'),
        ),
      ],
    );
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _summary = null;
      _keyPoints = null;
      _actionItems = null;
    });

    // TODO: 调用实际的 AI 服务生成摘要
    // 这里先模拟
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _summary = _simulateSummary(widget.sourceText, _selectedLength);
        _keyPoints = _simulateKeyPoints();
        _actionItems = _simulateActionItems();
      });
    }
  }

  String _simulateSummary(String text, SummaryLength length) {
    final baseLength = switch (length) {
      SummaryLength.brief => 50,
      SummaryLength.standard => 150,
      SummaryLength.detailed => 300,
    };

    final truncated =
        text.length > baseLength ? '${text.substring(0, baseLength)}...' : text;

    return '这是一段关于"$truncated"的${length.label}摘要。主要内容涵盖了语音转录的核心要点。';
  }

  List<String> _simulateKeyPoints() {
    return [
      '语音识别技术的应用场景',
      '实时转录的技术实现',
      '内容总结的重要性',
    ];
  }

  List<String> _simulateActionItems() {
    return [
      '完善语音识别模型',
      '优化转录准确率',
    ];
  }

  String _buildFullSummary() {
    final buffer = StringBuffer();
    buffer.writeln('## 摘要');
    buffer.writeln(_summary);

    if (_keyPoints != null && _keyPoints!.isNotEmpty) {
      buffer.writeln('\n## 要点');
      for (final point in _keyPoints!) {
        buffer.writeln('- $point');
      }
    }

    if (_actionItems != null && _actionItems!.isNotEmpty) {
      buffer.writeln('\n## 行动项');
      for (final item in _actionItems!) {
        buffer.writeln('- [ ] $item');
      }
    }

    return buffer.toString();
  }
}

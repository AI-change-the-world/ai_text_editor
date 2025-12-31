import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

/// 转录文本显示组件
/// 显示已确认和待确认的转录文本
class TranscriptionTextView extends StatefulWidget {
  final String confirmedText;
  final String pendingText;
  final bool editable;
  final ValueChanged<String>? onTextChanged;

  const TranscriptionTextView({
    super.key,
    required this.confirmedText,
    required this.pendingText,
    this.editable = false,
    this.onTextChanged,
  });

  @override
  State<TranscriptionTextView> createState() => _TranscriptionTextViewState();
}

class _TranscriptionTextViewState extends State<TranscriptionTextView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(TranscriptionTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当文本更新时自动滚动到底部
    if (widget.confirmedText != oldWidget.confirmedText ||
        widget.pendingText != oldWidget.pendingText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasContent =
        widget.confirmedText.isNotEmpty || widget.pendingText.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: hasContent ? _buildTextContent(colors) : _buildEmptyState(colors),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.text_fields,
            size: 48,
            color: colors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            '转录文本将显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(AppColors colors) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
        TextSpan(
          children: [
            // 已确认文本
            if (widget.confirmedText.isNotEmpty)
              TextSpan(
                text: widget.confirmedText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: colors.textPrimary,
                ),
              ),
            // 待确认文本（不同颜色）
            if (widget.pendingText.isNotEmpty)
              TextSpan(
                text: widget.pendingText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: colors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

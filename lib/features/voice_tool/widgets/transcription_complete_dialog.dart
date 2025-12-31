import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';
import 'ai_polish_widget.dart';
import 'summary_generator_widget.dart';
import 'save_to_workspace_dialog.dart';

/// 转录完成弹窗
/// 显示转录结果，提供 AI 优化、生成摘要、保存到工作空间等操作
class TranscriptionCompleteDialog extends ConsumerStatefulWidget {
  final String transcriptionText;
  final Duration? duration;

  const TranscriptionCompleteDialog({
    super.key,
    required this.transcriptionText,
    this.duration,
  });

  @override
  ConsumerState<TranscriptionCompleteDialog> createState() =>
      _TranscriptionCompleteDialogState();
}

class _TranscriptionCompleteDialogState
    extends ConsumerState<TranscriptionCompleteDialog> {
  late TextEditingController _textController;
  String? _summary;
  bool _includeSummary = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.transcriptionText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            _buildHeader(colors),
            const SizedBox(height: 16),
            // 转录文本编辑区
            Expanded(
              child: _buildTextEditor(colors),
            ),
            // 摘要显示区（如果有）
            if (_summary != null) ...[
              const SizedBox(height: 16),
              _buildSummarySection(colors),
            ],
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
        Icon(Icons.check_circle, color: colors.success, size: 24),
        const SizedBox(width: 12),
        Text(
          '转录完成',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        if (widget.duration != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '时长 ${_formatDuration(widget.duration!)}',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        const Spacer(),
        IconButton(
          icon: Icon(Icons.close, color: colors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '关闭',
        ),
      ],
    );
  }

  Widget _buildTextEditor(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '转录文本...',
          hintStyle: TextStyle(color: colors.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildSummarySection(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                '摘要',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '一起保存',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 20,
                    child: Switch(
                      value: _includeSummary,
                      onChanged: (v) => setState(() => _includeSummary = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _summary!,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.textPrimary,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppColors colors) {
    return Row(
      children: [
        // AI 优化按钮
        OutlinedButton.icon(
          onPressed: _showAIPolish,
          icon: Icon(Icons.auto_fix_high, size: 18, color: colors.primary),
          label: Text('AI 优化', style: TextStyle(color: colors.primary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        const SizedBox(width: 12),
        // 生成摘要按钮
        OutlinedButton.icon(
          onPressed: _showSummaryGenerator,
          icon: Icon(Icons.summarize, size: 18, color: colors.warning),
          label: Text('生成摘要', style: TextStyle(color: colors.warning)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.warning),
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
        // 保存按钮
        ElevatedButton.icon(
          onPressed: _showSaveDialog,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('存入工作空间'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.dialogBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }

  void _showAIPolish() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AIPolishWidget(
        originalText: _textController.text,
      ),
    );

    if (result != null) {
      setState(() {
        _textController.text = result;
      });
    }
  }

  void _showSummaryGenerator() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SummaryGeneratorWidget(
        sourceText: _textController.text,
      ),
    );

    if (result != null) {
      setState(() {
        _summary = result;
        _includeSummary = true;
      });
    }
  }

  void _showSaveDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => SaveToWorkspaceDialog(
        content: _textController.text,
        summary: _includeSummary ? _summary : null,
        sourceType: 'transcription',
      ),
    );

    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// 显示转录完成弹窗
Future<bool?> showTranscriptionCompleteDialog(
  BuildContext context, {
  required String transcriptionText,
  Duration? duration,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TranscriptionCompleteDialog(
      transcriptionText: transcriptionText,
      duration: duration,
    ),
  );
}

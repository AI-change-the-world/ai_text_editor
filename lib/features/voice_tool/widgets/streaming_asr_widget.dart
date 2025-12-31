import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';
import '../notifiers/streaming_asr_notifier.dart';
import 'recording_control_button.dart';
import 'transcription_complete_dialog.dart';
import 'transcription_text_view.dart';

/// 流式语音识别组件
/// 提供实时录音和语音识别功能
class StreamingASRWidget extends ConsumerStatefulWidget {
  const StreamingASRWidget({super.key});

  @override
  ConsumerState<StreamingASRWidget> createState() => _StreamingASRWidgetState();
}

class _StreamingASRWidgetState extends ConsumerState<StreamingASRWidget> {
  @override
  void initState() {
    super.initState();
    // 初始化 ASR 服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(streamingASRProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(streamingASRProvider);

    // 监听状态变化，当转录完成时显示弹窗
    ref.listen<StreamingASRState>(streamingASRProvider, (previous, next) {
      if (previous?.status == ASRStatus.recording &&
          next.status == ASRStatus.completed &&
          next.recognizedText.isNotEmpty) {
        _showCompleteDialog(next);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 模式选择和状态指示区域
          _buildHeader(state, colors),
          const SizedBox(height: 24),
          // 主要内容区域
          Expanded(
            child: _buildMainContent(context, state, colors),
          ),
          // 底部控制区域
          const SizedBox(height: 24),
          RecordingControlButton(
            status: state.status,
            onStart: () =>
                ref.read(streamingASRProvider.notifier).startRecording(),
            onStop: () =>
                ref.read(streamingASRProvider.notifier).stopRecording(),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(StreamingASRState state) async {
    final saved = await showTranscriptionCompleteDialog(
      context,
      transcriptionText: state.recognizedText,
      duration: state.recordingDuration,
    );

    if (mounted) {
      ref.read(streamingASRProvider.notifier).reset();

      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('转录内容已保存'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    }
  }

  Widget _buildHeader(StreamingASRState state, AppColors colors) {
    return Column(
      children: [
        // 模式选择
        if (state.status == ASRStatus.idle) _buildModeSelector(state, colors),
        const SizedBox(height: 12),
        // 状态指示
        _buildStatusBar(state, colors),
      ],
    );
  }

  Widget _buildModeSelector(StreamingASRState state, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeChip(
          label: '流式识别',
          isSelected: state.mode == ASRMode.streaming,
          isAvailable: state.isOnlineAvailable,
          onTap: state.isOnlineAvailable
              ? () => ref
                  .read(streamingASRProvider.notifier)
                  .setMode(ASRMode.streaming)
              : null,
          colors: colors,
        ),
        const SizedBox(width: 12),
        _buildModeChip(
          label: '离线识别',
          isSelected: state.mode == ASRMode.offlineWithVad,
          isAvailable: state.isOfflineAvailable,
          onTap: state.isOfflineAvailable
              ? () => ref
                  .read(streamingASRProvider.notifier)
                  .setMode(ASRMode.offlineWithVad)
              : null,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool isSelected,
    required bool isAvailable,
    required VoidCallback? onTap,
    required AppColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAvailable)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: colors.warning,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isAvailable
                    ? (isSelected ? colors.primary : colors.textSecondary)
                    : colors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(StreamingASRState state, AppColors colors) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (state.status) {
      case ASRStatus.idle:
        statusText = '准备就绪';
        statusColor = colors.textHint;
        statusIcon = Icons.mic_none;
      case ASRStatus.initializing:
        statusText = '正在初始化...';
        statusColor = colors.warning;
        statusIcon = Icons.hourglass_empty;
      case ASRStatus.recording:
        statusText = '正在录音...';
        statusColor = colors.error;
        statusIcon = Icons.mic;
      case ASRStatus.processing:
        statusText = '处理中...';
        statusColor = colors.warning;
        statusIcon = Icons.hourglass_empty;
      case ASRStatus.completed:
        statusText = '转录完成';
        statusColor = colors.success;
        statusIcon = Icons.check_circle;
      case ASRStatus.error:
        statusText = state.errorMessage ?? '发生错误';
        statusColor = colors.error;
        statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          if (state.status == ASRStatus.recording) ...[
            const SizedBox(width: 16),
            Text(
              _formatDuration(state.recordingDuration),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    StreamingASRState state,
    AppColors colors,
  ) {
    if (state.status == ASRStatus.idle ||
        state.status == ASRStatus.initializing) {
      return _buildIdleState(context, state, colors);
    }
    return _buildRecordingState(context, state, colors);
  }

  Widget _buildIdleState(
    BuildContext context,
    StreamingASRState state,
    AppColors colors,
  ) {
    final isInitializing = state.status == ASRStatus.initializing;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 3),
            ),
            child: isInitializing
                ? const CircularProgressIndicator()
                : Icon(
                    Icons.mic,
                    size: 64,
                    color: colors.textHint,
                  ),
          ),
          const SizedBox(height: 32),
          Text(
            isInitializing ? '正在加载模型...' : '点击下方按钮开始录音',
            style: TextStyle(
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.mode == ASRMode.streaming ? '语音将实时转换为文字' : '使用离线模型进行识别',
            style: TextStyle(
              fontSize: 14,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingState(
    BuildContext context,
    StreamingASRState state,
    AppColors colors,
  ) {
    return Column(
      children: [
        // 波形动画区域
        if (state.status == ASRStatus.recording)
          _buildWaveformAnimation(colors),
        const SizedBox(height: 16),
        // 转录文本显示区域
        Expanded(
          child: TranscriptionTextView(
            confirmedText: state.recognizedText,
            pendingText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformAnimation(AppColors colors) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          return _WaveformBar(
            index: index,
            color: colors.primary,
          );
        }),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// 波形动画条
class _WaveformBar extends StatefulWidget {
  final int index;
  final Color color;

  const _WaveformBar({required this.index, required this.color});

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50) % 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 40 * _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.6 + 0.4 * _animation.value),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

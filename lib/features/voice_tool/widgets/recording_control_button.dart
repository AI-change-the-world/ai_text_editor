import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';
import '../notifiers/streaming_asr_notifier.dart';

/// 录音控制按钮组件
/// 提供开始/停止录音的交互
class RecordingControlButton extends StatefulWidget {
  final ASRStatus status;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RecordingControlButton({
    super.key,
    required this.status,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<RecordingControlButton> createState() => _RecordingControlButtonState();
}

class _RecordingControlButtonState extends State<RecordingControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RecordingControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == ASRStatus.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRecording = widget.status == ASRStatus.recording;
    final isIdle = widget.status == ASRStatus.idle;
    final isCompleted = widget.status == ASRStatus.completed;
    final isInitializing = widget.status == ASRStatus.initializing;
    final canStart = isIdle || isCompleted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主按钮
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isRecording ? _pulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: isRecording
                ? widget.onStop
                : (canStart ? widget.onStart : null),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isRecording
                    ? colors.error
                    : (canStart ? colors.primary : colors.textHint),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? colors.error : colors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isInitializing
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colors.dialogBackground,
                      ),
                    )
                  : Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      size: 36,
                      color: colors.dialogBackground,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 提示文字
        Text(
          isRecording
              ? '点击停止'
              : (isInitializing ? '初始化中...' : (isCompleted ? '重新录音' : '点击开始')),
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

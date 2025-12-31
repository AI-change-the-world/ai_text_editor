import 'package:flutter/material.dart';

import '../../../services/voice_tool/hybrid_asr_service.dart';
import '../../../utils/app_theme.dart';

/// 音频段卡片组件
/// 显示单个时间段的识别结果
class SegmentCard extends StatelessWidget {
  final AudioSegment segment;
  final bool isCurrentSegment;

  const SegmentCard({
    super.key,
    required this.segment,
    this.isCurrentSegment = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSegment ? colors.primary : colors.border,
          width: isCurrentSegment ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textHint.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          _buildContent(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _getHeaderColor(colors),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          // 时间范围
          Icon(
            Icons.schedule,
            size: 14,
            color: _getHeaderTextColor(colors),
          ),
          const SizedBox(width: 6),
          Text(
            segment.timeRange,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _getHeaderTextColor(colors),
            ),
          ),
          const Spacer(),
          // 状态指示
          _buildStatusIndicator(colors),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(AppColors colors) {
    IconData icon;
    Color color;
    String tooltip;

    switch (segment.status) {
      case SegmentStatus.recording:
        icon = Icons.mic;
        color = colors.error;
        tooltip = '正在录音';
      case SegmentStatus.pendingOffline:
        icon = Icons.hourglass_empty;
        color = colors.warning;
        tooltip = '等待识别';
      case SegmentStatus.processingOffline:
        icon = Icons.sync;
        color = colors.primary;
        tooltip = '正在识别';
      case SegmentStatus.completed:
        icon = Icons.check_circle;
        color = colors.success;
        tooltip = '识别完成';
      case SegmentStatus.failed:
        icon = Icons.error;
        color = colors.error;
        tooltip = '识别失败';
    }

    Widget iconWidget = Icon(icon, size: 16, color: color);

    // 处理中时添加旋转动画
    if (segment.status == SegmentStatus.processingOffline) {
      iconWidget = _RotatingIcon(icon: icon, color: color);
    }

    return Tooltip(
      message: tooltip,
      child: iconWidget,
    );
  }

  Widget _buildContent(AppColors colors) {
    final text = segment.displayText;
    final isOfflineResult = segment.offlineText != null;

    if (text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isCurrentSegment ? '正在识别...' : '无识别内容',
          style: TextStyle(
            fontSize: 14,
            color: colors.textHint,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 如果是非流式结果，显示标签
          if (isOfflineResult)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '精确识别',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: colors.success,
                  ),
                ),
              ),
            ),
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color:
                  isOfflineResult ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeaderColor(AppColors colors) {
    if (isCurrentSegment) {
      return colors.primary.withValues(alpha: 0.1);
    }
    switch (segment.status) {
      case SegmentStatus.completed:
        return colors.success.withValues(alpha: 0.05);
      case SegmentStatus.failed:
        return colors.error.withValues(alpha: 0.05);
      default:
        return colors.surfaceVariant;
    }
  }

  Color _getHeaderTextColor(AppColors colors) {
    if (isCurrentSegment) {
      return colors.primary;
    }
    return colors.textSecondary;
  }
}

/// 旋转图标动画
class _RotatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _RotatingIcon({required this.icon, required this.color});

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: 16, color: widget.color),
    );
  }
}

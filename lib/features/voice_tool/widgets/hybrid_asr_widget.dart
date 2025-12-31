import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/voice_tool/hybrid_asr_service.dart';
import '../../../services/voice_tool/voice_tool_services.dart';
import '../../../utils/app_theme.dart';
import 'segment_card.dart';
import 'transcription_complete_dialog.dart';

/// 混合 ASR 状态
class HybridASRState {
  const HybridASRState({
    this.isInitialized = false,
    this.isPreloading = false,
    this.isRecording = false,
    this.segments = const [],
    this.currentSegmentIndex = 0,
    this.totalDuration = Duration.zero,
    this.segmentDurationSeconds = 60,
    this.errorMessage,
  });

  final bool isInitialized;
  final bool isPreloading; // 正在预加载模型
  final bool isRecording;
  final List<AudioSegment> segments;
  final int currentSegmentIndex;
  final Duration totalDuration;
  final int segmentDurationSeconds;
  final String? errorMessage;

  HybridASRState copyWith({
    bool? isInitialized,
    bool? isPreloading,
    bool? isRecording,
    List<AudioSegment>? segments,
    int? currentSegmentIndex,
    Duration? totalDuration,
    int? segmentDurationSeconds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HybridASRState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPreloading: isPreloading ?? this.isPreloading,
      isRecording: isRecording ?? this.isRecording,
      segments: segments ?? this.segments,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      totalDuration: totalDuration ?? this.totalDuration,
      segmentDurationSeconds:
          segmentDurationSeconds ?? this.segmentDurationSeconds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 混合 ASR 状态管理
class HybridASRNotifier extends Notifier<HybridASRState> {
  Timer? _durationTimer;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _asrEventSubscription;

  final _micService = MicrophoneService.instance;
  final _hybridService = HybridASRService.instance;
  final _configManager = ASRConfigManager.instance;

  @override
  HybridASRState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return const HybridASRState();
  }

  /// 初始化（仅加载配置，不加载模型）
  Future<void> initialize() async {
    if (_hybridService.isInitialized) {
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      final config = await _configManager.loadConfig();
      await _hybridService.initialize(config);

      state = state.copyWith(
        isInitialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: '初始化失败: $e');
    }
  }

  /// 设置分段时长
  void setSegmentDuration(int seconds) {
    if (state.isRecording) return;
    _hybridService.segmentDurationSeconds = seconds;
    state = state.copyWith(segmentDurationSeconds: seconds);
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (state.isRecording || state.isPreloading) return;

    if (!state.isInitialized) {
      await initialize();
      if (state.errorMessage != null) return;
    }

    try {
      // 显示预加载状态
      state = state.copyWith(isPreloading: true, clearError: true);

      // 监听 ASR 事件
      _asrEventSubscription = _hybridService.events.listen((event) {
        state = state.copyWith(
          segments: event.segments,
          currentSegmentIndex: event.currentSegmentIndex,
          totalDuration: event.totalDuration,
        );
      });

      // 开始录音（内部会预加载模型）
      await _hybridService.startRecording();
      await _micService.startRecording();

      // 监听音频数据
      _audioSubscription = _micService.audioStream?.listen((audioData) {
        _hybridService.feedAudioData(audioData);
      });

      // 启动计时器
      _startDurationTimer();

      state = state.copyWith(
        isPreloading: false,
        isRecording: true,
        clearError: true,
      );
    } catch (e) {
      _cleanup();
      state = state.copyWith(
        isPreloading: false,
        errorMessage: '启动录音失败: $e',
      );
    }
  }

  /// 停止录音
  Future<String> stopRecording() async {
    if (!state.isRecording) return '';

    try {
      await _micService.stopRecording();
      final text = await _hybridService.stopRecording();

      _durationTimer?.cancel();
      await _audioSubscription?.cancel();

      state = state.copyWith(isRecording: false);

      return text;
    } catch (e) {
      state = state.copyWith(errorMessage: '停止录音失败: $e');
      return '';
    }
  }

  /// 重置
  void reset() {
    _cleanup();
    _hybridService.reset();
    state = HybridASRState(
      isInitialized: _hybridService.isInitialized,
      segmentDurationSeconds: _hybridService.segmentDurationSeconds,
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.isRecording) {
        state = state.copyWith(totalDuration: _hybridService.totalDuration);
      } else {
        timer.cancel();
      }
    });
  }

  void _cleanup() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _audioSubscription?.cancel();
    _audioSubscription = null;
    _asrEventSubscription?.cancel();
    _asrEventSubscription = null;
  }
}

/// Provider
final hybridASRProvider = NotifierProvider<HybridASRNotifier, HybridASRState>(
  HybridASRNotifier.new,
);

/// 混合 ASR 组件
class HybridASRWidget extends ConsumerStatefulWidget {
  const HybridASRWidget({super.key});

  @override
  ConsumerState<HybridASRWidget> createState() => _HybridASRWidgetState();
}

class _HybridASRWidgetState extends ConsumerState<HybridASRWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hybridASRProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(hybridASRProvider);

    // 自动滚动到底部
    ref.listen<HybridASRState>(hybridASRProvider, (previous, next) {
      if (next.segments.length != (previous?.segments.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 顶部状态栏
          _buildHeader(state, colors),
          const SizedBox(height: 16),
          // 分段设置（仅在未录音时显示）
          if (!state.isRecording &&
              !state.isPreloading &&
              state.segments.isEmpty)
            _buildSegmentSettings(state, colors),
          const SizedBox(height: 16),
          // 主内容区域
          Expanded(
            child: _buildMainContent(state, colors),
          ),
          const SizedBox(height: 24),
          // 控制按钮
          _buildControlButtons(state, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(HybridASRState state, AppColors colors) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (state.isPreloading) {
      statusText = '正在加载模型...';
      statusColor = colors.warning;
      statusIcon = Icons.hourglass_empty;
    } else if (state.isRecording) {
      statusText = '正在录音';
      statusColor = colors.error;
      statusIcon = Icons.mic;
    } else {
      statusText = '准备就绪';
      statusColor = colors.textHint;
      statusIcon = Icons.mic_none;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (state.isPreloading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          const Spacer(),
          // 总时长
          Text(
            _formatDuration(state.totalDuration),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          // 段数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.segments.length} 段',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentSettings(HybridASRState state, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, size: 16, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                '分段设置',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '每段时长：',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(width: 8),
              _buildDurationChip(30, state, colors),
              const SizedBox(width: 8),
              _buildDurationChip(60, state, colors),
              const SizedBox(width: 8),
              _buildDurationChip(120, state, colors),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '每段结束后会使用非流式模型重新识别，获得更精确的结果',
            style: TextStyle(fontSize: 11, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(
      int seconds, HybridASRState state, AppColors colors) {
    final isSelected = state.segmentDurationSeconds == seconds;
    final label = seconds >= 60 ? '${seconds ~/ 60}分钟' : '$seconds秒';

    return GestureDetector(
      onTap: () =>
          ref.read(hybridASRProvider.notifier).setSegmentDuration(seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(HybridASRState state, AppColors colors) {
    if (state.segments.isEmpty) {
      return _buildEmptyState(state, colors);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.segments.length,
      itemBuilder: (context, index) {
        final segment = state.segments[index];
        final isCurrentSegment =
            state.isRecording && index == state.currentSegmentIndex;

        return SegmentCard(
          segment: segment,
          isCurrentSegment: isCurrentSegment,
        );
      },
    );
  }

  Widget _buildEmptyState(HybridASRState state, AppColors colors) {
    final isInitializing = !state.isInitialized;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 2),
            ),
            child: isInitializing
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(Icons.mic, size: 48, color: colors.textHint),
          ),
          const SizedBox(height: 24),
          Text(
            isInitializing ? '正在加载模型...' : '点击下方按钮开始录音',
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '流式识别 + 分段精确识别',
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(HybridASRState state, AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置按钮（有内容时显示）
        if (state.segments.isNotEmpty && !state.isRecording)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () => ref.read(hybridASRProvider.notifier).reset(),
              icon: Icon(Icons.refresh, color: colors.textSecondary),
              tooltip: '重新开始',
            ),
          ),
        // 主控制按钮
        _buildMainButton(state, colors),
        // 完成按钮（有内容且未录音时显示）
        if (state.segments.isNotEmpty && !state.isRecording)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteDialog(state),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('完成'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainButton(HybridASRState state, AppColors colors) {
    // 正在预加载模型
    if (state.isPreloading) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        label: const Text('加载中...'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    // 正在录音
    if (state.isRecording) {
      return ElevatedButton.icon(
        onPressed: () async {
          await ref.read(hybridASRProvider.notifier).stopRecording();
        },
        icon: const Icon(Icons.stop, size: 20),
        label: const Text('停止录音'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    // 空闲状态
    return ElevatedButton.icon(
      onPressed: state.isInitialized
          ? () => ref.read(hybridASRProvider.notifier).startRecording()
          : null,
      icon: const Icon(Icons.mic, size: 20),
      label: Text(state.segments.isEmpty ? '开始录音' : '继续录音'),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  void _showCompleteDialog(HybridASRState state) async {
    final fullText = HybridASRService.instance.getFullText();

    final saved = await showTranscriptionCompleteDialog(
      context,
      transcriptionText: fullText,
      duration: state.totalDuration,
    );

    if (mounted && saved == true) {
      ref.read(hybridASRProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('转录内容已保存'),
          backgroundColor: context.colors.success,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

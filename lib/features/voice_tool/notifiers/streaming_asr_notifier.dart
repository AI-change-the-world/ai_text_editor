import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/voice_tool/voice_tool_services.dart';

/// ASR 状态枚举
enum ASRStatus {
  /// 空闲状态，等待开始录音
  idle,

  /// 正在初始化
  initializing,

  /// 正在录音
  recording,

  /// 正在处理
  processing,

  /// 转录完成
  completed,

  /// 发生错误
  error,
}

/// ASR 模式
enum ASRMode {
  /// 流式识别（实时）
  streaming,

  /// 非流式识别（带 VAD）
  offlineWithVad,
}

/// 流式 ASR 状态
class StreamingASRState {
  const StreamingASRState({
    this.status = ASRStatus.idle,
    this.mode = ASRMode.streaming,
    this.recognizedText = '',
    this.recordingDuration = Duration.zero,
    this.errorMessage,
    this.isOnlineAvailable = false,
    this.isOfflineAvailable = false,
  });

  /// 当前状态
  final ASRStatus status;

  /// ASR 模式
  final ASRMode mode;

  /// 识别的文本
  final String recognizedText;

  /// 录音时长
  final Duration recordingDuration;

  /// 错误信息
  final String? errorMessage;

  /// 流式模型是否可用
  final bool isOnlineAvailable;

  /// 非流式模型是否可用
  final bool isOfflineAvailable;

  StreamingASRState copyWith({
    ASRStatus? status,
    ASRMode? mode,
    String? recognizedText,
    Duration? recordingDuration,
    String? errorMessage,
    bool? isOnlineAvailable,
    bool? isOfflineAvailable,
    bool clearError = false,
  }) {
    return StreamingASRState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      recognizedText: recognizedText ?? this.recognizedText,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isOnlineAvailable: isOnlineAvailable ?? this.isOnlineAvailable,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
    );
  }
}

/// 流式 ASR 状态管理
class StreamingASRNotifier extends Notifier<StreamingASRState> {
  Timer? _durationTimer;
  StreamSubscription? _audioSubscription;
  StreamSubscription? _asrResultSubscription;

  // 服务实例
  final _micService = MicrophoneService.instance;
  final _asrService = LocalASRService.instance;
  final _configManager = ASRConfigManager.instance;

  @override
  StreamingASRState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return const StreamingASRState();
  }

  /// 初始化 ASR 服务
  Future<void> initialize() async {
    if (_asrService.isInitialized) {
      _updateAvailability();
      return;
    }

    state = state.copyWith(status: ASRStatus.initializing);

    try {
      // 加载配置
      final config = await _configManager.loadConfig();

      // 验证配置
      final validation = _configManager.validateConfig();
      if (!validation.isValid) {
        state = state.copyWith(
          status: ASRStatus.error,
          errorMessage: validation.errors.join('\n'),
        );
        return;
      }

      // 初始化 ASR 服务
      await _asrService.initialize(config);

      _updateAvailability();
      state = state.copyWith(status: ASRStatus.idle, clearError: true);
      debugPrint('ASR service initialized');
    } catch (e) {
      state = state.copyWith(
        status: ASRStatus.error,
        errorMessage: '初始化失败: $e',
      );
    }
  }

  void _updateAvailability() {
    state = state.copyWith(
      isOnlineAvailable: _asrService.isOnlineAvailable,
      isOfflineAvailable: _asrService.isOfflineAvailable,
    );
  }

  /// 切换 ASR 模式
  void setMode(ASRMode mode) {
    if (state.status == ASRStatus.recording) return;
    state = state.copyWith(mode: mode);
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (state.status == ASRStatus.recording) return;

    // 确保已初始化
    if (!_asrService.isInitialized) {
      await initialize();
      if (state.status == ASRStatus.error) return;
    }

    try {
      state = state.copyWith(
        status: ASRStatus.recording,
        recognizedText: '',
        recordingDuration: Duration.zero,
        clearError: true,
      );

      // 监听 ASR 结果
      _asrResultSubscription = _asrService.streamingResults.listen((event) {
        state = state.copyWith(recognizedText: event.text);
      });

      // 根据模式启动 ASR
      if (state.mode == ASRMode.streaming) {
        await _asrService.startStreaming();
      } else {
        await _asrService.startOfflineWithVad();
      }

      // 启动麦克风录音
      await _micService.startRecording();

      // 监听音频数据并发送给 ASR
      _audioSubscription = _micService.audioStream?.listen((audioData) {
        if (state.mode == ASRMode.streaming) {
          _asrService.feedAudioData(audioData);
        } else {
          _asrService.feedAudioDataOffline(audioData);
        }
      });

      // 启动计时器
      _startDurationTimer();

      debugPrint('Recording started in ${state.mode} mode');
    } catch (e) {
      _cleanup();
      state = state.copyWith(
        status: ASRStatus.error,
        errorMessage: '启动录音失败: $e',
      );
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (state.status != ASRStatus.recording) return;

    try {
      state = state.copyWith(status: ASRStatus.processing);

      // 停止麦克风
      await _micService.stopRecording();

      // 停止 ASR 并获取最终结果
      TranscriptionResult result;
      if (state.mode == ASRMode.streaming) {
        result = await _asrService.stopStreaming();
      } else {
        result = await _asrService.stopOfflineWithVad();
      }

      _durationTimer?.cancel();
      await _audioSubscription?.cancel();
      await _asrResultSubscription?.cancel();

      state = state.copyWith(
        status: ASRStatus.completed,
        recognizedText: result.text,
        recordingDuration: result.duration,
      );

      debugPrint('Recording stopped, text: ${result.text}');
    } catch (e) {
      state = state.copyWith(
        status: ASRStatus.error,
        errorMessage: '停止录音失败: $e',
      );
    }
  }

  /// 重置状态
  void reset() {
    _cleanup();
    state = StreamingASRState(
      isOnlineAvailable: _asrService.isOnlineAvailable,
      isOfflineAvailable: _asrService.isOfflineAvailable,
    );
  }

  /// 更新识别文本（用于手动编辑）
  void updateText(String text) {
    state = state.copyWith(recognizedText: text);
  }

  /// 设置错误状态
  void setError(String message) {
    _cleanup();
    state = state.copyWith(
      status: ASRStatus.error,
      errorMessage: message,
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    final startTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.status == ASRStatus.recording) {
        state = state.copyWith(
          recordingDuration: DateTime.now().difference(startTime),
        );
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
    _asrResultSubscription?.cancel();
    _asrResultSubscription = null;
  }
}

/// Provider
final streamingASRProvider =
    NotifierProvider<StreamingASRNotifier, StreamingASRState>(
  StreamingASRNotifier.new,
);

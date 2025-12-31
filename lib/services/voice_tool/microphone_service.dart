import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// 麦克风录音状态
enum MicrophoneState {
  /// 空闲
  idle,

  /// 正在录音
  recording,

  /// 已暂停
  paused,

  /// 错误
  error,
}

/// 音频格式配置
class AudioConfig {
  const AudioConfig({
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.bitDepth = 16,
  });

  /// 采样率 (Hz)
  final int sampleRate;

  /// 声道数
  final int numChannels;

  /// 位深度
  final int bitDepth;

  /// 默认配置（适用于语音识别）
  static const AudioConfig defaultForASR = AudioConfig(
    sampleRate: 16000,
    numChannels: 1,
    bitDepth: 16,
  );
}

/// 麦克风录音服务
/// 负责音频采集和流式数据输出
class MicrophoneService extends ChangeNotifier {
  MicrophoneService._();

  static MicrophoneService? _instance;
  static MicrophoneService get instance => _instance ??= MicrophoneService._();

  /// 录音器实例
  final AudioRecorder _recorder = AudioRecorder();

  /// 当前状态
  MicrophoneState _state = MicrophoneState.idle;

  /// 音频配置
  AudioConfig _config = AudioConfig.defaultForASR;

  /// 音频流控制器
  StreamController<Uint8List>? _audioStreamController;

  /// 音频流订阅
  StreamSubscription<RecordState>? _recordStateSubscription;
  StreamSubscription<Uint8List>? _audioDataSubscription;

  /// 录音开始时间
  DateTime? _recordingStartTime;

  /// 错误信息
  String? _errorMessage;

  /// 获取当前状态
  MicrophoneState get state => _state;

  /// 获取音频配置
  AudioConfig get config => _config;

  /// 获取录音时长
  Duration get recordingDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 是否正在录音
  bool get isRecording => _state == MicrophoneState.recording;

  /// 获取音频数据流
  Stream<Uint8List>? get audioStream => _audioStreamController?.stream;

  /// 检查麦克风权限
  Future<bool> checkPermission() async {
    return await _recorder.hasPermission();
  }

  /// 请求麦克风权限
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// 获取可用的输入设备列表
  Future<List<InputDevice>> getInputDevices() async {
    return await _recorder.listInputDevices();
  }

  /// 开始录音
  /// [config] 音频配置
  /// [inputDevice] 可选的输入设备
  Future<void> startRecording({
    AudioConfig? config,
    InputDevice? inputDevice,
  }) async {
    if (_state == MicrophoneState.recording) {
      return;
    }

    // 检查权限
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      _state = MicrophoneState.error;
      _errorMessage = '没有麦克风权限';
      notifyListeners();
      throw Exception('Microphone permission denied');
    }

    _config = config ?? AudioConfig.defaultForASR;
    _errorMessage = null;

    // 创建音频流控制器
    _audioStreamController = StreamController<Uint8List>.broadcast();

    try {
      // 配置录音参数
      final recordConfig = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _config.sampleRate,
        numChannels: _config.numChannels,
        bitRate: _config.sampleRate * _config.bitDepth * _config.numChannels,
        device: inputDevice,
      );

      // 开始流式录音
      final stream = await _recorder.startStream(recordConfig);

      // 监听音频数据
      _audioDataSubscription = stream.listen(
        (data) {
          _audioStreamController?.add(data);
        },
        onError: (error) {
          _handleError('录音错误: $error');
        },
        onDone: () {
          // 录音结束
        },
      );

      // 监听录音状态
      _recordStateSubscription = _recorder.onStateChanged().listen((state) {
        switch (state) {
          case RecordState.record:
            _state = MicrophoneState.recording;
            break;
          case RecordState.pause:
            _state = MicrophoneState.paused;
            break;
          case RecordState.stop:
            _state = MicrophoneState.idle;
            break;
        }
        notifyListeners();
      });

      _state = MicrophoneState.recording;
      _recordingStartTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      _handleError('启动录音失败: $e');
      rethrow;
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    if (_state != MicrophoneState.recording) {
      return;
    }

    try {
      await _recorder.pause();
      _state = MicrophoneState.paused;
      notifyListeners();
    } catch (e) {
      _handleError('暂停录音失败: $e');
      rethrow;
    }
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    if (_state != MicrophoneState.paused) {
      return;
    }

    try {
      await _recorder.resume();
      _state = MicrophoneState.recording;
      notifyListeners();
    } catch (e) {
      _handleError('恢复录音失败: $e');
      rethrow;
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (_state == MicrophoneState.idle) {
      return;
    }

    try {
      await _recorder.stop();

      // 取消订阅
      await _audioDataSubscription?.cancel();
      _audioDataSubscription = null;

      await _recordStateSubscription?.cancel();
      _recordStateSubscription = null;

      // 关闭流控制器
      await _audioStreamController?.close();
      _audioStreamController = null;

      _state = MicrophoneState.idle;
      _recordingStartTime = null;
      notifyListeners();
    } catch (e) {
      _handleError('停止录音失败: $e');
      rethrow;
    }
  }

  /// 处理错误
  void _handleError(String message) {
    _state = MicrophoneState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// 获取音频振幅（用于显示波形）
  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  /// 释放资源
  @override
  void dispose() {
    stopRecording();
    _recorder.dispose();
    super.dispose();
  }
}

/// 音频振幅扩展
extension AmplitudeExtension on Amplitude {
  /// 获取归一化的振幅值 (0.0 - 1.0)
  double get normalizedCurrent {
    // dB 范围通常是 -160 到 0
    // 将其映射到 0.0 - 1.0
    const minDb = -60.0;
    const maxDb = 0.0;
    final clampedDb = current.clamp(minDb, maxDb);
    return (clampedDb - minDb) / (maxDb - minDb);
  }

  /// 获取归一化的最大振幅值 (0.0 - 1.0)
  double get normalizedMax {
    const minDb = -60.0;
    const maxDb = 0.0;
    final clampedDb = max.clamp(minDb, maxDb);
    return (clampedDb - minDb) / (maxDb - minDb);
  }
}

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'local_asr_service.dart';

/// 音频段状态
enum SegmentStatus {
  recording,
  pendingOffline,
  processingOffline,
  completed,
  failed,
}

/// 初始化状态
enum InitializationStatus {
  notStarted,
  initializing,
  ready,
  failed,
}

/// 音频段数据
class AudioSegment {
  AudioSegment({
    required this.index,
    required this.startTime,
    this.endTime,
    this.streamingText = '',
    this.offlineText,
    this.status = SegmentStatus.recording,
  });

  final int index;
  final Duration startTime;
  Duration? endTime;
  String streamingText;
  String? offlineText;
  SegmentStatus status;

  String get displayText => offlineText ?? streamingText;
  bool get isCompleted => status == SegmentStatus.completed;

  String get timeRange {
    final start = _formatDuration(startTime);
    if (endTime == null) return '$start - 进行中';
    return '$start - ${_formatDuration(endTime!)}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  AudioSegment copyWith({
    Duration? endTime,
    String? streamingText,
    String? offlineText,
    SegmentStatus? status,
  }) {
    return AudioSegment(
      index: index,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      streamingText: streamingText ?? this.streamingText,
      offlineText: offlineText ?? this.offlineText,
      status: status ?? this.status,
    );
  }
}

/// 混合识别事件
class HybridASREvent {
  const HybridASREvent({
    required this.segments,
    required this.currentSegmentIndex,
    required this.totalDuration,
  });

  final List<AudioSegment> segments;
  final int currentSegmentIndex;
  final Duration totalDuration;
}

/// 后台 Isolate 命令类型
enum _IsolateCommand {
  init, // 初始化模型
  recognize, // 识别音频
  dispose, // 释放资源
}

/// 发送给后台 Isolate 的消息
class _IsolateMessage {
  _IsolateMessage({
    required this.command,
    this.segmentIndex,
    this.audioData,
    this.modelDir,
    this.modelType,
    this.encoder,
    this.decoder,
    this.joiner,
    this.tokens,
  });

  final _IsolateCommand command;
  final int? segmentIndex;
  final Uint8List? audioData;
  final String? modelDir;
  final String? modelType;
  final String? encoder;
  final String? decoder;
  final String? joiner;
  final String? tokens;
}

/// 后台 Isolate 返回的消息
class _IsolateResponse {
  _IsolateResponse({
    required this.command,
    this.segmentIndex,
    this.text,
    this.success = true,
    this.error,
  });

  final _IsolateCommand command;
  final int? segmentIndex;
  final String? text;
  final bool success;
  final String? error;
}

/// 流式识别器初始化参数
class _OnlineRecognizerInitParams {
  _OnlineRecognizerInitParams({
    required this.modelDir,
    required this.modelType,
    required this.encoder,
    required this.decoder,
    required this.joiner,
    required this.tokens,
    required this.sendPort,
  });

  final String modelDir;
  final String modelType;
  final String encoder;
  final String decoder;
  final String joiner;
  final String tokens;
  final SendPort sendPort;
}

/// 流式识别器初始化结果
class _OnlineRecognizerInitResult {
  _OnlineRecognizerInitResult({
    required this.success,
    this.error,
  });

  final bool success;
  final String? error;
}

/// 混合 ASR 服务
/// 结合流式识别（实时）和非流式识别（精确）
/// 所有耗时操作在 Isolate 中执行，避免阻塞 UI
class HybridASRService extends ChangeNotifier {
  HybridASRService._();

  static HybridASRService? _instance;
  static HybridASRService get instance => _instance ??= HybridASRService._();

  static const int sampleRate = 16000;

  // 配置
  ASRConfig? _config;
  int _segmentDurationSeconds = 60;

  // 流式识别器（主线程）- 流式识别必须在主线程，因为需要实时处理
  sherpa_onnx.OnlineRecognizer? _onlineRecognizer;
  sherpa_onnx.OnlineStream? _onlineStream;

  // 状态
  bool _isInitialized = false;
  InitializationStatus _initStatus = InitializationStatus.notStarted;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  int _currentSegmentIndex = 0;
  String? _initError;

  // 音频段数据
  final List<AudioSegment> _segments = [];
  final List<List<int>> _segmentAudioBuffers = [];

  // 当前段的流式识别文本
  String _currentStreamingText = '';

  // 事件流
  final StreamController<HybridASREvent> _eventController =
      StreamController<HybridASREvent>.broadcast();

  // Isolate 结果接收
  ReceivePort? _resultReceivePort;
  StreamSubscription? _resultSubscription;

  // 后台 Isolate（持久化，只初始化一次）
  Isolate? _offlineIsolate;
  SendPort? _offlineSendPort;
  bool _offlineModelReady = false;

  // Getters
  Stream<HybridASREvent> get events => _eventController.stream;
  bool get isInitialized => _isInitialized;
  InitializationStatus get initStatus => _initStatus;
  String? get initError => _initError;
  bool get isRecording => _isRecording;
  List<AudioSegment> get segments => List.unmodifiable(_segments);
  int get segmentDurationSeconds => _segmentDurationSeconds;

  set segmentDurationSeconds(int value) {
    _segmentDurationSeconds = value.clamp(30, 300);
  }

  /// 初始化服务（仅保存配置，不加载模型）
  Future<void> initialize(ASRConfig config) async {
    if (_isInitialized) return;

    _config = config;
    sherpa_onnx.initBindings();

    // 设置 Isolate 结果接收
    _resultReceivePort = ReceivePort();
    _resultSubscription = _resultReceivePort!.listen(_handleIsolateResult);

    _isInitialized = true;
    _initStatus = InitializationStatus.notStarted;
    notifyListeners();
  }

  /// 预加载流式识别器（在 Isolate 中验证模型，然后在主线程创建）
  Future<bool> preloadOnlineRecognizer() async {
    if (_onlineRecognizer != null) return true;
    if (_config == null || !_config!.hasOnlineModel) {
      _initError = 'Online model not configured';
      _initStatus = InitializationStatus.failed;
      notifyListeners();
      return false;
    }

    _initStatus = InitializationStatus.initializing;
    _initError = null;
    notifyListeners();

    try {
      // 在 Isolate 中验证模型文件是否存在且可加载
      final completer = Completer<_OnlineRecognizerInitResult>();
      final receivePort = ReceivePort();

      receivePort.listen((message) {
        if (message is _OnlineRecognizerInitResult) {
          completer.complete(message);
          receivePort.close();
        }
      });

      final params = _OnlineRecognizerInitParams(
        modelDir: _config!.onlineModelDir,
        modelType: _config!.onlineModelType,
        encoder: _config!.onlineEncoder,
        decoder: _config!.onlineDecoder,
        joiner: _config!.onlineJoiner,
        tokens: _config!.onlineTokens,
        sendPort: receivePort.sendPort,
      );

      await Isolate.spawn(_validateOnlineModelIsolate, params);

      final result = await completer.future;

      if (!result.success) {
        _initError = result.error ?? 'Unknown error';
        _initStatus = InitializationStatus.failed;
        notifyListeners();
        return false;
      }

      // 模型验证通过，在主线程创建识别器
      await _createOnlineRecognizerInMainThread();

      _initStatus = InitializationStatus.ready;
      notifyListeners();
      return true;
    } catch (e) {
      _initError = e.toString();
      _initStatus = InitializationStatus.failed;
      notifyListeners();
      return false;
    }
  }

  /// Isolate: 验证流式模型
  static void _validateOnlineModelIsolate(_OnlineRecognizerInitParams params) {
    try {
      sherpa_onnx.initBindings();

      final dir = params.modelDir;
      final modelConfig = sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$dir/${params.encoder}',
          decoder: '$dir/${params.decoder}',
          joiner: '$dir/${params.joiner}',
        ),
        tokens: '$dir/${params.tokens}',
        modelType: params.modelType,
      );

      final config = sherpa_onnx.OnlineRecognizerConfig(
        model: modelConfig,
        ruleFsts: '',
      );

      // 尝试创建识别器验证模型
      final recognizer = sherpa_onnx.OnlineRecognizer(config);
      recognizer.free();

      params.sendPort.send(_OnlineRecognizerInitResult(success: true));
    } catch (e) {
      params.sendPort.send(_OnlineRecognizerInitResult(
        success: false,
        error: e.toString(),
      ));
    }
  }

  /// 在主线程创建流式识别器
  Future<void> _createOnlineRecognizerInMainThread() async {
    final dir = _config!.onlineModelDir;
    final modelConfig = sherpa_onnx.OnlineModelConfig(
      transducer: sherpa_onnx.OnlineTransducerModelConfig(
        encoder: '$dir/${_config!.onlineEncoder}',
        decoder: '$dir/${_config!.onlineDecoder}',
        joiner: '$dir/${_config!.onlineJoiner}',
      ),
      tokens: '$dir/${_config!.onlineTokens}',
      modelType: _config!.onlineModelType,
    );

    final config = sherpa_onnx.OnlineRecognizerConfig(
      model: modelConfig,
      ruleFsts: '',
    );

    _onlineRecognizer = sherpa_onnx.OnlineRecognizer(config);
    debugPrint('Online recognizer created in main thread');
  }

  /// 处理 Isolate 返回的结果
  void _handleIsolateResult(dynamic message) {
    if (message is SendPort) {
      // 收到后台 Isolate 的 SendPort
      _offlineSendPort = message;
      return;
    }

    if (message is _IsolateResponse) {
      switch (message.command) {
        case _IsolateCommand.init:
          _offlineModelReady = message.success;
          if (!message.success) {
            debugPrint('Offline model init failed: ${message.error}');
          } else {
            debugPrint('Offline model initialized in background isolate');
          }
          break;

        case _IsolateCommand.recognize:
          final segmentIndex = message.segmentIndex;
          if (segmentIndex != null && segmentIndex < _segments.length) {
            if (message.success) {
              _segments[segmentIndex] = _segments[segmentIndex].copyWith(
                offlineText: (message.text?.isNotEmpty ?? false)
                    ? message.text
                    : _segments[segmentIndex].streamingText,
                status: SegmentStatus.completed,
              );
              debugPrint('Segment $segmentIndex completed: ${message.text}');
            } else {
              _segments[segmentIndex] = _segments[segmentIndex].copyWith(
                status: SegmentStatus.failed,
              );
              debugPrint('Segment $segmentIndex failed: ${message.error}');
            }
            _emitEvent();
          }
          break;

        case _IsolateCommand.dispose:
          debugPrint('Offline isolate disposed');
          break;
      }
      return;
    }
  }

  /// 启动后台 Isolate 并初始化离线模型
  Future<bool> _startOfflineIsolate() async {
    if (_offlineIsolate != null) return _offlineModelReady;
    if (_config == null || !_config!.hasOfflineModel) return false;

    try {
      _offlineIsolate = await Isolate.spawn(
        _offlineIsolateEntry,
        _resultReceivePort!.sendPort,
      );

      // 等待收到 SendPort
      await Future.delayed(const Duration(milliseconds: 100));
      while (_offlineSendPort == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 发送初始化命令
      _offlineSendPort!.send(_IsolateMessage(
        command: _IsolateCommand.init,
        modelDir: _config!.offlineModelDir,
        modelType: _config!.offlineModelType,
        encoder: _config!.offlineEncoder,
        decoder: _config!.offlineDecoder,
        joiner: _config!.offlineJoiner,
        tokens: _config!.offlineTokens,
      ));

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      while (!_offlineModelReady) {
        await Future.delayed(const Duration(milliseconds: 100));
        // 超时检查可以加在这里
      }

      return _offlineModelReady;
    } catch (e) {
      debugPrint('Failed to start offline isolate: $e');
      return false;
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }
    if (_isRecording) return;

    // 确保流式识别器已加载
    if (_onlineRecognizer == null) {
      final success = await preloadOnlineRecognizer();
      if (!success) {
        throw StateError(_initError ?? 'Failed to load online recognizer');
      }
    }

    // 启动后台 Isolate 并初始化离线模型（如果配置了）
    if (_config!.hasOfflineModel && _offlineIsolate == null) {
      await _startOfflineIsolate();
    }

    // 重置状态
    _segments.clear();
    _segmentAudioBuffers.clear();
    _currentSegmentIndex = 0;
    _currentStreamingText = '';
    _recordingStartTime = DateTime.now();
    _isRecording = true;

    _startNewSegment();
    _onlineStream = _onlineRecognizer!.createStream();

    notifyListeners();
    _emitEvent();
    debugPrint('Hybrid recording started');
  }

  void _startNewSegment() {
    final startTime =
        Duration(seconds: _currentSegmentIndex * _segmentDurationSeconds);
    final segment = AudioSegment(
      index: _currentSegmentIndex,
      startTime: startTime,
    );
    _segments.add(segment);
    _segmentAudioBuffers.add([]);
    _currentStreamingText = '';
  }

  /// 输入音频数据
  void feedAudioData(Uint8List audioData) {
    if (!_isRecording || _onlineStream == null || _onlineRecognizer == null) {
      return;
    }

    // 保存原始音频数据
    _segmentAudioBuffers[_currentSegmentIndex].addAll(audioData);

    // 流式识别
    final samples = _convertBytesToFloat32(audioData);
    _onlineStream!.acceptWaveform(samples: samples, sampleRate: sampleRate);

    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    final isEndpoint = _onlineRecognizer!.isEndpoint(_onlineStream!);
    final text = _onlineRecognizer!.getResult(_onlineStream!).text;

    if (text.isNotEmpty) {
      if (_currentStreamingText.isEmpty) {
        _currentStreamingText = text;
      } else if (isEndpoint) {
        _currentStreamingText = '$_currentStreamingText\n$text';
      } else {
        final lines = _currentStreamingText.split('\n');
        if (lines.isNotEmpty) {
          lines[lines.length - 1] = text;
          _currentStreamingText = lines.join('\n');
        } else {
          _currentStreamingText = text;
        }
      }
    }

    if (isEndpoint) {
      _onlineRecognizer!.reset(_onlineStream!);
    }

    _segments[_currentSegmentIndex] = _segments[_currentSegmentIndex].copyWith(
      streamingText: _currentStreamingText,
    );

    _checkSegmentSwitch();
    _emitEvent();
  }

  void _checkSegmentSwitch() {
    final currentDuration = DateTime.now().difference(_recordingStartTime!);
    final expectedSegmentIndex =
        currentDuration.inSeconds ~/ _segmentDurationSeconds;

    if (expectedSegmentIndex > _currentSegmentIndex) {
      _finalizeCurrentSegment();
      _currentSegmentIndex = expectedSegmentIndex;
      _startNewSegment();

      _onlineStream?.free();
      _onlineStream = _onlineRecognizer!.createStream();
    }
  }

  void _finalizeCurrentSegment() {
    final segmentIndex = _currentSegmentIndex;
    final endTime =
        Duration(seconds: (segmentIndex + 1) * _segmentDurationSeconds);

    _segments[segmentIndex] = _segments[segmentIndex].copyWith(
      endTime: endTime,
      status: SegmentStatus.pendingOffline,
    );

    // 在 Isolate 中处理非流式识别
    _processSegmentInIsolate(segmentIndex);
  }

  /// 在 Isolate 中处理非流式识别
  void _processSegmentInIsolate(int segmentIndex) {
    if (_config == null || !_config!.hasOfflineModel) {
      debugPrint(
          'Offline model not configured, skipping segment $segmentIndex');
      _segments[segmentIndex] = _segments[segmentIndex].copyWith(
        status: SegmentStatus.completed,
      );
      _emitEvent();
      return;
    }

    if (_offlineSendPort == null || !_offlineModelReady) {
      debugPrint('Offline isolate not ready, skipping segment $segmentIndex');
      _segments[segmentIndex] = _segments[segmentIndex].copyWith(
        status: SegmentStatus.completed,
      );
      _emitEvent();
      return;
    }

    _segments[segmentIndex] = _segments[segmentIndex].copyWith(
      status: SegmentStatus.processingOffline,
    );
    _emitEvent();

    final audioData = Uint8List.fromList(_segmentAudioBuffers[segmentIndex]);

    // 发送识别命令到后台 Isolate
    _offlineSendPort!.send(_IsolateMessage(
      command: _IsolateCommand.recognize,
      segmentIndex: segmentIndex,
      audioData: audioData,
    ));
  }

  /// 静态方法：字节转 Float32（供 Isolate 使用）
  static Float32List _convertBytesToFloat32Static(Uint8List bytes,
      [Endian endian = Endian.little]) {
    final values = Float32List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer);

    for (var i = 0; i < bytes.length; i += 2) {
      int short = data.getInt16(i, endian);
      values[i ~/ 2] = short / 32768.0;
    }

    return values;
  }

  /// 后台 Isolate 入口函数（持久化运行）
  static void _offlineIsolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    sherpa_onnx.OfflineRecognizer? recognizer;

    receivePort.listen((message) {
      if (message is _IsolateMessage) {
        switch (message.command) {
          case _IsolateCommand.init:
            // 初始化模型
            try {
              sherpa_onnx.initBindings();

              final dir = message.modelDir!;
              sherpa_onnx.OfflineModelConfig modelConfig;

              switch (message.modelType) {
                case 'whisper':
                  modelConfig = sherpa_onnx.OfflineModelConfig(
                    whisper: sherpa_onnx.OfflineWhisperModelConfig(
                      encoder: '$dir/${message.encoder}',
                      decoder: '$dir/${message.decoder}',
                    ),
                    tokens: '$dir/${message.tokens}',
                    modelType: 'whisper',
                  );
                  break;
                case 'sense_voice':
                  modelConfig = sherpa_onnx.OfflineModelConfig(
                    senseVoice: sherpa_onnx.OfflineSenseVoiceModelConfig(
                      model: '$dir/${message.encoder}',
                    ),
                    tokens: '$dir/${message.tokens}',
                  );
                  break;
                case 'zipformer2_ctc':
                  modelConfig = sherpa_onnx.OfflineModelConfig(
                    zipformerCtc: sherpa_onnx.OfflineZipformerCtcModelConfig(
                      model: '$dir/${message.encoder}',
                    ),
                    tokens: '$dir/${message.tokens}',
                  );
                  break;
                default:
                  modelConfig = sherpa_onnx.OfflineModelConfig(
                    transducer: sherpa_onnx.OfflineTransducerModelConfig(
                      encoder: '$dir/${message.encoder}',
                      decoder: '$dir/${message.decoder}',
                      joiner: '$dir/${message.joiner}',
                    ),
                    tokens: '$dir/${message.tokens}',
                    modelType: message.modelType ?? '',
                  );
              }

              final config =
                  sherpa_onnx.OfflineRecognizerConfig(model: modelConfig);
              recognizer = sherpa_onnx.OfflineRecognizer(config);

              mainSendPort.send(_IsolateResponse(
                command: _IsolateCommand.init,
                success: true,
              ));
            } catch (e) {
              mainSendPort.send(_IsolateResponse(
                command: _IsolateCommand.init,
                success: false,
                error: e.toString(),
              ));
            }
            break;

          case _IsolateCommand.recognize:
            // 识别音频
            if (recognizer == null) {
              mainSendPort.send(_IsolateResponse(
                command: _IsolateCommand.recognize,
                segmentIndex: message.segmentIndex,
                success: false,
                error: 'Recognizer not initialized',
              ));
              return;
            }

            try {
              final samples = _convertBytesToFloat32Static(message.audioData!);
              final stream = recognizer!.createStream();
              stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
              recognizer!.decode(stream);
              final result = recognizer!.getResult(stream).text;
              stream.free();

              mainSendPort.send(_IsolateResponse(
                command: _IsolateCommand.recognize,
                segmentIndex: message.segmentIndex,
                text: result,
                success: true,
              ));
            } catch (e) {
              mainSendPort.send(_IsolateResponse(
                command: _IsolateCommand.recognize,
                segmentIndex: message.segmentIndex,
                success: false,
                error: e.toString(),
              ));
            }
            break;

          case _IsolateCommand.dispose:
            // 释放资源
            recognizer?.free();
            recognizer = null;
            mainSendPort.send(_IsolateResponse(
              command: _IsolateCommand.dispose,
              success: true,
            ));
            receivePort.close();
            break;
        }
      }
    });
  }

  /// 实例方法：字节转 Float32
  Float32List _convertBytesToFloat32(Uint8List bytes,
      [Endian endian = Endian.little]) {
    return _convertBytesToFloat32Static(bytes, endian);
  }

  /// 停止录音
  Future<String> stopRecording() async {
    if (!_isRecording) return '';

    _isRecording = false;

    final lastSegmentIndex = _currentSegmentIndex;
    final totalDuration = DateTime.now().difference(_recordingStartTime!);

    _segments[lastSegmentIndex] = _segments[lastSegmentIndex].copyWith(
      endTime: totalDuration,
      status: SegmentStatus.pendingOffline,
    );

    _onlineStream?.free();
    _onlineStream = null;

    _emitEvent();

    // 处理最后一段
    _processSegmentInIsolate(lastSegmentIndex);

    // 等待所有段完成
    await _waitForAllSegmentsComplete(const Duration(seconds: 60));

    notifyListeners();
    debugPrint('Hybrid recording stopped, total duration: $totalDuration');

    return getFullText();
  }

  Future<void> _waitForAllSegmentsComplete(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final allCompleted = _segments.every(
        (s) =>
            s.status == SegmentStatus.completed ||
            s.status == SegmentStatus.failed,
      );
      if (allCompleted) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  String getFullText() {
    return _segments
        .map((s) => s.displayText)
        .where((t) => t.isNotEmpty)
        .join('\n');
  }

  Duration get totalDuration {
    if (_recordingStartTime == null) return Duration.zero;
    if (_isRecording) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return _segments.lastOrNull?.endTime ?? Duration.zero;
  }

  void _emitEvent() {
    _eventController.add(HybridASREvent(
      segments: List.from(_segments),
      currentSegmentIndex: _currentSegmentIndex,
      totalDuration: totalDuration,
    ));
  }

  bool get isHybridAvailable =>
      (_config?.hasOnlineModel ?? false) && (_config?.hasOfflineModel ?? false);

  bool get isOnlineAvailable => _config?.hasOnlineModel ?? false;

  bool get isOfflineAvailable => _config?.hasOfflineModel ?? false;

  void reset() {
    _segments.clear();
    _segmentAudioBuffers.clear();
    _currentSegmentIndex = 0;
    _currentStreamingText = '';
    _recordingStartTime = null;
    _emitEvent();
  }

  @override
  void dispose() {
    _isRecording = false;
    _onlineStream?.free();
    _onlineRecognizer?.free();

    // 释放后台 Isolate
    if (_offlineSendPort != null) {
      _offlineSendPort!.send(_IsolateMessage(command: _IsolateCommand.dispose));
    }
    _offlineIsolate?.kill();
    _offlineIsolate = null;
    _offlineSendPort = null;
    _offlineModelReady = false;

    _resultSubscription?.cancel();
    _resultReceivePort?.close();
    _eventController.close();
    super.dispose();
  }
}

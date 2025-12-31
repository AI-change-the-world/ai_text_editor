import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// 流式转录事件
class StreamingTranscriptionEvent {
  const StreamingTranscriptionEvent({
    required this.text,
    required this.isFinal,
    required this.index,
  });

  /// 当前识别的文本
  final String text;

  /// 是否为最终结果（端点检测）
  final bool isFinal;

  /// 句子索引
  final int index;
}

/// 转录结果
class TranscriptionResult {
  const TranscriptionResult({
    required this.text,
    required this.duration,
  });

  /// 完整转录文本
  final String text;

  /// 录音时长
  final Duration duration;
}

/// ASR 配置（从 config.json 读取）
class ASRConfig {
  ASRConfig({
    required this.onlineModelDir,
    required this.onlineModelType,
    required this.onlineEncoder,
    required this.onlineDecoder,
    required this.onlineJoiner,
    required this.onlineTokens,
    required this.offlineModelDir,
    required this.offlineModelType,
    required this.offlineEncoder,
    required this.offlineDecoder,
    required this.offlineJoiner,
    required this.offlineTokens,
    required this.vadModel,
    this.vadMinSilenceDuration = 0.25,
    this.vadMinSpeechDuration = 0.5,
    this.vadMaxSpeechDuration = 5.0,
  });

  // 流式模型配置
  final String onlineModelDir;
  final String onlineModelType;
  final String onlineEncoder;
  final String onlineDecoder;
  final String onlineJoiner;
  final String onlineTokens;

  // 非流式模型配置
  final String offlineModelDir;
  final String offlineModelType;
  final String offlineEncoder;
  final String offlineDecoder;
  final String offlineJoiner;
  final String offlineTokens;

  // VAD 配置
  final String vadModel;
  final double vadMinSilenceDuration;
  final double vadMinSpeechDuration;
  final double vadMaxSpeechDuration;

  /// 是否配置了流式模型
  bool get hasOnlineModel => onlineModelDir.isNotEmpty;

  /// 是否配置了非流式模型
  bool get hasOfflineModel => offlineModelDir.isNotEmpty;

  /// 是否配置了 VAD
  bool get hasVad => vadModel.isNotEmpty;

  factory ASRConfig.fromJson(Map<String, dynamic> json) {
    final asr = json['asr'] as Map<String, dynamic>? ?? {};
    final online = asr['online'] as Map<String, dynamic>? ?? {};
    final offline = asr['offline'] as Map<String, dynamic>? ?? {};
    final vad = asr['vad'] as Map<String, dynamic>? ?? {};

    return ASRConfig(
      onlineModelDir: online['modelDir'] ?? '',
      onlineModelType: online['modelType'] ?? 'zipformer',
      onlineEncoder: online['encoder'] ?? 'encoder.onnx',
      onlineDecoder: online['decoder'] ?? 'decoder.onnx',
      onlineJoiner: online['joiner'] ?? 'joiner.onnx',
      onlineTokens: online['tokens'] ?? 'tokens.txt',
      offlineModelDir: offline['modelDir'] ?? '',
      offlineModelType: offline['modelType'] ?? 'whisper',
      offlineEncoder: offline['encoder'] ?? 'encoder.onnx',
      offlineDecoder: offline['decoder'] ?? 'decoder.onnx',
      offlineJoiner: offline['joiner'] ?? '',
      offlineTokens: offline['tokens'] ?? 'tokens.txt',
      vadModel: vad['model'] ?? '',
      vadMinSilenceDuration: (vad['minSilenceDuration'] ?? 0.25).toDouble(),
      vadMinSpeechDuration: (vad['minSpeechDuration'] ?? 0.5).toDouble(),
      vadMaxSpeechDuration: (vad['maxSpeechDuration'] ?? 5.0).toDouble(),
    );
  }
}

/// 本地 ASR 服务
/// 基于 sherpa_onnx 实现本地语音识别
class LocalASRService extends ChangeNotifier {
  LocalASRService._();

  static LocalASRService? _instance;
  static LocalASRService get instance => _instance ??= LocalASRService._();

  static const int sampleRate = 16000;

  bool _isInitialized = false;
  ASRConfig? _config;

  // 流式识别相关
  sherpa_onnx.OnlineRecognizer? _onlineRecognizer;
  sherpa_onnx.OnlineStream? _onlineStream;
  bool _isStreaming = false;
  String _lastText = '';
  int _index = 0;
  DateTime? _streamingStartTime;

  // 非流式识别相关
  sherpa_onnx.OfflineRecognizer? _offlineRecognizer;
  sherpa_onnx.VoiceActivityDetector? _vad;
  sherpa_onnx.CircularBuffer? _buffer;
  sherpa_onnx.SileroVadModelConfig? _sileroVadConfig;

  // 流式结果控制器
  final StreamController<StreamingTranscriptionEvent> _streamingController =
      StreamController<StreamingTranscriptionEvent>.broadcast();

  /// 获取流式识别结果流
  Stream<StreamingTranscriptionEvent> get streamingResults =>
      _streamingController.stream;

  /// 是否正在流式识别
  bool get isStreaming => _isStreaming;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取配置
  ASRConfig? get config => _config;

  /// 初始化服务（传入从 config.json 解析的配置）
  Future<void> initialize(ASRConfig config) async {
    if (_isInitialized) return;

    _config = config;
    sherpa_onnx.initBindings();
    _isInitialized = true;
    notifyListeners();
  }

  /// 创建流式识别器
  Future<void> _createOnlineRecognizer() async {
    if (_config == null || !_config!.hasOnlineModel) {
      throw StateError(
          'Online model not configured. Please set asr.online.modelDir in config.json');
    }

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
    debugPrint(
        'Online recognizer created with model: ${_config!.onlineModelType}');
  }

  /// 创建非流式识别器
  Future<void> _createOfflineRecognizer() async {
    if (_config == null || !_config!.hasOfflineModel) {
      throw StateError(
          'Offline model not configured. Please set asr.offline.modelDir in config.json');
    }

    final dir = _config!.offlineModelDir;
    sherpa_onnx.OfflineModelConfig modelConfig;

    switch (_config!.offlineModelType) {
      case 'whisper':
        modelConfig = sherpa_onnx.OfflineModelConfig(
          whisper: sherpa_onnx.OfflineWhisperModelConfig(
            encoder: '$dir/${_config!.offlineEncoder}',
            decoder: '$dir/${_config!.offlineDecoder}',
          ),
          tokens: '$dir/${_config!.offlineTokens}',
          modelType: 'whisper',
        );
        break;
      case 'sense_voice':
        modelConfig = sherpa_onnx.OfflineModelConfig(
          senseVoice: sherpa_onnx.OfflineSenseVoiceModelConfig(
            model: '$dir/${_config!.offlineEncoder}',
          ),
          tokens: '$dir/${_config!.offlineTokens}',
        );
        break;
      case 'zipformer2_ctc':
        modelConfig = sherpa_onnx.OfflineModelConfig(
          zipformerCtc: sherpa_onnx.OfflineZipformerCtcModelConfig(
            model: '$dir/${_config!.offlineEncoder}',
          ),
          tokens: '$dir/${_config!.offlineTokens}',
        );
        break;
      default:
        // transducer 类型模型 (nemo_transducer, zipformer 等)
        modelConfig = sherpa_onnx.OfflineModelConfig(
          transducer: sherpa_onnx.OfflineTransducerModelConfig(
            encoder: '$dir/${_config!.offlineEncoder}',
            decoder: '$dir/${_config!.offlineDecoder}',
            joiner: '$dir/${_config!.offlineJoiner}',
          ),
          tokens: '$dir/${_config!.offlineTokens}',
          modelType: _config!.offlineModelType,
        );
    }

    final config = sherpa_onnx.OfflineRecognizerConfig(model: modelConfig);
    _offlineRecognizer = sherpa_onnx.OfflineRecognizer(config);
    debugPrint(
        'Offline recognizer created with model: ${_config!.offlineModelType}');
  }

  /// 创建 VAD
  Future<void> _createVad() async {
    if (_config == null || !_config!.hasVad) {
      throw StateError(
          'VAD model not configured. Please set asr.vad.model in config.json');
    }

    _sileroVadConfig = sherpa_onnx.SileroVadModelConfig(
      model: _config!.vadModel,
      minSilenceDuration: _config!.vadMinSilenceDuration,
      minSpeechDuration: _config!.vadMinSpeechDuration,
      maxSpeechDuration: _config!.vadMaxSpeechDuration,
    );

    final vadConfig = sherpa_onnx.VadModelConfig(
      sileroVad: _sileroVadConfig!,
      numThreads: 1,
      debug: false,
    );

    _vad = sherpa_onnx.VoiceActivityDetector(
      config: vadConfig,
      bufferSizeInSeconds: 30,
    );
    _buffer = sherpa_onnx.CircularBuffer(capacity: 30 * sampleRate);
    debugPrint('VAD created');
  }

  // ==================== 流式识别 API ====================

  /// 开始流式识别
  Future<void> startStreaming() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized. Call initialize() first.');
    }
    if (_isStreaming) {
      debugPrint('Already streaming, ignoring start request');
      return;
    }

    // 懒加载创建识别器
    if (_onlineRecognizer == null) {
      await _createOnlineRecognizer();
    }

    _onlineStream = _onlineRecognizer!.createStream();
    _isStreaming = true;
    _lastText = '';
    _index = 0;
    _streamingStartTime = DateTime.now();
    notifyListeners();
    debugPrint('Streaming started');
  }

  /// 输入音频数据（流式识别）
  void feedAudioData(Uint8List audioData) {
    if (!_isStreaming || _onlineStream == null || _onlineRecognizer == null) {
      return;
    }

    final samples = _convertBytesToFloat32(audioData);
    _onlineStream!.acceptWaveform(samples: samples, sampleRate: sampleRate);

    // 解码
    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    // 检查端点
    final isEndpoint = _onlineRecognizer!.isEndpoint(_onlineStream!);

    // 获取当前部分结果
    final text = _onlineRecognizer!.getResult(_onlineStream!).text;

    // 构建显示文本
    String textToDisplay;
    if (_lastText.isEmpty) {
      textToDisplay = text;
    } else if (text.isEmpty) {
      textToDisplay = _lastText;
    } else {
      textToDisplay = '$_lastText\n$text';
    }

    // 如果检测到端点，保存当前结果并重置流
    if (isEndpoint) {
      if (text.isNotEmpty) {
        _index += 1;
        if (_lastText.isEmpty) {
          _lastText = text;
        } else {
          _lastText = '$_lastText\n$text';
        }
        textToDisplay = _lastText;
      }
      _onlineRecognizer!.reset(_onlineStream!);
    }

    // 发送事件（只要有文本就发送，让 UI 实时更新）
    if (textToDisplay.isNotEmpty) {
      _streamingController.add(StreamingTranscriptionEvent(
        text: textToDisplay,
        isFinal: isEndpoint,
        index: _index,
      ));
    }
  }

  /// 停止流式识别并返回结果
  Future<TranscriptionResult> stopStreaming() async {
    if (!_isStreaming) {
      return const TranscriptionResult(text: '', duration: Duration.zero);
    }

    final duration = _streamingStartTime != null
        ? DateTime.now().difference(_streamingStartTime!)
        : Duration.zero;

    final finalText = _lastText;

    // 释放当前流并创建新流（为下次使用准备）
    _onlineStream?.free();
    _onlineStream = _onlineRecognizer?.createStream();

    _isStreaming = false;
    _lastText = '';
    _index = 0;
    _streamingStartTime = null;
    notifyListeners();
    debugPrint('Streaming stopped, duration: $duration');

    return TranscriptionResult(text: finalText, duration: duration);
  }

  // ==================== 非流式识别 API (带 VAD) ====================

  /// 开始非流式识别（带 VAD）
  Future<void> startOfflineWithVad() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized. Call initialize() first.');
    }

    // 懒加载创建识别器和 VAD
    if (_offlineRecognizer == null) {
      await _createOfflineRecognizer();
    }
    if (_vad == null) {
      await _createVad();
    }

    _index = 0;
    _lastText = '';
    _streamingStartTime = DateTime.now();
    _isStreaming = true;
    notifyListeners();
    debugPrint('Offline with VAD started');
  }

  /// 输入音频数据（非流式 + VAD）
  void feedAudioDataOffline(Uint8List audioData) {
    if (!_isStreaming ||
        _offlineRecognizer == null ||
        _vad == null ||
        _buffer == null) {
      return;
    }

    final samples = _convertBytesToFloat32(audioData);
    _buffer!.push(samples);

    // VAD 窗口大小
    final windowSize = _sileroVadConfig?.windowSize ?? 512;

    while (_buffer!.size > windowSize) {
      final windowSamples = _buffer!.get(
        startIndex: _buffer!.head,
        n: windowSize,
      );
      _buffer!.pop(windowSize);
      _vad!.acceptWaveform(windowSamples);

      // 处理检测到的语音段
      while (!_vad!.isEmpty()) {
        final segment = _vad!.front();
        final segmentSamples = segment.samples;

        // 创建离线流进行识别
        final stream = _offlineRecognizer!.createStream();
        stream.acceptWaveform(samples: segmentSamples, sampleRate: sampleRate);
        _offlineRecognizer!.decode(stream);
        final text = _offlineRecognizer!.getResult(stream).text;
        stream.free();
        _vad!.pop();

        if (text.isNotEmpty) {
          _index += 1;
          String textToDisplay;
          if (_lastText.isEmpty) {
            textToDisplay = '$_index: $text';
          } else {
            textToDisplay = '$_index: $text\n$_lastText';
          }
          _lastText = textToDisplay;

          _streamingController.add(StreamingTranscriptionEvent(
            text: textToDisplay,
            isFinal: true,
            index: _index,
          ));
        }
      }
    }
  }

  /// 停止非流式识别并刷新 VAD 缓冲区
  Future<TranscriptionResult> stopOfflineWithVad() async {
    if (!_isStreaming || _vad == null) {
      return const TranscriptionResult(text: '', duration: Duration.zero);
    }

    // 刷新 VAD 处理剩余数据
    _vad!.flush();
    while (!_vad!.isEmpty()) {
      final segment = _vad!.front();
      final samples = segment.samples;

      final stream = _offlineRecognizer!.createStream();
      stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
      _offlineRecognizer!.decode(stream);
      final text = _offlineRecognizer!.getResult(stream).text;
      stream.free();
      _vad!.pop();

      if (text.isNotEmpty) {
        _index += 1;
        String textToDisplay;
        if (_lastText.isEmpty) {
          textToDisplay = '$_index: $text';
        } else {
          textToDisplay = '$_index: $text\n$_lastText';
        }
        _lastText = textToDisplay;

        _streamingController.add(StreamingTranscriptionEvent(
          text: textToDisplay,
          isFinal: true,
          index: _index,
        ));
      }
    }

    final duration = _streamingStartTime != null
        ? DateTime.now().difference(_streamingStartTime!)
        : Duration.zero;

    final finalText = _lastText;

    _isStreaming = false;
    _lastText = '';
    _index = 0;
    _streamingStartTime = null;
    notifyListeners();
    debugPrint('Offline with VAD stopped, duration: $duration');

    return TranscriptionResult(text: finalText, duration: duration);
  }

  // ==================== 工具方法 ====================

  /// 字节转 Float32（官方实现）
  Float32List _convertBytesToFloat32(Uint8List bytes,
      [Endian endian = Endian.little]) {
    final values = Float32List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer);

    for (var i = 0; i < bytes.length; i += 2) {
      int short = data.getInt16(i, endian);
      values[i ~/ 2] = short / 32768.0;
    }

    return values;
  }

  /// 检查流式模型是否可用
  bool get isOnlineAvailable => _config?.hasOnlineModel ?? false;

  /// 检查非流式模型是否可用
  bool get isOfflineAvailable => _config?.hasOfflineModel ?? false;

  /// 检查 VAD 是否可用
  bool get isVadAvailable => _config?.hasVad ?? false;

  /// 释放流式识别器资源
  void freeOnlineRecognizer() {
    _onlineStream?.free();
    _onlineStream = null;
    _onlineRecognizer?.free();
    _onlineRecognizer = null;
    debugPrint('Online recognizer freed');
  }

  /// 释放非流式识别器资源
  void freeOfflineRecognizer() {
    _offlineRecognizer?.free();
    _offlineRecognizer = null;
    _vad?.free();
    _vad = null;
    _buffer?.free();
    _buffer = null;
    debugPrint('Offline recognizer and VAD freed');
  }

  /// 释放所有资源
  @override
  void dispose() {
    if (_isStreaming) {
      _isStreaming = false;
    }
    freeOnlineRecognizer();
    freeOfflineRecognizer();
    _streamingController.close();
    _isInitialized = false;
    super.dispose();
  }
}

/// ASR 模型配置
/// 从 config.json 读取模型路径配置

export 'local_asr_service.dart' show ASRConfig;

/// 支持的模型类型
class ASRModelTypes {
  ASRModelTypes._();

  // 流式模型类型
  static const String zipformer = 'zipformer';
  static const String zipformer2 = 'zipformer2';
  static const String paraformer = 'paraformer';

  // 非流式模型类型
  static const String whisper = 'whisper';
  static const String senseVoice = 'sense_voice';
  static const String nemoTransducer = 'nemo_transducer';

  /// 获取所有流式模型类型
  static List<String> get onlineTypes => [zipformer, zipformer2, paraformer];

  /// 获取所有非流式模型类型
  static List<String> get offlineTypes => [whisper, senseVoice, nemoTransducer];
}

/// 模型配置说明
/// 
/// config.json 中的 asr 配置示例：
/// ```json
/// {
///   "asr": {
///     "online": {
///       "modelDir": "C:/models/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20",
///       "modelType": "zipformer",
///       "encoder": "encoder-epoch-99-avg-1.int8.onnx",
///       "decoder": "decoder-epoch-99-avg-1.onnx",
///       "joiner": "joiner-epoch-99-avg-1.onnx",
///       "tokens": "tokens.txt"
///     },
///     "offline": {
///       "modelDir": "C:/models/whisper",
///       "modelType": "whisper",
///       "encoder": "base-encoder.onnx",
///       "decoder": "base-decoder.onnx",
///       "joiner": "",
///       "tokens": "base-tokens.txt"
///     },
///     "vad": {
///       "model": "C:/models/silero_vad.onnx",
///       "minSilenceDuration": 0.25,
///       "minSpeechDuration": 0.5,
///       "maxSpeechDuration": 5.0
///     }
///   }
/// }
/// ```
/// 
/// 模型下载地址：
/// - 流式模型: https://github.com/k2-fsa/sherpa-onnx/releases (搜索 streaming)
/// - 非流式模型: https://github.com/k2-fsa/sherpa-onnx/releases (搜索 whisper/sense-voice)
/// - VAD 模型: https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx

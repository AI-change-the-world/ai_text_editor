import 'package:objectbox/objectbox.dart';

/// AI 任务类型枚举
enum AITask {
  chat, // 对话/问答
  writing, // 写作辅助
  embedding, // 文本嵌入
  translation, // 翻译
  summarization, // 摘要
  qa, // 知识问答
  code, // 代码辅助
}

/// 模型配置实体
/// 统一管理所有 AI 模型配置
@Entity()
class ModelProfile {
  @Id()
  int id = 0;

  /// 唯一标识符/标签
  @Unique()
  String tag;

  /// 配置名称（显示用）
  String name;

  /// 提供商 (openai, anthropic, deepseek, ollama, etc.)
  String provider;

  /// 模型名称 (gpt-4, claude-3, etc.)
  String modelName;

  /// API Key
  String apiKey;

  /// API 地址
  String baseUrl;

  /// 任务类型 (存储为 int)
  int taskTypeIndex;

  /// 是否为该任务的默认模型
  bool isDefault;

  /// 是否启用
  bool isEnabled;

  /// 温度参数
  double temperature;

  /// 最大 token 数
  int maxTokens;

  /// 系统提示词
  String? systemPrompt;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  ModelProfile({
    this.id = 0,
    required this.tag,
    required this.name,
    required this.provider,
    required this.modelName,
    required this.apiKey,
    required this.baseUrl,
    this.taskTypeIndex = 0, // AITask.chat
    this.isDefault = false,
    this.isEnabled = true,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.systemPrompt,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取任务类型
  AITask get taskType => AITask.values[taskTypeIndex];

  /// 设置任务类型
  set taskType(AITask value) {
    taskTypeIndex = value.index;
  }

  /// 创建空模型配置
  static ModelProfile empty() {
    return ModelProfile(
      tag: '',
      name: '',
      provider: '',
      modelName: '',
      apiKey: '',
      baseUrl: '',
    );
  }

  /// 从旧的 Model 迁移
  static ModelProfile fromLegacyModel({
    required String tag,
    required String baseUrl,
    required String modelName,
    required String sk,
    AITask taskType = AITask.chat,
  }) {
    return ModelProfile(
      tag: tag,
      name: tag,
      provider: _inferProvider(baseUrl),
      modelName: modelName,
      apiKey: sk,
      baseUrl: baseUrl,
      taskTypeIndex: taskType.index,
    );
  }

  /// 根据 baseUrl 推断提供商
  static String _inferProvider(String baseUrl) {
    if (baseUrl.contains('openai')) return 'openai';
    if (baseUrl.contains('anthropic')) return 'anthropic';
    if (baseUrl.contains('deepseek')) return 'deepseek';
    if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
      return 'ollama';
    }
    return 'custom';
  }

  /// 复制并修改
  ModelProfile copyWith({
    int? id,
    String? tag,
    String? name,
    String? provider,
    String? modelName,
    String? apiKey,
    String? baseUrl,
    int? taskTypeIndex,
    bool? isDefault,
    bool? isEnabled,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    int? createdAt,
    int? updatedAt,
  }) {
    return ModelProfile(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      taskTypeIndex: taskTypeIndex ?? this.taskTypeIndex,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:objectbox/objectbox.dart';

/// AI 任务类型枚举
enum AITask {
  writing, // 写作
  qa, // 问答
  translation, // 翻译
  summarization, // 摘要
  code, // 代码
  embedding, // 嵌入
}

/// 模型配置实体
/// 针对特定任务配置的 AI 模型
/// Requirements: 7.4, 7.5
@Entity()
class ModelProfile {
  @Id()
  int id = 0;

  /// 唯一标识符
  @Unique()
  String uuid;

  /// 配置名称
  String name;

  /// 提供商 (openai, anthropic, deepseek, ollama)
  String provider;

  /// 模型名称 (gpt-4, claude-3, etc.)
  String modelName;

  /// API Key (加密存储)
  String? apiKey;

  /// 自定义 API 地址
  String? baseUrl;

  /// 任务类型 (存储为 int)
  int taskTypeIndex;

  /// 是否为该任务的默认模型
  bool isDefault;

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
    required this.uuid,
    required this.name,
    required this.provider,
    required this.modelName,
    this.apiKey,
    this.baseUrl,
    this.taskTypeIndex = 0, // AITask.writing
    this.isDefault = false,
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
      uuid: '',
      name: '',
      provider: '',
      modelName: '',
    );
  }

  /// 复制并修改
  ModelProfile copyWith({
    int? id,
    String? uuid,
    String? name,
    String? provider,
    String? modelName,
    String? apiKey,
    String? baseUrl,
    int? taskTypeIndex,
    bool? isDefault,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    int? createdAt,
    int? updatedAt,
  }) {
    return ModelProfile(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      taskTypeIndex: taskTypeIndex ?? this.taskTypeIndex,
      isDefault: isDefault ?? this.isDefault,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../data/datasources/objectbox/entities/model_profile.dart';
import '../data/datasources/objectbox/database.dart';
import '../objectbox.g.dart';

/// AI 提供商枚举
/// Requirements: 7.5
enum AIProvider {
  openai('openai', 'OpenAI', 'https://api.openai.com/v1'),
  anthropic('anthropic', 'Anthropic', 'https://api.anthropic.com/v1'),
  deepseek('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1'),
  ollama('ollama', 'Ollama (Local)', 'http://localhost:11434/v1');

  final String id;
  final String displayName;
  final String defaultBaseUrl;

  const AIProvider(this.id, this.displayName, this.defaultBaseUrl);

  static AIProvider? fromId(String id) {
    for (final provider in values) {
      if (provider.id == id) return provider;
    }
    return null;
  }
}

/// 创建模型配置请求
class CreateModelProfileRequest {
  final String name;
  final String provider;
  final String modelName;
  final String? apiKey;
  final String? baseUrl;
  final AITask taskType;
  final bool isDefault;
  final double temperature;
  final int maxTokens;
  final String? systemPrompt;

  CreateModelProfileRequest({
    required this.name,
    required this.provider,
    required this.modelName,
    this.apiKey,
    this.baseUrl,
    this.taskType = AITask.writing,
    this.isDefault = false,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.systemPrompt,
  });
}

/// 更新模型配置请求
class UpdateModelProfileRequest {
  final String? name;
  final String? provider;
  final String? modelName;
  final String? apiKey;
  final String? baseUrl;
  final AITask? taskType;
  final bool? isDefault;
  final double? temperature;
  final int? maxTokens;
  final String? systemPrompt;

  UpdateModelProfileRequest({
    this.name,
    this.provider,
    this.modelName,
    this.apiKey,
    this.baseUrl,
    this.taskType,
    this.isDefault,
    this.temperature,
    this.maxTokens,
    this.systemPrompt,
  });
}

/// 模型配置服务接口
/// Requirements: 7.4, 7.5
abstract class IModelProfileService {
  /// 获取所有模型配置
  Future<List<ModelProfile>> getAllProfiles();

  /// 根据 ID 获取模型配置
  Future<ModelProfile?> getProfileById(String uuid);

  /// 创建模型配置
  Future<ModelProfile> createProfile(CreateModelProfileRequest request);

  /// 更新模型配置
  Future<ModelProfile> updateProfile(
      String uuid, UpdateModelProfileRequest request);

  /// 删除模型配置
  Future<void> deleteProfile(String uuid);

  /// 获取指定任务的默认模型
  Future<ModelProfile?> getDefaultProfileForTask(AITask task);

  /// 设置任务的默认模型
  Future<void> setDefaultProfileForTask(String uuid, AITask task);

  /// 获取指定任务的所有模型
  Future<List<ModelProfile>> getProfilesForTask(AITask task);

  /// 获取指定提供商的所有模型
  Future<List<ModelProfile>> getProfilesByProvider(String provider);

  /// 获取带回退的模型（如果默认模型不可用，返回备用模型）
  /// Requirements: 7.13
  Future<ModelProfile?> getProfileWithFallback(AITask task);

  /// 验证模型配置是否有效
  Future<bool> validateProfile(ModelProfile profile);

  /// 解密 API Key
  String? decryptApiKey(String? encryptedKey);
}

/// 模型配置服务实现
/// Requirements: 7.4, 7.5, 7.13
class ModelProfileService implements IModelProfileService {
  final ObxDatabase _db;
  final Uuid _uuid = const Uuid();

  // 用于加密的密钥（在生产环境中应该从安全存储获取）
  static const String _encryptionKey = 'ai_text_editor_secure_key_2024';

  ModelProfileService(this._db);

  /// 获取单例实例
  static ModelProfileService? _instance;

  /// 获取单例实例（懒加载）
  static ModelProfileService get instance {
    _instance ??= ModelProfileService(ObxDatabase.db);
    return _instance!;
  }

  /// 加密 API Key
  /// Requirements: 7.5
  String _encryptApiKey(String apiKey) {
    final key = utf8.encode(_encryptionKey);
    final bytes = utf8.encode(apiKey);

    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);

    // 使用简单的 XOR 加密（结合 HMAC 作为密钥派生）
    final derivedKey = digest.bytes;
    final encrypted = <int>[];

    for (var i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ derivedKey[i % derivedKey.length]);
    }

    return base64Encode(encrypted);
  }

  /// 解密 API Key
  /// Requirements: 7.5
  @override
  String? decryptApiKey(String? encryptedKey) {
    if (encryptedKey == null || encryptedKey.isEmpty) return null;

    try {
      final key = utf8.encode(_encryptionKey);
      final encrypted = base64Decode(encryptedKey);

      final hmacSha256 = Hmac(sha256, key);
      // 我们需要原始密钥来派生相同的密钥流
      // 由于 XOR 是对称的，我们可以用相同的方法解密
      final derivedKey = hmacSha256.convert(utf8.encode(_encryptionKey)).bytes;

      final decrypted = <int>[];
      for (var i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ derivedKey[i % derivedKey.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      return null;
    }
  }

  /// 获取所有模型配置
  @override
  Future<List<ModelProfile>> getAllProfiles() async {
    final query = _db.modelProfileBox.query().order(ModelProfile_.name).build();

    final profiles = query.find();
    query.close();
    return profiles;
  }

  /// 根据 ID 获取模型配置
  @override
  Future<ModelProfile?> getProfileById(String uuid) async {
    final query =
        _db.modelProfileBox.query(ModelProfile_.uuid.equals(uuid)).build();

    final profile = query.findFirst();
    query.close();
    return profile;
  }

  /// 创建模型配置
  /// Requirements: 7.4, 7.5
  @override
  Future<ModelProfile> createProfile(CreateModelProfileRequest request) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 如果设置为默认，先取消其他同任务类型的默认设置
    if (request.isDefault) {
      await _clearDefaultForTask(request.taskType);
    }

    // 加密 API Key
    String? encryptedApiKey;
    if (request.apiKey != null && request.apiKey!.isNotEmpty) {
      encryptedApiKey = _encryptApiKey(request.apiKey!);
    }

    // 获取提供商的默认 base URL
    String? baseUrl = request.baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      final provider = AIProvider.fromId(request.provider);
      baseUrl = provider?.defaultBaseUrl;
    }

    final profile = ModelProfile(
      uuid: _uuid.v4(),
      name: request.name,
      provider: request.provider,
      modelName: request.modelName,
      apiKey: encryptedApiKey,
      baseUrl: baseUrl,
      taskTypeIndex: request.taskType.index,
      isDefault: request.isDefault,
      temperature: request.temperature,
      maxTokens: request.maxTokens,
      systemPrompt: request.systemPrompt,
      createdAt: now,
      updatedAt: now,
    );

    _db.modelProfileBox.put(profile);
    return profile;
  }

  /// 更新模型配置
  @override
  Future<ModelProfile> updateProfile(
      String uuid, UpdateModelProfileRequest request) async {
    final existing = await getProfileById(uuid);
    if (existing == null) {
      throw ModelProfileNotFoundException(uuid);
    }

    // 如果设置为默认，先取消其他同任务类型的默认设置
    final newTaskType = request.taskType ?? existing.taskType;
    if (request.isDefault == true) {
      await _clearDefaultForTask(newTaskType);
    }

    // 处理 API Key 更新
    String? encryptedApiKey = existing.apiKey;
    if (request.apiKey != null) {
      if (request.apiKey!.isNotEmpty) {
        encryptedApiKey = _encryptApiKey(request.apiKey!);
      } else {
        encryptedApiKey = null;
      }
    }

    final updated = existing.copyWith(
      name: request.name ?? existing.name,
      provider: request.provider ?? existing.provider,
      modelName: request.modelName ?? existing.modelName,
      apiKey: encryptedApiKey,
      baseUrl: request.baseUrl ?? existing.baseUrl,
      taskTypeIndex: newTaskType.index,
      isDefault: request.isDefault ?? existing.isDefault,
      temperature: request.temperature ?? existing.temperature,
      maxTokens: request.maxTokens ?? existing.maxTokens,
      systemPrompt: request.systemPrompt ?? existing.systemPrompt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.modelProfileBox.put(updated);
    return updated;
  }

  /// 删除模型配置
  @override
  Future<void> deleteProfile(String uuid) async {
    final query =
        _db.modelProfileBox.query(ModelProfile_.uuid.equals(uuid)).build();

    final profile = query.findFirst();
    query.close();

    if (profile == null) {
      throw ModelProfileNotFoundException(uuid);
    }

    _db.modelProfileBox.remove(profile.id);
  }

  /// 获取指定任务的默认模型
  @override
  Future<ModelProfile?> getDefaultProfileForTask(AITask task) async {
    final query = _db.modelProfileBox
        .query(ModelProfile_.taskTypeIndex.equals(task.index) &
            ModelProfile_.isDefault.equals(true))
        .build();

    final profile = query.findFirst();
    query.close();
    return profile;
  }

  /// 设置任务的默认模型
  @override
  Future<void> setDefaultProfileForTask(String uuid, AITask task) async {
    // 先取消其他同任务类型的默认设置
    await _clearDefaultForTask(task);

    // 设置新的默认模型
    final profile = await getProfileById(uuid);
    if (profile == null) {
      throw ModelProfileNotFoundException(uuid);
    }

    final updated = profile.copyWith(
      isDefault: true,
      taskTypeIndex: task.index,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _db.modelProfileBox.put(updated);
  }

  /// 获取指定任务的所有模型
  @override
  Future<List<ModelProfile>> getProfilesForTask(AITask task) async {
    final query = _db.modelProfileBox
        .query(ModelProfile_.taskTypeIndex.equals(task.index))
        .order(ModelProfile_.isDefault, flags: Order.descending)
        .order(ModelProfile_.name)
        .build();

    final profiles = query.find();
    query.close();
    return profiles;
  }

  /// 获取指定提供商的所有模型
  @override
  Future<List<ModelProfile>> getProfilesByProvider(String provider) async {
    final query = _db.modelProfileBox
        .query(ModelProfile_.provider.equals(provider))
        .order(ModelProfile_.name)
        .build();

    final profiles = query.find();
    query.close();
    return profiles;
  }

  /// 获取带回退的模型
  /// 如果默认模型不可用或验证失败，尝试返回同任务类型的其他可用模型
  /// Requirements: 7.13
  @override
  Future<ModelProfile?> getProfileWithFallback(AITask task) async {
    // 首先尝试获取默认模型
    final defaultProfile = await getDefaultProfileForTask(task);
    if (defaultProfile != null && await validateProfile(defaultProfile)) {
      return defaultProfile;
    }

    // 如果默认模型不可用，获取同任务类型的其他模型
    final profiles = await getProfilesForTask(task);
    for (final profile in profiles) {
      if (profile.uuid != defaultProfile?.uuid &&
          await validateProfile(profile)) {
        return profile;
      }
    }

    // 如果同任务类型没有可用模型，尝试获取任意可用模型
    final allProfiles = await getAllProfiles();
    for (final profile in allProfiles) {
      if (await validateProfile(profile)) {
        return profile;
      }
    }

    return null;
  }

  /// 验证模型配置是否有效
  /// 检查必要字段是否存在，API Key 是否有效（对于非本地模型）
  @override
  Future<bool> validateProfile(ModelProfile profile) async {
    // 基本字段验证
    if (profile.name.isEmpty ||
        profile.provider.isEmpty ||
        profile.modelName.isEmpty) {
      return false;
    }

    // Ollama 是本地模型，不需要 API Key
    if (profile.provider == AIProvider.ollama.id) {
      return true;
    }

    // 其他提供商需要 API Key
    final apiKey = decryptApiKey(profile.apiKey);
    if (apiKey == null || apiKey.isEmpty) {
      return false;
    }

    return true;
  }

  /// 清除指定任务类型的默认设置
  Future<void> _clearDefaultForTask(AITask task) async {
    final query = _db.modelProfileBox
        .query(ModelProfile_.taskTypeIndex.equals(task.index) &
            ModelProfile_.isDefault.equals(true))
        .build();

    final profiles = query.find();
    query.close();

    for (final profile in profiles) {
      final updated = profile.copyWith(
        isDefault: false,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _db.modelProfileBox.put(updated);
    }
  }

  /// 获取提供商的推荐模型列表
  /// Requirements: 7.5
  static List<String> getRecommendedModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-4-turbo',
          'gpt-4',
          'gpt-3.5-turbo',
          'text-embedding-3-small',
          'text-embedding-3-large',
        ];
      case AIProvider.anthropic:
        return [
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
          'claude-3-opus-20240229',
          'claude-3-sonnet-20240229',
          'claude-3-haiku-20240307',
        ];
      case AIProvider.deepseek:
        return [
          'deepseek-chat',
          'deepseek-coder',
          'deepseek-reasoner',
        ];
      case AIProvider.ollama:
        return [
          'llama3.2',
          'llama3.1',
          'mistral',
          'codellama',
          'phi3',
          'gemma2',
          'qwen2.5',
          'nomic-embed-text',
        ];
    }
  }

  /// 获取任务类型的推荐系统提示词
  static String? getDefaultSystemPrompt(AITask task) {
    switch (task) {
      case AITask.writing:
        return '你是一个专业的写作助手，帮助用户改进文章质量、润色文字、扩展内容。请保持用户的写作风格，同时提升表达的清晰度和流畅性。';
      case AITask.qa:
        return '你是一个知识问答助手，基于提供的上下文信息回答用户问题。如果上下文中没有相关信息，请诚实地说明。回答时请引用来源。';
      case AITask.translation:
        return '你是一个专业的翻译助手，能够准确翻译多种语言。请保持原文的语气和风格，同时确保译文自然流畅。';
      case AITask.summarization:
        return '你是一个摘要生成助手，能够提取文本的关键信息并生成简洁的摘要。请保留重要细节，同时去除冗余内容。';
      case AITask.code:
        return '你是一个编程助手，帮助用户编写、调试和优化代码。请提供清晰的代码示例和解释，遵循最佳实践。';
      case AITask.embedding:
        return null; // 嵌入模型不需要系统提示词
    }
  }

  /// 创建默认模型配置（用于初始化）
  Future<void> createDefaultProfiles() async {
    final existing = await getAllProfiles();
    if (existing.isNotEmpty) return;

    // 创建 OpenAI 默认配置
    await createProfile(CreateModelProfileRequest(
      name: 'GPT-4o (Writing)',
      provider: AIProvider.openai.id,
      modelName: 'gpt-4o',
      taskType: AITask.writing,
      isDefault: true,
      systemPrompt: getDefaultSystemPrompt(AITask.writing),
    ));

    await createProfile(CreateModelProfileRequest(
      name: 'GPT-4o (Q&A)',
      provider: AIProvider.openai.id,
      modelName: 'gpt-4o',
      taskType: AITask.qa,
      isDefault: true,
      systemPrompt: getDefaultSystemPrompt(AITask.qa),
    ));

    await createProfile(CreateModelProfileRequest(
      name: 'GPT-4o-mini (Translation)',
      provider: AIProvider.openai.id,
      modelName: 'gpt-4o-mini',
      taskType: AITask.translation,
      isDefault: true,
      systemPrompt: getDefaultSystemPrompt(AITask.translation),
    ));

    await createProfile(CreateModelProfileRequest(
      name: 'GPT-4o-mini (Summary)',
      provider: AIProvider.openai.id,
      modelName: 'gpt-4o-mini',
      taskType: AITask.summarization,
      isDefault: true,
      systemPrompt: getDefaultSystemPrompt(AITask.summarization),
    ));

    await createProfile(CreateModelProfileRequest(
      name: 'GPT-4o (Code)',
      provider: AIProvider.openai.id,
      modelName: 'gpt-4o',
      taskType: AITask.code,
      isDefault: true,
      systemPrompt: getDefaultSystemPrompt(AITask.code),
    ));

    await createProfile(CreateModelProfileRequest(
      name: 'text-embedding-3-small',
      provider: AIProvider.openai.id,
      modelName: 'text-embedding-3-small',
      taskType: AITask.embedding,
      isDefault: true,
    ));
  }
}

/// 模型配置未找到异常
class ModelProfileNotFoundException implements Exception {
  final String uuid;

  ModelProfileNotFoundException(this.uuid);

  @override
  String toString() => 'Model profile not found: $uuid';
}

/// 模型验证失败异常
class ModelProfileValidationException implements Exception {
  final String message;

  ModelProfileValidationException(this.message);

  @override
  String toString() => 'Model profile validation failed: $message';
}

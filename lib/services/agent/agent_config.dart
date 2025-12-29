/// Agent configuration models
///
/// This file defines configuration options for AI agents,
/// including preset configurations for different use cases.
/// Requirements: 7.7, 7.6, 4.4
library;

/// Agent type enumeration for categorizing agents.
enum AgentType {
  /// Research-focused agent for information retrieval and synthesis.
  research,

  /// Writing-focused agent for content creation and editing.
  writing,

  /// Q&A-focused agent for answering questions from knowledge base.
  qa,

  /// Code-focused agent for code-related tasks.
  code,

  /// Custom user-defined agent.
  custom,
}

/// Configuration for an AI Agent.
///
/// Defines the agent's behavior, available tools, and system prompt.
class AgentConfig {
  /// Unique identifier for the agent configuration.
  final String id;

  /// Display name of the agent.
  final String name;

  /// Description of what the agent does.
  final String description;

  /// The type of agent.
  final AgentType type;

  /// List of tool names this agent can use.
  ///
  /// If empty, all registered tools are available.
  final List<String> enabledTools;

  /// System prompt that defines the agent's behavior.
  final String systemPrompt;

  /// Optional icon for the agent (emoji or icon name).
  final String? icon;

  /// Temperature setting for the LLM (0.0 - 1.0).
  final double temperature;

  /// Maximum tokens for the response.
  final int maxTokens;

  /// Whether this agent requires RAG context.
  final bool requiresRagContext;

  /// Whether this agent can use deep search (web search).
  final bool canUseDeepSearch;

  /// Priority order for display (lower = higher priority).
  final int displayOrder;

  /// Creates a new [AgentConfig].
  const AgentConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.enabledTools,
    required this.systemPrompt,
    this.icon,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.requiresRagContext = false,
    this.canUseDeepSearch = false,
    this.displayOrder = 100,
  });

  /// Creates a copy with modified fields.
  AgentConfig copyWith({
    String? id,
    String? name,
    String? description,
    AgentType? type,
    List<String>? enabledTools,
    String? systemPrompt,
    String? icon,
    double? temperature,
    int? maxTokens,
    bool? requiresRagContext,
    bool? canUseDeepSearch,
    int? displayOrder,
  }) {
    return AgentConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      enabledTools: enabledTools ?? this.enabledTools,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      icon: icon ?? this.icon,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      requiresRagContext: requiresRagContext ?? this.requiresRagContext,
      canUseDeepSearch: canUseDeepSearch ?? this.canUseDeepSearch,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// Converts to JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'enabledTools': enabledTools,
      'systemPrompt': systemPrompt,
      if (icon != null) 'icon': icon,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'requiresRagContext': requiresRagContext,
      'canUseDeepSearch': canUseDeepSearch,
      'displayOrder': displayOrder,
    };
  }

  /// Creates from JSON map.
  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    return AgentConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: AgentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AgentType.custom,
      ),
      enabledTools: List<String>.from(json['enabledTools'] as List),
      systemPrompt: json['systemPrompt'] as String,
      icon: json['icon'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      requiresRagContext: json['requiresRagContext'] as bool? ?? false,
      canUseDeepSearch: json['canUseDeepSearch'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 100,
    );
  }

  @override
  String toString() {
    return 'AgentConfig(id: $id, name: $name, type: ${type.name}, tools: ${enabledTools.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Predefined agent configurations for common use cases.
///
/// Requirements: 7.7, 7.6, 4.4
class AgentPresets {
  AgentPresets._();

  /// Research Assistant - specialized in information retrieval and synthesis.
  ///
  /// Best for:
  /// - Finding information in the knowledge base
  /// - Searching the web for additional resources
  /// - Compiling research reports
  /// - Cross-referencing multiple sources
  ///
  /// Requirements: 7.7
  static const AgentConfig researchAssistant = AgentConfig(
    id: 'research_assistant',
    name: 'Research Assistant',
    description: '帮助你搜索、整理和分析信息，支持跨工作空间检索和网络深度搜索',
    type: AgentType.research,
    icon: '🔍',
    displayOrder: 1,
    temperature: 0.5,
    maxTokens: 8192,
    requiresRagContext: true,
    canUseDeepSearch: true,
    enabledTools: [
      'full_text_search',
      'vector_search',
      'deep_search',
      'summarize',
      'document_operation',
    ],
    systemPrompt: '''你是一个专业的研究助手，擅长信息检索、整理和分析。

## 核心能力
1. **知识库检索**: 在用户的知识库中查找相关信息，支持语义搜索和关键词搜索
2. **网络深度搜索**: 当知识库信息不足时，可以在互联网上搜索补充资料
3. **信息整合**: 整合多个来源的信息，生成结构化的研究报告
4. **来源追溯**: 始终标注信息来源，方便用户验证和深入阅读

## 工作原则
- 优先使用知识库中的信息，确保回答基于用户已有的知识
- 明确区分事实和推测，对不确定的信息标注置信度
- 提供多角度的分析，帮助用户全面理解问题
- 如果信息不足以回答问题，诚实说明并建议进一步的研究方向
- 引用时使用 [来源: 文档名称] 格式标注

## 输出格式
- 对于简单问题，直接给出答案并附上来源
- 对于复杂问题，使用结构化格式：
  1. 摘要：简要回答
  2. 详细分析：分点阐述
  3. 来源引用：列出所有参考的文档
  4. 延伸阅读：建议相关主题''',
  );

  /// Writing Assistant - specialized in content creation and editing.
  ///
  /// Best for:
  /// - Writing and editing documents
  /// - Improving text quality
  /// - Translation
  /// - Generating outlines and structures
  ///
  /// Requirements: 7.6
  static const AgentConfig writingAssistant = AgentConfig(
    id: 'writing_assistant',
    name: 'Writing Assistant',
    description: '帮助你写作、润色、翻译和改进文本，支持多种写作风格',
    type: AgentType.writing,
    icon: '✍️',
    displayOrder: 2,
    temperature: 0.7,
    maxTokens: 8192,
    requiresRagContext: true,
    canUseDeepSearch: false,
    enabledTools: [
      'vector_search',
      'document_operation',
      'summarize',
      'translate',
    ],
    systemPrompt: '''你是一个专业的写作助手，擅长内容创作、文本润色和翻译。

## 核心能力
1. **内容创作**: 根据用户需求和知识库内容辅助写作
2. **文本润色**: 改进文本的表达、结构和流畅度
3. **多语言翻译**: 支持中英日韩法德等多种语言的翻译
4. **结构优化**: 帮助组织文章结构，生成大纲

## 写作风格适配
- 学术风格：严谨、客观、引用规范
- 商务风格：专业、简洁、重点突出
- 创意风格：生动、有趣、富有表现力
- 技术风格：准确、清晰、逻辑性强

## 工作原则
- 保持用户的写作风格和语气，除非明确要求改变
- 提供具体的改进建议，而不是笼统的评价
- 尊重原文的核心意思，改进时不改变原意
- 翻译时注重语言的自然流畅，而非逐字翻译
- 可以参考知识库中的相关内容来丰富写作

## 常用功能
- /rewrite - 重写选中的文本
- /expand - 扩展内容
- /summarize - 生成摘要
- /translate - 翻译文本
- /outline - 生成大纲''',
  );

  /// Q&A Assistant - specialized in answering questions from knowledge base.
  ///
  /// Best for:
  /// - Answering questions based on stored knowledge
  /// - Finding specific information quickly
  /// - Explaining concepts from documents
  /// - Providing cited answers
  ///
  /// Requirements: 4.4
  static const AgentConfig qaAssistant = AgentConfig(
    id: 'qa_assistant',
    name: 'Q&A Assistant',
    description: '基于你的知识库回答问题，提供带来源引用的准确答案',
    type: AgentType.qa,
    icon: '💬',
    displayOrder: 3,
    temperature: 0.3,
    maxTokens: 4096,
    requiresRagContext: true,
    canUseDeepSearch: false,
    enabledTools: [
      'full_text_search',
      'vector_search',
    ],
    systemPrompt: '''你是一个知识问答助手，专门基于用户的知识库回答问题。

## 核心原则
1. **仅基于知识库**: 只使用知识库中的内容回答问题，不编造信息
2. **来源引用**: 每个回答都必须标注信息来源
3. **准确简洁**: 回答要准确、简洁、直接切中要点
4. **诚实透明**: 如果知识库中没有相关信息，明确告知用户

## 回答格式
对于每个问题，按以下格式回答：

**答案**: [简洁的回答]

**详细说明**: [如果需要，提供更多细节]

**来源**: 
- [文档名称1] - "相关引用片段"
- [文档名称2] - "相关引用片段"

## 特殊情况处理
- 如果找不到相关信息：明确说明"在当前知识库中未找到相关信息"
- 如果信息不完整：说明已找到的内容，并指出缺失的部分
- 如果有多个相关文档：综合多个来源给出完整答案
- 如果信息可能过时：提醒用户检查信息的时效性

## 交互建议
- 建议用户查看原始文档获取更多细节
- 如果问题模糊，请求用户澄清
- 提供相关问题的建议，帮助用户深入探索''',
  );

  /// Code Assistant - specialized in code-related tasks.
  ///
  /// Best for:
  /// - Finding code examples in knowledge base
  /// - Explaining code functionality
  /// - Code review suggestions
  /// - Technical documentation queries
  static const AgentConfig codeAssistant = AgentConfig(
    id: 'code_assistant',
    name: 'Code Assistant',
    description: '帮助你查找代码示例、理解代码逻辑和技术文档',
    type: AgentType.code,
    icon: '💻',
    displayOrder: 4,
    temperature: 0.3,
    maxTokens: 8192,
    requiresRagContext: true,
    canUseDeepSearch: false,
    enabledTools: [
      'full_text_search',
      'vector_search',
      'document_operation',
    ],
    systemPrompt: '''你是一个代码助手，擅长在知识库中查找代码示例和技术文档。

## 核心能力
1. **代码检索**: 在知识库中查找相关的代码示例和实现
2. **代码解释**: 解释代码的功能、逻辑和设计思路
3. **技术文档**: 帮助理解和查找技术文档
4. **最佳实践**: 基于知识库中的内容提供建议

## 工作原则
- 提供可运行的代码示例，注明来源
- 解释代码的关键部分和设计决策
- 指出潜在的问题和改进点
- 引用相关的文档和资源

## 代码展示格式
```language
// 来源: [文档名称]
代码内容
```

## 注意事项
- 代码示例来自知识库，可能需要根据具体情况调整
- 如果知识库中没有相关代码，会明确说明
- 建议查看原始文档获取完整上下文''',
  );

  /// Gets all preset configurations.
  static List<AgentConfig> get all => [
        researchAssistant,
        writingAssistant,
        qaAssistant,
        codeAssistant,
      ];

  /// Gets presets sorted by display order.
  static List<AgentConfig> get allSorted {
    final list = List<AgentConfig>.from(all);
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  }

  /// Gets a preset by ID.
  static AgentConfig? getById(String id) {
    return all.cast<AgentConfig?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
  }

  /// Gets a preset by name.
  static AgentConfig? getByName(String name) {
    return all.cast<AgentConfig?>().firstWhere(
          (c) => c?.name == name,
          orElse: () => null,
        );
  }

  /// Gets presets by type.
  static List<AgentConfig> getByType(AgentType type) {
    return all.where((c) => c.type == type).toList();
  }

  /// Gets the default agent (Q&A Assistant).
  static AgentConfig get defaultAgent => qaAssistant;
}

/// Service for managing agent configurations.
///
/// Provides methods to get, create, and manage agent configurations,
/// including both presets and custom user-defined agents.
class AgentConfigService {
  /// Custom agent configurations created by the user.
  final List<AgentConfig> _customAgents = [];

  /// Creates a new [AgentConfigService].
  AgentConfigService();

  /// Gets all available agent configurations (presets + custom).
  List<AgentConfig> getAllAgents() {
    final agents = <AgentConfig>[...AgentPresets.all, ..._customAgents];
    agents.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return agents;
  }

  /// Gets an agent by ID.
  AgentConfig? getAgentById(String id) {
    // Check presets first
    final preset = AgentPresets.getById(id);
    if (preset != null) return preset;

    // Check custom agents
    return _customAgents.cast<AgentConfig?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
  }

  /// Adds a custom agent configuration.
  void addCustomAgent(AgentConfig config) {
    if (config.type != AgentType.custom) {
      throw ArgumentError('Only custom agents can be added');
    }
    _customAgents.add(config);
  }

  /// Removes a custom agent configuration.
  bool removeCustomAgent(String id) {
    final initialLength = _customAgents.length;
    _customAgents.removeWhere((c) => c.id == id);
    return _customAgents.length < initialLength;
  }

  /// Updates a custom agent configuration.
  bool updateCustomAgent(AgentConfig config) {
    final index = _customAgents.indexWhere((c) => c.id == config.id);
    if (index == -1) return false;
    _customAgents[index] = config;
    return true;
  }

  /// Gets agents that support RAG context.
  List<AgentConfig> getRagAgents() {
    return getAllAgents().where((c) => c.requiresRagContext).toList();
  }

  /// Gets agents that support deep search.
  List<AgentConfig> getDeepSearchAgents() {
    return getAllAgents().where((c) => c.canUseDeepSearch).toList();
  }

  /// Creates a custom agent from a preset with modifications.
  AgentConfig createFromPreset(
    AgentConfig preset, {
    required String id,
    required String name,
    String? description,
    List<String>? enabledTools,
    String? systemPrompt,
  }) {
    return preset.copyWith(
      id: id,
      name: name,
      type: AgentType.custom,
      description: description,
      enabledTools: enabledTools,
      systemPrompt: systemPrompt,
    );
  }
}

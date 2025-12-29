/// Agent Orchestrator for the AI Agent system
///
/// This file implements the core orchestration logic for the AI Agent,
/// including task planning, tool selection, execution, and result aggregation.
/// Requirements: 7.7, 7.9, 7.10
library;

import 'dart:async';
import 'dart:convert';

import 'package:ai_packages_core/ai_packages_core.dart';

import '../tools/tool_registry.dart';
import '../tools/tool_result.dart';
import '../../data/models/ai_model.dart';
import 'agent_config.dart';
import 'agent_request.dart';
import 'agent_response.dart';
import 'task_plan.dart';

/// Agent Orchestrator - coordinates AI agent operations
///
/// The orchestrator is responsible for:
/// 1. Analyzing user requests and planning tasks
/// 2. Selecting and executing appropriate tools
/// 3. Aggregating results and generating citations
/// 4. Streaming responses back to the user
///
/// Requirements: 7.7
class AgentOrchestrator {
  final ToolRegistry _toolRegistry;
  final AgentConfig _config;

  /// Creates a new [AgentOrchestrator].
  ///
  /// [toolRegistry] - Registry of available tools.
  /// [config] - Agent configuration for customization.
  AgentOrchestrator({
    required ToolRegistry toolRegistry,
    required AgentConfig config,
  })  : _toolRegistry = toolRegistry,
        _config = config;

  /// Creates an [AgentOrchestrator] with default tools and Q&A assistant config.
  factory AgentOrchestrator.withDefaults() {
    final registry = ToolRegistry();
    // Tools will be registered by the caller or through dependency injection
    return AgentOrchestrator(
      toolRegistry: registry,
      config: AgentPresets.defaultAgent,
    );
  }

  /// Creates an [AgentOrchestrator] for a specific preset agent.
  factory AgentOrchestrator.forPreset(
    AgentType type, {
    required ToolRegistry toolRegistry,
  }) {
    final presets = AgentPresets.getByType(type);
    if (presets.isEmpty) {
      throw ArgumentError('No preset found for type: $type');
    }
    return AgentOrchestrator(
      toolRegistry: toolRegistry,
      config: presets.first,
    );
  }

  /// Gets the tool registry.
  ToolRegistry get toolRegistry => _toolRegistry;

  /// Gets the current agent configuration.
  AgentConfig get config => _config;

  /// Processes a user request and returns a stream of responses.
  ///
  /// This is the main entry point for agent interactions. It:
  /// 1. Plans tasks based on the user's query
  /// 2. Executes tools as needed
  /// 3. Aggregates results with citations
  /// 4. Streams the final response
  ///
  /// [request] - The user's request including query and scope.
  ///
  /// Requirements: 7.7, 7.9
  Stream<AgentResponse> processRequest(AgentRequest request) async* {
    try {
      // 1. Plan tasks based on user request
      yield AgentResponse.status('正在分析请求...');

      final plan = await _planTasks(request);
      yield AgentResponse.planning(plan);

      // 2. Execute planned tasks
      if (plan.tasks.isNotEmpty) {
        yield AgentResponse.status('正在执行任务...');

        for (final task in plan.tasks) {
          yield AgentResponse.toolExecuting(task.toolName);

          final tool = _toolRegistry.getTool(task.toolName);
          if (tool == null) {
            yield AgentResponse.error('工具未找到: ${task.toolName}');
            continue;
          }

          try {
            final result = await tool.execute(task.parameters);
            plan.addResult(task.id, result);
            yield AgentResponse.toolResult(task.toolName, result);
          } catch (e) {
            final errorResult = ToolResult.failure('工具执行失败: $e');
            plan.addResult(task.id, errorResult);
            yield AgentResponse.toolResult(task.toolName, errorResult);
          }
        }
      }

      // 3. Generate final response with citations
      yield AgentResponse.status('正在生成回答...');
      yield* _generateFinalResponse(request, plan);
    } catch (e) {
      yield AgentResponse.error('处理请求时发生错误: $e');
    }
  }

  /// Plans tasks based on the user request.
  ///
  /// Uses the LLM to analyze the user's query and determine which
  /// tools to use and in what order.
  ///
  /// [request] - The user's request.
  ///
  /// Returns a [TaskPlan] containing the planned tasks.
  ///
  /// Requirements: 7.7
  Future<TaskPlan> _planTasks(AgentRequest request) async {
    // Check if we have a model configured
    if (GlobalModel.model == null) {
      // No model available, create a simple plan based on query analysis
      return _createSimplePlan(request);
    }

    try {
      // Build the planning prompt
      final systemPrompt = _buildPlanningPrompt();
      final userPrompt = _buildUserPrompt(request);

      // Call LLM for task planning
      final messages = [
        ChatMessage<String>(
          role: 'system',
          content: systemPrompt,
          createAt: DateTime.now().millisecondsSinceEpoch,
        ),
        ChatMessage<String>(
          role: 'user',
          content: userPrompt,
          createAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      final response = await GlobalModel.model!.chat(messages);

      // Parse the LLM response into a task plan
      return _parsePlanFromResponse(response, request);
    } catch (e) {
      // Fallback to simple planning if LLM fails
      return _createSimplePlan(request);
    }
  }

  /// Builds the system prompt for task planning.
  String _buildPlanningPrompt() {
    final toolDescriptions = _config.enabledTools.isNotEmpty
        ? _toolRegistry.getToolDescriptionsFor(_config.enabledTools)
        : _toolRegistry.getToolDescriptions();

    final basePrompt = _config.systemPrompt;

    return '''
$basePrompt

可用的工具有：
$toolDescriptions

请分析用户请求，返回需要执行的工具调用。
返回格式为 JSON 数组，每个元素包含：
- tool: 工具名称
- parameters: 工具参数对象

示例：
[
  {"tool": "vector_search", "parameters": {"query": "用户的问题", "limit": 5}},
  {"tool": "full_text_search", "parameters": {"query": "关键词"}}
]

如果不需要使用任何工具，返回空数组 []。
只返回 JSON，不要有其他内容。
''';
  }

  /// Builds the user prompt for task planning.
  String _buildUserPrompt(AgentRequest request) {
    final scopeInfo = request.workspaceIds.isNotEmpty
        ? '搜索范围: ${request.workspaceIds.join(", ")}'
        : '搜索范围: 当前工作空间';

    return '''
用户问题: ${request.query}
$scopeInfo

请规划需要执行的工具调用。
''';
  }

  /// Parses the LLM response into a TaskPlan.
  TaskPlan _parsePlanFromResponse(String response, AgentRequest request) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) {
        return _createSimplePlan(request);
      }

      final jsonStr = jsonMatch.group(0)!;
      final List<dynamic> toolCalls = json.decode(jsonStr);

      final tasks = <PlannedTask>[];
      for (int i = 0; i < toolCalls.length; i++) {
        final call = toolCalls[i] as Map<String, dynamic>;
        final toolName = call['tool'] as String?;
        final parameters = call['parameters'] as Map<String, dynamic>? ?? {};

        if (toolName != null && _toolRegistry.hasTool(toolName)) {
          // Inject workspace IDs if not specified
          if (request.workspaceIds.isNotEmpty &&
              !parameters.containsKey('workspace_ids')) {
            parameters['workspace_ids'] = request.workspaceIds;
          }

          tasks.add(PlannedTask(
            id: 'task_$i',
            toolName: toolName,
            parameters: parameters,
          ));
        }
      }

      return TaskPlan(
        query: request.query,
        tasks: tasks,
      );
    } catch (e) {
      return _createSimplePlan(request);
    }
  }

  /// Creates a simple plan based on query analysis without LLM.
  ///
  /// This is used as a fallback when the LLM is not available or fails.
  TaskPlan _createSimplePlan(AgentRequest request) {
    final tasks = <PlannedTask>[];
    final query = request.query.toLowerCase();

    // Determine which tools to use based on query patterns
    bool needsSearch = true;

    // Check for translation requests
    if (query.contains('翻译') ||
        query.contains('translate') ||
        query.contains('转换成')) {
      if (_toolRegistry.hasTool('translate')) {
        tasks.add(PlannedTask(
          id: 'task_translate',
          toolName: 'translate',
          parameters: {
            'text': request.query,
            'target_language': _detectTargetLanguage(query),
          },
        ));
        needsSearch = false;
      }
    }

    // Check for summarization requests
    if (query.contains('总结') ||
        query.contains('摘要') ||
        query.contains('summarize')) {
      if (_toolRegistry.hasTool('summarize')) {
        tasks.add(PlannedTask(
          id: 'task_summarize',
          toolName: 'summarize',
          parameters: {
            'text': request.query,
            'style': 'brief',
          },
        ));
      }
    }

    // Default to search if no specific action detected
    if (needsSearch) {
      // Use vector search for question-like queries
      if (_isQuestionQuery(query) && _toolRegistry.hasTool('vector_search')) {
        tasks.add(PlannedTask(
          id: 'task_vector_search',
          toolName: 'vector_search',
          parameters: {
            'query': request.query,
            'workspace_ids': request.workspaceIds,
            'limit': 5,
          },
        ));
      }

      // Also use full-text search for keyword matching
      if (_toolRegistry.hasTool('full_text_search')) {
        tasks.add(PlannedTask(
          id: 'task_fulltext_search',
          toolName: 'full_text_search',
          parameters: {
            'query': request.query,
            'workspace_ids': request.workspaceIds,
            'limit': 5,
          },
        ));
      }
    }

    return TaskPlan(
      query: request.query,
      tasks: tasks,
    );
  }

  /// Detects if the query is a question.
  bool _isQuestionQuery(String query) {
    final questionPatterns = [
      '什么',
      '怎么',
      '如何',
      '为什么',
      '哪',
      '谁',
      '何时',
      '多少',
      'what',
      'how',
      'why',
      'where',
      'when',
      'who',
      'which',
      '?',
      '？',
    ];
    return questionPatterns.any((p) => query.contains(p));
  }

  /// Detects target language from query.
  String _detectTargetLanguage(String query) {
    if (query.contains('英文') || query.contains('english')) return 'en';
    if (query.contains('中文') || query.contains('chinese')) return 'zh';
    if (query.contains('日文') || query.contains('japanese')) return 'ja';
    if (query.contains('韩文') || query.contains('korean')) return 'ko';
    if (query.contains('法文') || query.contains('french')) return 'fr';
    if (query.contains('德文') || query.contains('german')) return 'de';
    return 'en'; // Default to English
  }

  /// Generates the final response based on executed tasks.
  ///
  /// Aggregates results from all tools, generates citations,
  /// and streams the response.
  ///
  /// Requirements: 7.9, 7.10
  Stream<AgentResponse> _generateFinalResponse(
    AgentRequest request,
    TaskPlan plan,
  ) async* {
    // Collect all results and citations
    final context = plan.getResultsContext();
    final citations = plan.getAllCitations();

    // If no model available, return raw results
    if (GlobalModel.model == null) {
      yield AgentResponse.streaming(context);
      if (citations.isNotEmpty) {
        yield AgentResponse.citations(citations);
      }
      yield AgentResponse.done();
      return;
    }

    try {
      // Build the response generation prompt
      final systemPrompt = '''
基于以下检索到的信息回答用户的问题。
如果信息不足以回答问题，请诚实地说明。
回答要准确、简洁、有帮助。

检索到的信息：
$context
''';

      final messages = [
        ChatMessage<String>(
          role: 'system',
          content: systemPrompt,
          createAt: DateTime.now().millisecondsSinceEpoch,
        ),
        ChatMessage<String>(
          role: 'user',
          content: request.query,
          createAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      // Stream the response
      await for (final chunk in GlobalModel.model!.streamChat(messages)) {
        yield AgentResponse.streaming(chunk);
      }

      // Append citations
      if (citations.isNotEmpty) {
        yield AgentResponse.citations(citations);
      }

      yield AgentResponse.done();
    } catch (e) {
      // Fallback to raw results if streaming fails
      yield AgentResponse.streaming(context);
      if (citations.isNotEmpty) {
        yield AgentResponse.citations(citations);
      }
      yield AgentResponse.done();
    }
  }
}

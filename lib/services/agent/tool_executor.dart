/// Tool executor for the AI Agent system
///
/// This file implements the tool execution logic, handling
/// tool selection, parameter validation, and execution.
/// Requirements: 7.7
library;

import 'dart:async';

import '../tools/tool_interface.dart';
import '../tools/tool_registry.dart';
import '../tools/tool_result.dart';
import 'task_plan.dart';

/// Callback for tool execution events.
typedef ToolExecutionCallback = void Function(ToolExecutionEvent event);

/// Event types for tool execution.
enum ToolExecutionEventType {
  /// Tool execution started.
  started,

  /// Tool execution completed successfully.
  completed,

  /// Tool execution failed.
  failed,

  /// Tool not found.
  notFound,
}

/// Event emitted during tool execution.
class ToolExecutionEvent {
  /// The type of event.
  final ToolExecutionEventType type;

  /// The task being executed.
  final PlannedTask task;

  /// The result (only for completed/failed events).
  final ToolResult? result;

  /// Error message (only for failed events).
  final String? error;

  /// Creates a new [ToolExecutionEvent].
  const ToolExecutionEvent({
    required this.type,
    required this.task,
    this.result,
    this.error,
  });

  /// Creates a started event.
  factory ToolExecutionEvent.started(PlannedTask task) {
    return ToolExecutionEvent(
      type: ToolExecutionEventType.started,
      task: task,
    );
  }

  /// Creates a completed event.
  factory ToolExecutionEvent.completed(PlannedTask task, ToolResult result) {
    return ToolExecutionEvent(
      type: ToolExecutionEventType.completed,
      task: task,
      result: result,
    );
  }

  /// Creates a failed event.
  factory ToolExecutionEvent.failed(PlannedTask task, String error) {
    return ToolExecutionEvent(
      type: ToolExecutionEventType.failed,
      task: task,
      error: error,
      result: ToolResult.failure(error),
    );
  }

  /// Creates a not found event.
  factory ToolExecutionEvent.notFound(PlannedTask task) {
    return ToolExecutionEvent(
      type: ToolExecutionEventType.notFound,
      task: task,
      error: 'Tool not found: ${task.toolName}',
      result: ToolResult.failure('Tool not found: ${task.toolName}'),
    );
  }
}

/// Executes tools for the AI Agent system.
///
/// The [ToolExecutor] handles:
/// - Tool lookup from the registry
/// - Parameter validation
/// - Sequential or parallel execution
/// - Error handling and recovery
///
/// Requirements: 7.7
class ToolExecutor {
  final ToolRegistry _registry;

  /// Creates a new [ToolExecutor].
  ToolExecutor(this._registry);

  /// Gets the tool registry.
  ToolRegistry get registry => _registry;

  /// Executes a single task.
  ///
  /// [task] - The task to execute.
  /// [onEvent] - Optional callback for execution events.
  ///
  /// Returns the [ToolResult] from execution.
  Future<ToolResult> executeTask(
    PlannedTask task, {
    ToolExecutionCallback? onEvent,
  }) async {
    // Look up the tool
    final tool = _registry.getTool(task.toolName);
    if (tool == null) {
      final event = ToolExecutionEvent.notFound(task);
      onEvent?.call(event);
      return event.result!;
    }

    // Notify start
    onEvent?.call(ToolExecutionEvent.started(task));

    try {
      // Validate parameters
      final validationError = _validateParameters(tool, task.parameters);
      if (validationError != null) {
        final event = ToolExecutionEvent.failed(task, validationError);
        onEvent?.call(event);
        return event.result!;
      }

      // Execute the tool
      final result = await tool.execute(task.parameters);

      // Notify completion
      onEvent?.call(ToolExecutionEvent.completed(task, result));
      return result;
    } catch (e) {
      final event = ToolExecutionEvent.failed(task, e.toString());
      onEvent?.call(event);
      return event.result!;
    }
  }

  /// Executes multiple tasks sequentially.
  ///
  /// [tasks] - The tasks to execute in order.
  /// [onEvent] - Optional callback for execution events.
  ///
  /// Returns a map of task ID to [ToolResult].
  Future<Map<String, ToolResult>> executeTasksSequentially(
    List<PlannedTask> tasks, {
    ToolExecutionCallback? onEvent,
  }) async {
    final results = <String, ToolResult>{};

    for (final task in tasks) {
      final result = await executeTask(task, onEvent: onEvent);
      results[task.id] = result;
    }

    return results;
  }

  /// Executes multiple tasks in parallel.
  ///
  /// [tasks] - The tasks to execute concurrently.
  /// [onEvent] - Optional callback for execution events.
  /// [maxConcurrency] - Maximum number of concurrent executions.
  ///
  /// Returns a map of task ID to [ToolResult].
  Future<Map<String, ToolResult>> executeTasksParallel(
    List<PlannedTask> tasks, {
    ToolExecutionCallback? onEvent,
    int maxConcurrency = 3,
  }) async {
    final results = <String, ToolResult>{};

    // Execute in batches to limit concurrency
    for (int i = 0; i < tasks.length; i += maxConcurrency) {
      final batch = tasks.skip(i).take(maxConcurrency).toList();
      final batchFutures = batch.map((task) async {
        final result = await executeTask(task, onEvent: onEvent);
        return MapEntry(task.id, result);
      });

      final batchResults = await Future.wait(batchFutures);
      for (final entry in batchResults) {
        results[entry.key] = entry.value;
      }
    }

    return results;
  }

  /// Executes a task plan.
  ///
  /// [plan] - The task plan to execute.
  /// [onEvent] - Optional callback for execution events.
  /// [parallel] - Whether to execute tasks in parallel.
  ///
  /// Updates the plan with results and returns it.
  Future<TaskPlan> executePlan(
    TaskPlan plan, {
    ToolExecutionCallback? onEvent,
    bool parallel = false,
  }) async {
    final results = parallel
        ? await executeTasksParallel(plan.tasks, onEvent: onEvent)
        : await executeTasksSequentially(plan.tasks, onEvent: onEvent);

    for (final entry in results.entries) {
      plan.addResult(entry.key, entry.value);
    }

    return plan;
  }

  /// Validates tool parameters against the schema.
  ///
  /// Returns an error message if validation fails, null otherwise.
  String? _validateParameters(ITool tool, Map<String, dynamic> parameters) {
    final schema = tool.parametersSchema;

    // Check required parameters
    final required = schema['required'] as List<dynamic>?;
    if (required != null) {
      for (final param in required) {
        if (!parameters.containsKey(param)) {
          return 'Missing required parameter: $param';
        }
      }
    }

    // Basic type validation
    final properties = schema['properties'] as Map<String, dynamic>?;
    if (properties != null) {
      for (final entry in parameters.entries) {
        final propSchema = properties[entry.key] as Map<String, dynamic>?;
        if (propSchema == null) continue;

        final expectedType = propSchema['type'] as String?;
        if (expectedType != null) {
          final error = _validateType(entry.key, entry.value, expectedType);
          if (error != null) return error;
        }
      }
    }

    return null;
  }

  /// Validates a value against an expected type.
  String? _validateType(String name, dynamic value, String expectedType) {
    switch (expectedType) {
      case 'string':
        if (value is! String) {
          return 'Parameter $name must be a string';
        }
        break;
      case 'integer':
        if (value is! int) {
          return 'Parameter $name must be an integer';
        }
        break;
      case 'number':
        if (value is! num) {
          return 'Parameter $name must be a number';
        }
        break;
      case 'boolean':
        if (value is! bool) {
          return 'Parameter $name must be a boolean';
        }
        break;
      case 'array':
        if (value is! List) {
          return 'Parameter $name must be an array';
        }
        break;
      case 'object':
        if (value is! Map) {
          return 'Parameter $name must be an object';
        }
        break;
    }
    return null;
  }

  /// Selects the best tool for a given intent.
  ///
  /// [intent] - The user's intent or query type.
  /// [availableTools] - Optional list of tool names to consider.
  ///
  /// Returns the name of the best matching tool, or null if none found.
  String? selectToolForIntent(String intent, {List<String>? availableTools}) {
    final tools = availableTools ?? _registry.toolNames;
    final intentLower = intent.toLowerCase();

    // Search-related intents
    if (_matchesAny(intentLower, ['搜索', 'search', '查找', 'find', '查询'])) {
      if (tools.contains('vector_search')) return 'vector_search';
      if (tools.contains('full_text_search')) return 'full_text_search';
    }

    // Question-answering intents
    if (_matchesAny(
        intentLower, ['什么', '怎么', '为什么', 'what', 'how', 'why', '?', '？'])) {
      if (tools.contains('vector_search')) return 'vector_search';
    }

    // Translation intents
    if (_matchesAny(intentLower, ['翻译', 'translate', '转换'])) {
      if (tools.contains('translate')) return 'translate';
    }

    // Summarization intents
    if (_matchesAny(intentLower, ['总结', '摘要', 'summarize', 'summary'])) {
      if (tools.contains('summarize')) return 'summarize';
    }

    // Document intents
    if (_matchesAny(
        intentLower, ['文档', '创建', '保存', 'document', 'create', 'save'])) {
      if (tools.contains('document_operation')) return 'document_operation';
    }

    // Web search intents
    if (_matchesAny(
        intentLower, ['网上', '网页', '互联网', 'web', 'internet', 'online'])) {
      if (tools.contains('deep_search')) return 'deep_search';
    }

    // Default to vector search for general queries
    if (tools.contains('vector_search')) return 'vector_search';
    if (tools.contains('full_text_search')) return 'full_text_search';

    return tools.isNotEmpty ? tools.first : null;
  }

  /// Checks if text matches any of the patterns.
  bool _matchesAny(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }
}

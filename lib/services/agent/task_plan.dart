/// Task planning models for the AI Agent system
///
/// This file defines the task plan structure used by the agent
/// orchestrator to coordinate tool execution.
/// Requirements: 7.7
library;

import '../tools/tool_result.dart';

/// Represents a planned task to be executed by the agent.
class PlannedTask {
  /// Unique identifier for this task.
  final String id;

  /// Name of the tool to execute.
  final String toolName;

  /// Parameters to pass to the tool.
  final Map<String, dynamic> parameters;

  /// Optional description of what this task does.
  final String? description;

  /// Creates a new [PlannedTask].
  const PlannedTask({
    required this.id,
    required this.toolName,
    required this.parameters,
    this.description,
  });

  /// Creates a copy with modified fields.
  PlannedTask copyWith({
    String? id,
    String? toolName,
    Map<String, dynamic>? parameters,
    String? description,
  }) {
    return PlannedTask(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      parameters: parameters ?? this.parameters,
      description: description ?? this.description,
    );
  }

  /// Converts to JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolName': toolName,
      'parameters': parameters,
      if (description != null) 'description': description,
    };
  }

  /// Creates from JSON map.
  factory PlannedTask.fromJson(Map<String, dynamic> json) {
    return PlannedTask(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      description: json['description'] as String?,
    );
  }

  @override
  String toString() {
    return 'PlannedTask(id: $id, tool: $toolName)';
  }
}

/// Represents a complete task plan with results.
///
/// The task plan contains the original query, planned tasks,
/// and results from executed tasks.
///
/// Requirements: 7.7
class TaskPlan {
  /// The original user query.
  final String query;

  /// List of planned tasks to execute.
  final List<PlannedTask> tasks;

  /// Results from executed tasks, keyed by task ID.
  final Map<String, ToolResult> _results = {};

  /// Creates a new [TaskPlan].
  TaskPlan({
    required this.query,
    required this.tasks,
  });

  /// Creates an empty task plan.
  factory TaskPlan.empty(String query) {
    return TaskPlan(query: query, tasks: []);
  }

  /// Whether the plan has any tasks.
  bool get hasTasks => tasks.isNotEmpty;

  /// Whether all tasks have been executed.
  bool get isComplete => tasks.every((t) => _results.containsKey(t.id));

  /// Gets the number of completed tasks.
  int get completedCount => _results.length;

  /// Gets the total number of tasks.
  int get totalCount => tasks.length;

  /// Adds a result for a task.
  void addResult(String taskId, ToolResult result) {
    _results[taskId] = result;
  }

  /// Gets the result for a task.
  ToolResult? getResult(String taskId) => _results[taskId];

  /// Gets all results.
  Map<String, ToolResult> get results => Map.unmodifiable(_results);

  /// Gets all successful results.
  List<ToolResult> get successfulResults =>
      _results.values.where((r) => r.success).toList();

  /// Gets all failed results.
  List<ToolResult> get failedResults =>
      _results.values.where((r) => !r.success).toList();

  /// Aggregates context from all successful results.
  ///
  /// This combines the data from all tool results into a single
  /// context string that can be used for response generation.
  ///
  /// Requirements: 7.10
  String getResultsContext() {
    final buffer = StringBuffer();

    for (final task in tasks) {
      final result = _results[task.id];
      if (result == null || !result.success) continue;

      buffer.writeln('--- ${task.toolName} 结果 ---');

      if (result.data != null) {
        if (result.data is Map) {
          final data = result.data as Map<String, dynamic>;

          // Handle search results specially
          if (data.containsKey('results')) {
            final results = data['results'] as List;
            buffer.writeln('找到 ${results.length} 条结果:');

            for (final item in results) {
              if (item is Map) {
                final title = item['document_title'] ?? item['title'] ?? '未知';
                final snippet = item['snippet'] ?? '';
                buffer.writeln('\n【$title】');
                buffer.writeln(snippet);
              }
            }
          } else {
            // Generic map data
            buffer.writeln(data.toString());
          }
        } else if (result.data is String) {
          buffer.writeln(result.data);
        } else {
          buffer.writeln(result.data.toString());
        }
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// Collects all citations from successful results.
  ///
  /// Requirements: 7.10
  List<SourceCitation> getAllCitations() {
    final citations = <SourceCitation>[];

    for (final result in _results.values) {
      if (result.success && result.citations != null) {
        citations.addAll(result.citations!);
      }
    }

    // Remove duplicates based on document ID and snippet
    final seen = <String>{};
    return citations.where((c) {
      final key = '${c.documentId}:${c.snippet.hashCode}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  /// Converts to JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'results': _results.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  @override
  String toString() {
    return 'TaskPlan(query: $query, tasks: ${tasks.length}, completed: ${_results.length})';
  }
}

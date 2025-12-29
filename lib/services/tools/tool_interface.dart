/// Tool interface for the AI Agent system
///
/// This file defines the base interface that all tools must implement
/// to be usable by the Agent Orchestrator.
library;

import 'tool_result.dart';

/// Base interface for all tools in the AI Agent system.
///
/// Tools are the building blocks of the Agent system, providing
/// specific capabilities that the AI can use to accomplish tasks.
/// Each tool has a name, description, parameter schema, and an
/// execute method.
///
/// Example implementation:
/// ```dart
/// class MyTool implements ITool {
///   @override
///   String get name => 'my_tool';
///
///   @override
///   String get description => 'Does something useful';
///
///   @override
///   Map<String, dynamic> get parametersSchema => {
///     'type': 'object',
///     'properties': {
///       'input': {'type': 'string'},
///     },
///     'required': ['input'],
///   };
///
///   @override
///   Future<ToolResult> execute(Map<String, dynamic> parameters) async {
///     final input = parameters['input'] as String;
///     return ToolResult.success(data: 'Processed: $input');
///   }
/// }
/// ```
abstract class ITool {
  /// The unique name of the tool.
  ///
  /// This name is used by the LLM to identify and call the tool.
  /// Should be lowercase with underscores (snake_case).
  String get name;

  /// A description of what the tool does.
  ///
  /// This description is provided to the LLM to help it understand
  /// when and how to use the tool. Should be clear and comprehensive.
  String get description;

  /// The JSON Schema for the tool's parameters.
  ///
  /// This schema defines what parameters the tool accepts,
  /// their types, and which are required. The schema follows
  /// the JSON Schema specification.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'type': 'object',
  ///   'properties': {
  ///     'query': {
  ///       'type': 'string',
  ///       'description': 'The search query',
  ///     },
  ///     'limit': {
  ///       'type': 'integer',
  ///       'default': 10,
  ///       'description': 'Maximum number of results',
  ///     },
  ///   },
  ///   'required': ['query'],
  /// }
  /// ```
  Map<String, dynamic> get parametersSchema;

  /// Executes the tool with the given parameters.
  ///
  /// [parameters] - A map of parameter names to values, matching
  /// the schema defined in [parametersSchema].
  ///
  /// Returns a [ToolResult] containing the execution result,
  /// which may include data, error information, and source citations.
  Future<ToolResult> execute(Map<String, dynamic> parameters);
}

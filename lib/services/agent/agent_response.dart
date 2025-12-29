/// Agent response model
///
/// This file defines the response types returned by the agent orchestrator.
/// Requirements: 7.9, 7.10
library;

import '../tools/tool_result.dart';
import 'task_plan.dart';

/// The type of agent response.
enum AgentResponseType {
  /// Status update message.
  status,

  /// Task planning information.
  planning,

  /// Tool is being executed.
  toolExecuting,

  /// Tool execution result.
  toolResult,

  /// Streaming text chunk.
  streaming,

  /// Source citations.
  citations,

  /// Error message.
  error,

  /// Processing complete.
  done,
}

/// Represents a response from the AI Agent.
///
/// Responses are streamed during agent processing and can be
/// of various types including status updates, tool results,
/// streaming text, and citations.
///
/// Requirements: 7.9, 7.10
class AgentResponse {
  /// The type of this response.
  final AgentResponseType type;

  /// The response data (type depends on [type]).
  final dynamic data;

  /// Private constructor.
  const AgentResponse._(this.type, this.data);

  /// Creates a status update response.
  factory AgentResponse.status(String message) {
    return AgentResponse._(AgentResponseType.status, message);
  }

  /// Creates a planning response with the task plan.
  factory AgentResponse.planning(TaskPlan plan) {
    return AgentResponse._(AgentResponseType.planning, plan);
  }

  /// Creates a tool executing response.
  factory AgentResponse.toolExecuting(String toolName) {
    return AgentResponse._(AgentResponseType.toolExecuting, toolName);
  }

  /// Creates a tool result response.
  factory AgentResponse.toolResult(String toolName, ToolResult result) {
    return AgentResponse._(AgentResponseType.toolResult, {
      'tool': toolName,
      'result': result,
    });
  }

  /// Creates a streaming text response.
  factory AgentResponse.streaming(String chunk) {
    return AgentResponse._(AgentResponseType.streaming, chunk);
  }

  /// Creates a citations response.
  factory AgentResponse.citations(List<SourceCitation> citations) {
    return AgentResponse._(AgentResponseType.citations, citations);
  }

  /// Creates an error response.
  factory AgentResponse.error(String message) {
    return AgentResponse._(AgentResponseType.error, message);
  }

  /// Creates a done response indicating processing is complete.
  factory AgentResponse.done() {
    return const AgentResponse._(AgentResponseType.done, null);
  }

  /// Whether this is a status response.
  bool get isStatus => type == AgentResponseType.status;

  /// Whether this is a planning response.
  bool get isPlanning => type == AgentResponseType.planning;

  /// Whether this is a tool executing response.
  bool get isToolExecuting => type == AgentResponseType.toolExecuting;

  /// Whether this is a tool result response.
  bool get isToolResult => type == AgentResponseType.toolResult;

  /// Whether this is a streaming response.
  bool get isStreaming => type == AgentResponseType.streaming;

  /// Whether this is a citations response.
  bool get isCitations => type == AgentResponseType.citations;

  /// Whether this is an error response.
  bool get isError => type == AgentResponseType.error;

  /// Whether this is a done response.
  bool get isDone => type == AgentResponseType.done;

  /// Gets the status message (only valid for status responses).
  String? get statusMessage => isStatus ? data as String : null;

  /// Gets the task plan (only valid for planning responses).
  TaskPlan? get taskPlan => isPlanning ? data as TaskPlan : null;

  /// Gets the tool name being executed (only valid for toolExecuting responses).
  String? get executingToolName => isToolExecuting ? data as String : null;

  /// Gets the tool result data (only valid for toolResult responses).
  Map<String, dynamic>? get toolResultData =>
      isToolResult ? data as Map<String, dynamic> : null;

  /// Gets the streaming chunk (only valid for streaming responses).
  String? get streamingChunk => isStreaming ? data as String : null;

  /// Gets the citations (only valid for citations responses).
  List<SourceCitation>? get citationsList =>
      isCitations ? data as List<SourceCitation> : null;

  /// Gets the error message (only valid for error responses).
  String? get errorMessage => isError ? data as String : null;

  @override
  String toString() {
    switch (type) {
      case AgentResponseType.status:
        return 'AgentResponse.status($data)';
      case AgentResponseType.planning:
        return 'AgentResponse.planning(${(data as TaskPlan).tasks.length} tasks)';
      case AgentResponseType.toolExecuting:
        return 'AgentResponse.toolExecuting($data)';
      case AgentResponseType.toolResult:
        return 'AgentResponse.toolResult(${(data as Map)['tool']})';
      case AgentResponseType.streaming:
        final chunk = data as String;
        return 'AgentResponse.streaming(${chunk.length} chars)';
      case AgentResponseType.citations:
        return 'AgentResponse.citations(${(data as List).length} citations)';
      case AgentResponseType.error:
        return 'AgentResponse.error($data)';
      case AgentResponseType.done:
        return 'AgentResponse.done()';
    }
  }
}

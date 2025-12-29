/// Agent request model
///
/// This file defines the request structure for agent interactions.
library;

/// Represents a request to the AI Agent.
///
/// Contains the user's query and optional scope configuration
/// for search and context retrieval.
class AgentRequest {
  /// The user's query or question.
  final String query;

  /// List of workspace IDs to search within.
  ///
  /// If empty, the agent will use the current workspace.
  /// If contains multiple IDs, cross-workspace search is enabled.
  final List<String> workspaceIds;

  /// Optional document ID for document-specific queries.
  final String? documentId;

  /// Optional conversation history for context.
  final List<AgentMessage>? conversationHistory;

  /// Additional context or instructions.
  final String? additionalContext;

  /// Creates a new [AgentRequest].
  const AgentRequest({
    required this.query,
    this.workspaceIds = const [],
    this.documentId,
    this.conversationHistory,
    this.additionalContext,
  });

  /// Creates a request for the current workspace.
  factory AgentRequest.currentWorkspace(String query) {
    return AgentRequest(query: query);
  }

  /// Creates a request for specific workspaces.
  factory AgentRequest.withWorkspaces(
    String query,
    List<String> workspaceIds,
  ) {
    return AgentRequest(
      query: query,
      workspaceIds: workspaceIds,
    );
  }

  /// Creates a request for all workspaces.
  factory AgentRequest.allWorkspaces(String query) {
    return AgentRequest(
      query: query,
      workspaceIds: const ['*'], // Special marker for all workspaces
    );
  }

  /// Whether this request searches all workspaces.
  bool get isAllWorkspaces =>
      workspaceIds.length == 1 && workspaceIds.first == '*';

  /// Whether this request is scoped to specific workspaces.
  bool get hasWorkspaceScope => workspaceIds.isNotEmpty && !isAllWorkspaces;

  /// Creates a copy with modified fields.
  AgentRequest copyWith({
    String? query,
    List<String>? workspaceIds,
    String? documentId,
    List<AgentMessage>? conversationHistory,
    String? additionalContext,
  }) {
    return AgentRequest(
      query: query ?? this.query,
      workspaceIds: workspaceIds ?? this.workspaceIds,
      documentId: documentId ?? this.documentId,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      additionalContext: additionalContext ?? this.additionalContext,
    );
  }

  @override
  String toString() {
    return 'AgentRequest(query: $query, workspaces: ${workspaceIds.length})';
  }
}

/// Represents a message in the conversation history.
class AgentMessage {
  /// The role of the message sender (user, assistant, system).
  final String role;

  /// The content of the message.
  final String content;

  /// Timestamp of the message.
  final DateTime timestamp;

  /// Creates a new [AgentMessage].
  const AgentMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Creates a user message.
  factory AgentMessage.user(String content) {
    return AgentMessage(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Creates an assistant message.
  factory AgentMessage.assistant(String content) {
    return AgentMessage(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a system message.
  factory AgentMessage.system(String content) {
    return AgentMessage(
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }
}

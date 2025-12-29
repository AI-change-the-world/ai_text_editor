import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../services/agent/agent.dart';
import '../../../services/tools/tool_registry.dart';
import '../../../services/tools/tool_result.dart';
import '../../workspace/notifiers/workspace_notifier.dart';

/// Search scope for AI assistant
/// Requirements: 7.3
enum SearchScope {
  /// Search only in current workspace
  currentWorkspace,

  /// Search in selected workspaces
  selectedWorkspaces,

  /// Search in all workspaces
  allWorkspaces,
}

/// Message with citations for display
class AIMessage {
  final String id;
  final String role;
  final String content;
  final List<SourceCitation> citations;
  final DateTime timestamp;
  final bool isStreaming;

  const AIMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    required this.timestamp,
    this.isStreaming = false,
  });

  AIMessage copyWith({
    String? id,
    String? role,
    String? content,
    List<SourceCitation>? citations,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return AIMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// State for AI Assistant Panel
/// Requirements: 7.1, 7.3, 7.7, 7.9, 7.11
class AIAssistantState {
  /// Current messages in the conversation
  final List<AIMessage> messages;

  /// Whether AI is currently generating a response
  final bool isGenerating;

  /// Current search scope
  final SearchScope searchScope;

  /// Selected workspace IDs for search (when scope is selectedWorkspaces)
  final List<String> selectedWorkspaceIds;

  /// Current agent configuration
  final AgentConfig currentAgent;

  /// Current chat history ID (for persistence)
  final String? chatHistoryId;

  /// Status message for UI feedback
  final String? statusMessage;

  /// Error message if any
  final String? error;

  /// Whether the panel is visible
  final bool isPanelVisible;

  const AIAssistantState({
    this.messages = const [],
    this.isGenerating = false,
    this.searchScope = SearchScope.currentWorkspace,
    this.selectedWorkspaceIds = const [],
    required this.currentAgent,
    this.chatHistoryId,
    this.statusMessage,
    this.error,
    this.isPanelVisible = false,
  });

  AIAssistantState copyWith({
    List<AIMessage>? messages,
    bool? isGenerating,
    SearchScope? searchScope,
    List<String>? selectedWorkspaceIds,
    AgentConfig? currentAgent,
    String? chatHistoryId,
    String? statusMessage,
    String? error,
    bool? isPanelVisible,
    bool clearError = false,
    bool clearStatus = false,
    bool clearChatHistory = false,
  }) {
    return AIAssistantState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      searchScope: searchScope ?? this.searchScope,
      selectedWorkspaceIds: selectedWorkspaceIds ?? this.selectedWorkspaceIds,
      currentAgent: currentAgent ?? this.currentAgent,
      chatHistoryId:
          clearChatHistory ? null : (chatHistoryId ?? this.chatHistoryId),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      error: clearError ? null : (error ?? this.error),
      isPanelVisible: isPanelVisible ?? this.isPanelVisible,
    );
  }
}

/// AI Assistant Notifier
/// Manages the state and logic for the global AI assistant panel
/// Requirements: 7.1, 7.3, 7.7, 7.9, 7.10, 7.11
class AIAssistantNotifier extends Notifier<AIAssistantState> {
  final Uuid _uuid = const Uuid();
  final ScrollController scrollController = ScrollController();
  StreamSubscription<AgentResponse>? _responseSubscription;

  @override
  AIAssistantState build() {
    ref.onDispose(() {
      _responseSubscription?.cancel();
      scrollController.dispose();
    });
    return AIAssistantState(
      currentAgent: AgentPresets.defaultAgent,
    );
  }

  /// Toggle panel visibility
  /// Requirements: 7.1
  void togglePanel() {
    state = state.copyWith(isPanelVisible: !state.isPanelVisible);
  }

  /// Show the panel
  /// Requirements: 7.1
  void showPanel() {
    state = state.copyWith(isPanelVisible: true);
  }

  /// Hide the panel
  void hidePanel() {
    state = state.copyWith(isPanelVisible: false);
  }

  /// Set search scope
  /// Requirements: 7.3
  void setSearchScope(SearchScope scope) {
    state = state.copyWith(searchScope: scope, clearError: true);
  }

  /// Set selected workspaces for search
  /// Requirements: 7.3
  void setSelectedWorkspaces(List<String> workspaceIds) {
    state = state.copyWith(
      selectedWorkspaceIds: workspaceIds,
      searchScope: SearchScope.selectedWorkspaces,
      clearError: true,
    );
  }

  /// Change current agent
  /// Requirements: 7.7
  void setAgent(AgentConfig agent) {
    state = state.copyWith(currentAgent: agent, clearError: true);
  }

  /// Send a message to the AI assistant
  /// Requirements: 7.7, 7.9
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isGenerating) return;

    // Add user message
    final userMessage = AIMessage(
      id: _uuid.v4(),
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
      clearError: true,
      clearStatus: true,
    );

    _scrollToBottom();

    // Create assistant message placeholder for streaming
    final assistantMessageId = _uuid.v4();
    final assistantMessage = AIMessage(
      id: assistantMessageId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMessage],
    );

    // Build request based on search scope
    final workspaceIds = _getWorkspaceIds();
    final request = AgentRequest(
      query: content.trim(),
      workspaceIds: workspaceIds,
      conversationHistory: _buildConversationHistory(),
    );

    // Process with agent orchestrator
    await _processWithAgent(request, assistantMessageId);
  }

  /// Get workspace IDs based on current search scope
  List<String> _getWorkspaceIds() {
    switch (state.searchScope) {
      case SearchScope.currentWorkspace:
        final currentWorkspace = ref.read(workspaceProvider).currentWorkspace;
        return currentWorkspace != null ? [currentWorkspace.uuid] : [];
      case SearchScope.selectedWorkspaces:
        return state.selectedWorkspaceIds;
      case SearchScope.allWorkspaces:
        return ['*']; // Special marker for all workspaces
    }
  }

  /// Build conversation history for context
  List<AgentMessage> _buildConversationHistory() {
    return state.messages
        .where((m) => !m.isStreaming)
        .map((m) => AgentMessage(
              role: m.role,
              content: m.content,
              timestamp: m.timestamp,
            ))
        .toList();
  }

  /// Process request with agent orchestrator
  /// Requirements: 7.9, 7.10
  Future<void> _processWithAgent(
    AgentRequest request,
    String assistantMessageId,
  ) async {
    final orchestrator = AgentOrchestrator(
      toolRegistry: ToolRegistry(),
      config: state.currentAgent,
    );

    final buffer = StringBuffer();
    final citations = <SourceCitation>[];

    try {
      await for (final response in orchestrator.processRequest(request)) {
        switch (response.type) {
          case AgentResponseType.status:
            state = state.copyWith(statusMessage: response.statusMessage);
            break;

          case AgentResponseType.streaming:
            buffer.write(response.streamingChunk ?? '');
            _updateAssistantMessage(
              assistantMessageId,
              buffer.toString(),
              citations,
              isStreaming: true,
            );
            _scrollToBottom();
            break;

          case AgentResponseType.citations:
            citations.addAll(response.citationsList ?? []);
            _updateAssistantMessage(
              assistantMessageId,
              buffer.toString(),
              citations,
              isStreaming: true,
            );
            break;

          case AgentResponseType.error:
            state = state.copyWith(
              error: response.errorMessage,
              isGenerating: false,
              clearStatus: true,
            );
            _updateAssistantMessage(
              assistantMessageId,
              buffer.isEmpty ? '抱歉，处理请求时发生错误。' : buffer.toString(),
              citations,
              isStreaming: false,
            );
            return;

          case AgentResponseType.done:
            _updateAssistantMessage(
              assistantMessageId,
              buffer.toString(),
              citations,
              isStreaming: false,
            );
            state = state.copyWith(
              isGenerating: false,
              clearStatus: true,
            );
            break;

          default:
            break;
        }
      }
    } catch (e) {
      state = state.copyWith(
        error: '处理请求时发生错误: $e',
        isGenerating: false,
        clearStatus: true,
      );
      _updateAssistantMessage(
        assistantMessageId,
        buffer.isEmpty ? '抱歉，处理请求时发生错误。' : buffer.toString(),
        citations,
        isStreaming: false,
      );
    }
  }

  /// Update assistant message during streaming
  void _updateAssistantMessage(
    String messageId,
    String content,
    List<SourceCitation> citations, {
    required bool isStreaming,
  }) {
    final messages = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          content: content,
          citations: citations,
          isStreaming: isStreaming,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(messages: messages);
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear conversation
  /// Requirements: 7.11
  void clearConversation() {
    state = state.copyWith(
      messages: [],
      clearChatHistory: true,
      clearError: true,
      clearStatus: true,
    );
  }

  /// Stop current generation
  void stopGeneration() {
    _responseSubscription?.cancel();
    _responseSubscription = null;

    // Mark the last streaming message as complete
    final messages = state.messages.map((m) {
      if (m.isStreaming) {
        return m.copyWith(isStreaming: false);
      }
      return m;
    }).toList();

    state = state.copyWith(
      messages: messages,
      isGenerating: false,
      clearStatus: true,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for AI Assistant state
final aiAssistantProvider =
    NotifierProvider<AIAssistantNotifier, AIAssistantState>(
  AIAssistantNotifier.new,
);

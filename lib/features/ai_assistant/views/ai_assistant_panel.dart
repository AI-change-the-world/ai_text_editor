import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';
import '../widgets/agent_selector.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../widgets/search_scope_selector.dart';

/// AI Assistant Panel - Global AI assistant overlay
/// Requirements: 7.1
class AIAssistantPanel extends ConsumerStatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  ConsumerState<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends ConsumerState<AIAssistantPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);

    if (!state.isPanelVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Backdrop - tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                ref.read(aiAssistantProvider.notifier).hidePanel();
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Panel
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.8,
              constraints: const BoxConstraints(
                maxWidth: 800,
                maxHeight: 700,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, state),
                  // Toolbar with scope and agent selectors
                  _buildToolbar(context, state),
                  // Divider
                  const Divider(height: 1),
                  // Message list
                  Expanded(
                    child: MessageList(
                      messages: state.messages,
                      scrollController: ref
                          .read(aiAssistantProvider.notifier)
                          .scrollController,
                      isGenerating: state.isGenerating,
                      statusMessage: state.statusMessage,
                    ),
                  ),
                  // Error message
                  if (state.error != null) _buildErrorBanner(context, state),
                  // Input area
                  const ChatInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AIAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assistant,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'AI 助手',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          // Clear conversation button
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '清空对话',
              onPressed: () {
                ref.read(aiAssistantProvider.notifier).clearConversation();
              },
            ),
          // Close button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: '关闭 (Esc)',
            onPressed: () {
              ref.read(aiAssistantProvider.notifier).hidePanel();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, AIAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Search scope selector
          const Expanded(child: SearchScopeSelector()),
          const SizedBox(width: 16),
          // Agent selector
          const AgentSelector(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, AIAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 16),
            onPressed: () {
              ref.read(aiAssistantProvider.notifier).clearError();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

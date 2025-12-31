import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';
import 'agent_selector.dart';
import 'chat_input.dart';
import 'message_list.dart';
import 'search_scope_selector.dart';

/// 嵌入式 AI 对话面板
/// 用于在工具面板内显示 AI 对话功能
class EmbeddedAIChatPanel extends ConsumerWidget {
  const EmbeddedAIChatPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAssistantProvider);

    return Column(
      children: [
        // 工具栏
        _buildToolbar(context, ref, state),
        const Divider(height: 1),
        // 消息列表
        Expanded(
          child: MessageList(
            messages: state.messages,
            scrollController:
                ref.read(aiAssistantProvider.notifier).scrollController,
            isGenerating: state.isGenerating,
            statusMessage: state.statusMessage,
          ),
        ),
        // 错误信息
        if (state.error != null) _buildErrorBanner(context, ref, state),
        // 输入区域
        const ChatInput(),
      ],
    );
  }

  Widget _buildToolbar(
      BuildContext context, WidgetRef ref, AIAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 搜索范围选择器
          const Expanded(child: SearchScopeSelector()),
          const SizedBox(width: 16),
          // Agent 选择器
          const AgentSelector(),
          const SizedBox(width: 8),
          // 清空对话按钮
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '清空对话',
              onPressed: () {
                ref.read(aiAssistantProvider.notifier).clearConversation();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
      BuildContext context, WidgetRef ref, AIAssistantState state) {
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

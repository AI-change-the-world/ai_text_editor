import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';

/// Sidebar entry button for AI Assistant
/// Requirements: 7.1
class AIAssistantSidebarEntry extends ConsumerWidget {
  /// Whether to show as a compact icon button or full button with text
  final bool compact;

  const AIAssistantSidebarEntry({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (compact) {
      return _buildCompactButton(context, ref);
    }
    return _buildFullButton(context, ref);
  }

  Widget _buildCompactButton(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'AI 助手 (Cmd+J / Ctrl+J)',
      child: IconButton(
        icon: Icon(
          Icons.assistant,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () {
          ref.read(aiAssistantProvider.notifier).showPanel();
        },
      ),
    );
  }

  Widget _buildFullButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(aiAssistantProvider.notifier).showPanel();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assistant,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI 助手',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '⌘J',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sidebar section containing AI Assistant entry
/// Requirements: 7.1
class AIAssistantSidebarSection extends ConsumerWidget {
  const AIAssistantSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'AI 工具',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        const AIAssistantSidebarEntry(),
      ],
    );
  }
}

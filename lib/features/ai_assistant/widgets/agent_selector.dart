import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/agent/agent_config.dart';
import '../notifiers/ai_assistant_notifier.dart';

/// Agent selector dropdown for AI assistant
/// Allows users to select different AI agents for different tasks
/// Requirements: 7.7
class AgentSelector extends ConsumerWidget {
  const AgentSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAssistantProvider);
    final agents = AgentPresets.allSorted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.currentAgent.id,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          items: agents.map((agent) {
            return DropdownMenuItem(
              value: agent.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (agent.icon != null) ...[
                    Text(agent.icon!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                  ],
                  Text(agent.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (agentId) {
            if (agentId != null) {
              final agent = AgentPresets.getById(agentId);
              if (agent != null) {
                ref.read(aiAssistantProvider.notifier).setAgent(agent);
              }
            }
          },
        ),
      ),
    );
  }
}

/// Agent card for displaying agent details
class AgentCard extends StatelessWidget {
  final AgentConfig agent;
  final bool isSelected;
  final VoidCallback onTap;

  const AgentCard({
    super.key,
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAgentColor(agent.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: agent.icon != null
                    ? Text(agent.icon!, style: const TextStyle(fontSize: 20))
                    : Icon(
                        _getAgentIcon(agent.type),
                        color: _getAgentColor(agent.type),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agent.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getAgentColor(AgentType type) {
    switch (type) {
      case AgentType.research:
        return Colors.blue;
      case AgentType.writing:
        return Colors.purple;
      case AgentType.qa:
        return Colors.green;
      case AgentType.code:
        return Colors.orange;
      case AgentType.custom:
        return Colors.grey;
    }
  }

  IconData _getAgentIcon(AgentType type) {
    switch (type) {
      case AgentType.research:
        return Icons.search;
      case AgentType.writing:
        return Icons.edit;
      case AgentType.qa:
        return Icons.question_answer;
      case AgentType.code:
        return Icons.code;
      case AgentType.custom:
        return Icons.settings;
    }
  }
}

/// Agent selector dialog for detailed selection
class AgentSelectorDialog extends ConsumerWidget {
  const AgentSelectorDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAssistantProvider);
    final agents = AgentPresets.allSorted;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.smart_toy, size: 24),
          SizedBox(width: 8),
          Text('选择 AI 助手'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '不同的助手针对不同任务进行了优化',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...agents.map((agent) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AgentCard(
                  agent: agent,
                  isSelected: state.currentAgent.id == agent.id,
                  onTap: () {
                    ref.read(aiAssistantProvider.notifier).setAgent(agent);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// Agent info tooltip
class AgentInfoTooltip extends StatelessWidget {
  final AgentConfig agent;

  const AgentInfoTooltip({
    super.key,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              if (agent.icon != null) ...[
                Text(agent.icon!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  agent.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            agent.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          // Capabilities
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (agent.requiresRagContext)
                _buildCapabilityChip('知识库检索', Icons.search),
              if (agent.canUseDeepSearch)
                _buildCapabilityChip('网络搜索', Icons.public),
              ...agent.enabledTools.take(3).map((tool) {
                return _buildCapabilityChip(
                  _getToolDisplayName(tool),
                  _getToolIcon(tool),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'full_text_search':
        return '全文搜索';
      case 'vector_search':
        return '语义搜索';
      case 'deep_search':
        return '深度搜索';
      case 'document_operation':
        return '文档操作';
      case 'summarize':
        return '摘要';
      case 'translate':
        return '翻译';
      default:
        return toolName;
    }
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'full_text_search':
        return Icons.text_fields;
      case 'vector_search':
        return Icons.psychology;
      case 'deep_search':
        return Icons.travel_explore;
      case 'document_operation':
        return Icons.description;
      case 'summarize':
        return Icons.summarize;
      case 'translate':
        return Icons.translate;
      default:
        return Icons.extension;
    }
  }
}

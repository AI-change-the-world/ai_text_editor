import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/tools/tool_result.dart';
import '../../workspace/notifiers/workspace_notifier.dart';
import '../notifiers/ai_assistant_notifier.dart';

/// Citation list widget for displaying source references
/// Requirements: 4.5, 7.10
class CitationList extends ConsumerWidget {
  final List<SourceCitation> citations;

  const CitationList({
    super.key,
    required this.citations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (citations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                '来源引用 (${citations.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: citations.asMap().entries.map((entry) {
            final index = entry.key;
            final citation = entry.value;
            return CitationChip(
              citation: citation,
              index: index + 1,
              onTap: () => _navigateToCitation(context, ref, citation),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _navigateToCitation(
    BuildContext context,
    WidgetRef ref,
    SourceCitation citation,
  ) {
    // Close AI panel
    ref.read(aiAssistantProvider.notifier).hidePanel();

    // Switch to the workspace if different
    final currentWorkspace = ref.read(workspaceProvider).currentWorkspace;
    if (currentWorkspace?.uuid != citation.workspaceId) {
      ref
          .read(workspaceProvider.notifier)
          .switchWorkspace(citation.workspaceId);
    }

    // TODO: Navigate to the document and highlight the passage
    // This will be implemented when the document navigation is available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('跳转到: ${citation.documentTitle}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            // Document navigation will be implemented here
          },
        ),
      ),
    );
  }
}

/// Individual citation chip
/// Requirements: 4.5, 7.10
class CitationChip extends StatefulWidget {
  final SourceCitation citation;
  final int index;
  final VoidCallback onTap;

  const CitationChip({
    super.key,
    required this.citation,
    required this.index,
    required this.onTap,
  });

  @override
  State<CitationChip> createState() => _CitationChipState();
}

class _CitationChipState extends State<CitationChip> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Theme.of(context).primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).primaryColor.withOpacity(0.4)
                  : Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Index badge
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Document title
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      widget.citation.documentTitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Expand/collapse button
                  if (widget.citation.snippet.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                ],
              ),
              // Workspace name
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  widget.citation.workspaceName,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              // Expanded snippet
              if (_isExpanded && widget.citation.snippet.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.citation.snippet,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Citation preview tooltip
class CitationPreview extends StatelessWidget {
  final SourceCitation citation;

  const CitationPreview({
    super.key,
    required this.citation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
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
              Icon(
                Icons.description,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  citation.documentTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Workspace
          Row(
            children: [
              Icon(
                Icons.folder,
                size: 12,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                citation.workspaceName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          // Snippet
          if (citation.snippet.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              citation.snippet,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Score
          if (citation.score != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  '相关度: ${(citation.score! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline citation reference (for use within text)
class InlineCitation extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const InlineCitation({
    super.key,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '[$index]',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

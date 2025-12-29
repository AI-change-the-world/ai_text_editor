import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/deep_search_service.dart';

/// Search result list widget for displaying Deep Search results
/// Requirements: 6.2
class SearchResultList extends StatelessWidget {
  /// The search result to display
  final DeepSearchResult result;

  /// Callback when a result item is tapped
  final void Function(DeepSearchResultItem item)? onItemTap;

  /// Callback when extract content is requested
  final void Function(DeepSearchResultItem item)? onExtractContent;

  const SearchResultList({
    super.key,
    required this.result,
    this.onItemTap,
    this.onExtractContent,
  });

  @override
  Widget build(BuildContext context) {
    if (result.items.isEmpty) {
      return _buildEmptyResults(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header
        _buildResultsHeader(context),
        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
              return SearchResultCard(
                item: item,
                onTap: () => onItemTap?.call(item),
                onExtractContent: () => onExtractContent?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text(
            '搜索结果',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${result.items.length} 条',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '搜索用时: ${result.searchTimeMs}ms',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '未找到相关结果',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词搜索',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual search result card
/// Requirements: 6.2
class SearchResultCard extends StatefulWidget {
  /// The search result item
  final DeepSearchResultItem item;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when extract content is requested
  final VoidCallback? onExtractContent;

  const SearchResultCard({
    super.key,
    required this.item,
    this.onTap,
    this.onExtractContent,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: _isHovered ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _isHovered ? Colors.blue.shade200 : Colors.grey.shade200,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Favicon placeholder
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.language,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Title and domain
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.item.domain,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content extracted indicator
                    if (widget.item.isContentExtracted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '已提取',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Snippet
                Text(
                  widget.item.snippet,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Action buttons
                Row(
                  children: [
                    // URL
                    Expanded(
                      child: Text(
                        widget.item.url,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy URL button
                    _ActionButton(
                      icon: Icons.copy,
                      tooltip: '复制链接',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.item.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('链接已复制'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Extract content button
                    _ActionButton(
                      icon: Icons.download,
                      tooltip: '提取内容',
                      onPressed: widget.onExtractContent,
                    ),
                    const SizedBox(width: 4),
                    // Open in browser button
                    _ActionButton(
                      icon: Icons.open_in_new,
                      tooltip: '在浏览器中打开',
                      onPressed: widget.onTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small action button for result card actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// Compact search result item for inline display
class CompactSearchResultItem extends StatelessWidget {
  final DeepSearchResultItem item;
  final VoidCallback? onTap;

  const CompactSearchResultItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.language,
          size: 18,
          color: Colors.grey.shade400,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.domain,
        style: TextStyle(
          fontSize: 11,
          color: Colors.green.shade600,
        ),
      ),
      trailing: item.isContentExtracted
          ? Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green.shade600,
            )
          : null,
      onTap: onTap,
    );
  }
}

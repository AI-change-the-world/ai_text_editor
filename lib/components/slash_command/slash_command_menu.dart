import 'package:flutter/material.dart';

/// Category for grouping slash commands
enum SlashCommandCategory {
  ai,
  format,
  insert,
  list,
}

/// Extension to get display name for categories
extension SlashCommandCategoryExtension on SlashCommandCategory {
  String get displayName {
    switch (this) {
      case SlashCommandCategory.ai:
        return 'AI 助手';
      case SlashCommandCategory.format:
        return '格式';
      case SlashCommandCategory.insert:
        return '插入';
      case SlashCommandCategory.list:
        return '列表';
    }
  }

  IconData get icon {
    switch (this) {
      case SlashCommandCategory.ai:
        return Icons.auto_awesome;
      case SlashCommandCategory.format:
        return Icons.format_size;
      case SlashCommandCategory.insert:
        return Icons.add_box_outlined;
      case SlashCommandCategory.list:
        return Icons.format_list_bulleted;
    }
  }
}

class SlashCommandItem {
  final String command;
  final String description;
  final IconData icon;
  final VoidCallback onSelect;
  final SlashCommandCategory category;
  final List<String> keywords;

  SlashCommandItem({
    required this.command,
    required this.description,
    required this.icon,
    required this.onSelect,
    this.category = SlashCommandCategory.format,
    this.keywords = const [],
  });
}

class SlashCommandMenu extends StatefulWidget {
  const SlashCommandMenu({
    super.key,
    required this.items,
    required this.onDismiss,
    required this.filterText,
    required this.onIndexChange,
    required this.selectedIndex,
  });

  final List<SlashCommandItem> items;
  final VoidCallback onDismiss;
  final String filterText;
  final int selectedIndex;
  final ValueChanged<int> onIndexChange;

  @override
  State<SlashCommandMenu> createState() => _SlashCommandMenuState();
}

class _SlashCommandMenuState extends State<SlashCommandMenu> {
  late List<SlashCommandItem> _filteredItems;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _filterItems();
  }

  @override
  void didUpdateWidget(SlashCommandMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterText != widget.filterText) {
      _filterItems();
    }
    // 滚动到选中项
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _filteredItems.isNotEmpty) {
      _scrollToSelected();
    }
  }

  void _filterItems() {
    final filter = widget.filterText.toLowerCase();
    if (filter.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items.where((item) {
        return item.command.toLowerCase().contains(filter) ||
            item.description.toLowerCase().contains(filter) ||
            item.keywords.any((k) => k.toLowerCase().contains(filter));
      }).toList();
    }
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients &&
        widget.selectedIndex < _filteredItems.length) {
      const itemHeight = 52.0; // 大约每项高度
      final targetOffset = widget.selectedIndex * itemHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final viewportHeight = _scrollController.position.viewportDimension;

      if (targetOffset < _scrollController.offset) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      } else if (targetOffset + itemHeight >
          _scrollController.offset + viewportHeight) {
        _scrollController.animateTo(
          (targetOffset + itemHeight - viewportHeight).clamp(0, maxScroll),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Group items by category
  Map<SlashCommandCategory, List<SlashCommandItem>> _groupByCategory() {
    final grouped = <SlashCommandCategory, List<SlashCommandItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredItems.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'No matching commands',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final selectedIndex =
        widget.selectedIndex.clamp(0, _filteredItems.length - 1);

    // If filter is active, show flat list; otherwise show grouped
    final showGrouped = widget.filterText.isEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: showGrouped
              ? _buildGroupedList(selectedIndex)
              : _buildFlatList(selectedIndex),
        ),
      ),
    );
  }

  Widget _buildFlatList(int selectedIndex) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildCommandItem(_filteredItems[index], index, selectedIndex);
      },
    );
  }

  Widget _buildGroupedList(int selectedIndex) {
    final grouped = _groupByCategory();
    final categoryOrder = [
      SlashCommandCategory.ai,
      SlashCommandCategory.format,
      SlashCommandCategory.insert,
      SlashCommandCategory.list,
    ];

    int globalIndex = 0;
    final widgets = <Widget>[];

    for (final category in categoryOrder) {
      final items = grouped[category];
      if (items == null || items.isEmpty) continue;

      // Add category header
      widgets.add(_buildCategoryHeader(category));

      // Add items
      for (final item in items) {
        widgets.add(_buildCommandItem(item, globalIndex, selectedIndex));
        globalIndex++;
      }
    }

    return ListView(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: widgets,
    );
  }

  Widget _buildCategoryHeader(SlashCommandCategory category) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Icon(
            category.icon,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            category.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(
      SlashCommandItem item, int index, int selectedIndex) {
    final isSelected = index == selectedIndex;
    return MouseRegion(
      onEnter: (_) => widget.onIndexChange(index),
      child: GestureDetector(
        onTap: item.onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  item.icon,
                  size: 16,
                  color: isSelected ? Colors.blue : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '/${item.command}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

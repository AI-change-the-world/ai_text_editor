import 'package:flutter/material.dart';

class SlashCommandItem {
  final String command;
  final String description;
  final IconData icon;
  final VoidCallback onSelect;

  SlashCommandItem({
    required this.command,
    required this.description,
    required this.icon,
    required this.onSelect,
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
    _filteredItems = widget.items
        .where((item) =>
            item.command.toLowerCase().contains(filter) ||
            item.description.toLowerCase().contains(filter))
        .toList();
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients &&
        widget.selectedIndex < _filteredItems.length) {
      final itemHeight = 52.0; // 大约每项高度
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

  @override
  Widget build(BuildContext context) {
    if (_filteredItems.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 300),
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
          child: ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isSelected = index == selectedIndex;
              return MouseRegion(
                onEnter: (_) => widget.onIndexChange(index),
                child: GestureDetector(
                  onTap: item.onSelect,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.white,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 18, color: Colors.grey[700]),
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
                                  color:
                                      isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

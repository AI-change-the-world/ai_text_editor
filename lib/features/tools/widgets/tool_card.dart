import 'package:flutter/material.dart';

import '../../../utils/app_theme.dart';

/// 工具卡片组件
/// 展示单个工具的信息，点击跳转到对应工具页面
class ToolCard extends StatefulWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = widget.iconColor ?? colors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? colors.cardHover : colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? colors.primary : colors.border,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 16),
                // 名称
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // 描述
                Expanded(
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 箭头指示
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isHovered ? 1.0 : 0.0,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: colors.primary,
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

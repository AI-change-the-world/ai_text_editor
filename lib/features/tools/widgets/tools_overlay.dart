import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tools_fab.dart';
import 'tools_panel.dart';

/// 工具中心 Overlay
/// 提供工具面板和浮动按钮
/// 替代原来的 AIAssistantOverlay
class ToolsOverlay extends ConsumerWidget {
  final Widget child;

  /// 是否显示浮动按钮
  final bool showFAB;

  /// 浮动按钮是否可拖动
  final bool draggableFAB;

  const ToolsOverlay({
    super.key,
    required this.child,
    this.showFAB = true,
    this.draggableFAB = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPanelVisible =
        ref.watch(toolsPanelProvider.select((s) => s.isVisible));

    return ToolsShortcuts(
      child: Stack(
        children: [
          // 主内容
          child,
          // 浮动按钮
          if (showFAB)
            draggableFAB ? const DraggableToolsFAB() : const ToolsFAB(),
          // 工具面板
          if (isPanelVisible) const ToolsPanel(),
        ],
      ),
    );
  }
}

/// 工具中心快捷键处理
/// Cmd+J (Mac) / Ctrl+J (Windows/Linux) 切换工具面板
class ToolsShortcuts extends ConsumerWidget {
  final Widget child;

  const ToolsShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        // Cmd+J (Mac) 切换工具面板
        SingleActivator(
          LogicalKeyboardKey.keyJ,
          meta: true,
        ): const ToggleToolsPanelIntent(),
        // Ctrl+J (Windows/Linux) 切换工具面板
        SingleActivator(
          LogicalKeyboardKey.keyJ,
          control: true,
        ): const ToggleToolsPanelIntent(),
        // Escape 关闭面板
        const SingleActivator(LogicalKeyboardKey.escape):
            const CloseToolsPanelIntent(),
      },
      child: Actions(
        actions: {
          ToggleToolsPanelIntent: CallbackAction<ToggleToolsPanelIntent>(
            onInvoke: (intent) {
              ref.read(toolsPanelProvider.notifier).togglePanel();
              return null;
            },
          ),
          CloseToolsPanelIntent: CallbackAction<CloseToolsPanelIntent>(
            onInvoke: (intent) {
              final state = ref.read(toolsPanelProvider);
              if (state.isVisible) {
                ref.read(toolsPanelProvider.notifier).hidePanel();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

/// 切换工具面板 Intent
class ToggleToolsPanelIntent extends Intent {
  const ToggleToolsPanelIntent();
}

/// 关闭工具面板 Intent
class CloseToolsPanelIntent extends Intent {
  const CloseToolsPanelIntent();
}

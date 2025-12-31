import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';
import 'tools_panel.dart';

/// 工具中心浮动按钮
/// 点击打开工具面板
class ToolsFAB extends ConsumerWidget {
  const ToolsFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton(
        onPressed: () {
          ref.read(toolsPanelProvider.notifier).togglePanel();
        },
        tooltip: '工具中心 (Cmd+J / Ctrl+J)',
        backgroundColor: colors.primary,
        child: const Icon(
          Icons.widgets_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 可拖动的工具中心浮动按钮
class DraggableToolsFAB extends ConsumerStatefulWidget {
  const DraggableToolsFAB({super.key});

  @override
  ConsumerState<DraggableToolsFAB> createState() => _DraggableToolsFABState();
}

class _DraggableToolsFABState extends ConsumerState<DraggableToolsFAB> {
  Offset _position = const Offset(0, 0);
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 首次构建时初始化位置到右下角
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final size = MediaQuery.of(context).size;
          setState(() {
            _position = Offset(size.width - 80, size.height - 80);
            _initialized = true;
          });
        }
      });
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        child: FloatingActionButton(
          onPressed: () {
            ref.read(toolsPanelProvider.notifier).togglePanel();
          },
          tooltip: '工具中心 (Cmd+J / Ctrl+J)',
          backgroundColor: colors.primary,
          child: const Icon(
            Icons.widgets_outlined,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

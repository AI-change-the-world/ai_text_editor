import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';
import 'ai_assistant_settings_provider.dart';

/// Floating Action Button for AI Assistant
/// Requirements: 7.1, 7.14
class AIAssistantFAB extends ConsumerWidget {
  const AIAssistantFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(aiAssistantSettingsProvider).showFloatingButton;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 24,
      bottom: 24,
      child: FloatingActionButton(
        onPressed: () {
          ref.read(aiAssistantProvider.notifier).togglePanel();
        },
        tooltip: 'AI 助手 (Cmd+J / Ctrl+J)',
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.assistant,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Draggable Floating Action Button for AI Assistant
/// Allows user to reposition the button
/// Requirements: 7.1, 7.14
class DraggableAIAssistantFAB extends ConsumerStatefulWidget {
  const DraggableAIAssistantFAB({super.key});

  @override
  ConsumerState<DraggableAIAssistantFAB> createState() =>
      _DraggableAIAssistantFABState();
}

class _DraggableAIAssistantFABState
    extends ConsumerState<DraggableAIAssistantFAB> {
  Offset _position = const Offset(0, 0);
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final isVisible = ref.watch(aiAssistantSettingsProvider).showFloatingButton;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    // Initialize position to bottom-right on first build
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
            ref.read(aiAssistantProvider.notifier).togglePanel();
          },
          tooltip: 'AI 助手 (Cmd+J / Ctrl+J)',
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(
            Icons.assistant,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';
import '../views/ai_assistant_panel.dart';
import 'ai_assistant_fab.dart';

/// Overlay widget that provides AI Assistant panel and floating button
/// This widget should wrap the main app content
/// Requirements: 7.1, 7.2, 7.14
class AIAssistantOverlay extends ConsumerWidget {
  final Widget child;

  /// Whether to show the floating action button
  final bool showFAB;

  /// Whether the FAB should be draggable
  final bool draggableFAB;

  const AIAssistantOverlay({
    super.key,
    required this.child,
    this.showFAB = true,
    this.draggableFAB = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPanelVisible =
        ref.watch(aiAssistantProvider.select((s) => s.isPanelVisible));

    return AIAssistantShortcuts(
      child: Stack(
        children: [
          // Main content
          child,
          // Floating action button
          if (showFAB)
            draggableFAB
                ? const DraggableAIAssistantFAB()
                : const AIAssistantFAB(),
          // AI Assistant panel overlay
          if (isPanelVisible) const AIAssistantPanel(),
        ],
      ),
    );
  }
}

/// Keyboard shortcut handler for AI Assistant
/// Handles Cmd+J (Mac) / Ctrl+J (Windows/Linux) to toggle AI panel
/// Requirements: 7.2
class AIAssistantShortcuts extends ConsumerWidget {
  final Widget child;

  const AIAssistantShortcuts({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: {
        // Cmd+J (Mac) to toggle AI panel
        SingleActivator(
          LogicalKeyboardKey.keyJ,
          meta: true,
        ): const ToggleAIPanelIntent(),
        // Ctrl+J (Windows/Linux) to toggle AI panel
        SingleActivator(
          LogicalKeyboardKey.keyJ,
          control: true,
        ): const ToggleAIPanelIntent(),
        // Escape to close panel when open
        const SingleActivator(LogicalKeyboardKey.escape):
            const CloseAIPanelIntent(),
      },
      child: Actions(
        actions: {
          ToggleAIPanelIntent: CallbackAction<ToggleAIPanelIntent>(
            onInvoke: (intent) {
              ref.read(aiAssistantProvider.notifier).togglePanel();
              return null;
            },
          ),
          CloseAIPanelIntent: CallbackAction<CloseAIPanelIntent>(
            onInvoke: (intent) {
              final state = ref.read(aiAssistantProvider);
              if (state.isPanelVisible) {
                ref.read(aiAssistantProvider.notifier).hidePanel();
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

/// Intent for toggling AI panel
class ToggleAIPanelIntent extends Intent {
  const ToggleAIPanelIntent();
}

/// Intent for closing AI panel
class CloseAIPanelIntent extends Intent {
  const CloseAIPanelIntent();
}

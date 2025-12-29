import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings state for AI Assistant
/// Requirements: 7.14
class AIAssistantSettings {
  /// Whether to show the floating button
  final bool showFloatingButton;

  const AIAssistantSettings({
    this.showFloatingButton = true,
  });

  AIAssistantSettings copyWith({
    bool? showFloatingButton,
  }) {
    return AIAssistantSettings(
      showFloatingButton: showFloatingButton ?? this.showFloatingButton,
    );
  }
}

/// Notifier for AI Assistant settings
/// Requirements: 7.14
class AIAssistantSettingsNotifier extends Notifier<AIAssistantSettings> {
  @override
  AIAssistantSettings build() {
    return const AIAssistantSettings();
  }

  /// Toggle floating button visibility
  /// Requirements: 7.14
  void toggleFloatingButton() {
    state = state.copyWith(showFloatingButton: !state.showFloatingButton);
  }

  /// Set floating button visibility
  /// Requirements: 7.14
  void setFloatingButtonVisibility(bool visible) {
    state = state.copyWith(showFloatingButton: visible);
  }
}

/// Provider for AI Assistant settings
final aiAssistantSettingsProvider =
    NotifierProvider<AIAssistantSettingsNotifier, AIAssistantSettings>(
  AIAssistantSettingsNotifier.new,
);

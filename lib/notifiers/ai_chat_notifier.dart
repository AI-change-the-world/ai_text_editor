import 'package:flutter_riverpod/flutter_riverpod.dart';

class AIChatMessage {
  final String role;
  final String content;

  AIChatMessage({required this.role, required this.content});
}

class AIChatState {
  final List<AIChatMessage> messages;
  final bool isGenerating;

  AIChatState({this.messages = const [], this.isGenerating = false});

  AIChatState copyWith({List<AIChatMessage>? messages, bool? isGenerating}) {
    return AIChatState(
        messages: messages ?? this.messages,
        isGenerating: isGenerating ?? this.isGenerating);
  }
}

class AIChatNotifier extends Notifier<AIChatState> {
  @override
  AIChatState build() {
    return AIChatState();
  }

  void addMessage(AIChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void updateMessage(AIChatMessage message) {
    if (!state.isGenerating) {
      return;
    }

    final last = state.messages.last;
    AIChatMessage newLast = AIChatMessage(
      content: last.content + message.content,
      role: last.role,
    );

    state = state.copyWith(messages: [
      ...state.messages.sublist(0, state.messages.length - 1),
      newLast
    ]);
  }
}

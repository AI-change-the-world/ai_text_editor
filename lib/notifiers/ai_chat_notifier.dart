import 'package:ai_packages_core/ai_packages_core.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:flutter/material.dart';
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

  final ScrollController controller = ScrollController();

  void addMessage(AIChatMessage message) {
    state = state
        .copyWith(messages: [...state.messages, message], isGenerating: true);
  }

  void updateMessage(String m) {
    if (!state.isGenerating) {
      return;
    }

    final last = state.messages.last;
    AIChatMessage newLast = AIChatMessage(
      content: last.content + m,
      role: last.role,
    );

    state = state.copyWith(messages: [
      ...state.messages.sublist(0, state.messages.length - 1),
      newLast
    ]);

    controller.jumpTo(controller.position.maxScrollExtent);
  }

  handleMessage() {
    final d = DateTime.now();
    final history = state.messages
        .map((v) => ChatMessage<String>(
            role: v.role,
            content: v.content,
            createAt: d.millisecondsSinceEpoch))
        .toList();

    addMessage(AIChatMessage(role: "assistant", content: ""));

    GlobalModel.model.streamChat(history).listen(
      (v) {
        updateMessage(v);
        controller.jumpTo(controller.position.maxScrollExtent);
      },
      onDone: () {
        state = state.copyWith(isGenerating: false);
      },
    );
  }
}

final aiChatNotifierProvider =
    NotifierProvider<AIChatNotifier, AIChatState>(() => AIChatNotifier());

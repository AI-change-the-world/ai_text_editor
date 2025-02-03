import 'package:ai_text_editor/notifiers/ai_chat_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'message_box.dart';

class AiChatWidget extends ConsumerStatefulWidget {
  const AiChatWidget({super.key});

  @override
  ConsumerState<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends ConsumerState<AiChatWidget> {
  final _textController = TextEditingController();
  late final FocusNode _focusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event.physicalKey == PhysicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.physicalKeysPressed
              .any((el) => <PhysicalKeyboardKey>{
                    PhysicalKeyboardKey.shiftLeft,
                    PhysicalKeyboardKey.shiftRight,
                  }.contains(el))) {
        if (event is KeyDownEvent) {
          _submit();
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future _submit() async {
    if (ref.read(aiChatNotifierProvider).isGenerating) return;

    ref
        .read(aiChatNotifierProvider.notifier)
        .addMessage(AIChatMessage(role: "user", content: _textController.text));
    ref.read(aiChatNotifierProvider.notifier).handleMessage();
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatNotifierProvider);
    return Column(
      children: [
        Expanded(
            child: SingleChildScrollView(
          controller: ref.read(aiChatNotifierProvider.notifier).controller,
          child: Column(
            spacing: 20,
            children: state.messages.map((e) {
              if (e.role == "user") {
                return UserMessageBox(message: e.content);
              } else {
                return AiMessageBox(
                  message: e.content,
                );
              }
            }).toList(),
          ),
        )),
        Padding(
          padding: EdgeInsets.all(15),
          child: TextField(
            focusNode: _focusNode,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: 12),
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Ask me anything",
              hintStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

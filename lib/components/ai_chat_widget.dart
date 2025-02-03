import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container()),
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

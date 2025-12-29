import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/ai_assistant_notifier.dart';

/// Chat input widget for AI assistant
/// Requirements: 7.1
class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when panel opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(aiAssistantProvider.notifier).sendMessage(text);
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                // Submit on Enter (without Shift)
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  _submit();
                }
              },
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                enabled: !state.isGenerating,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: state.isGenerating
                      ? '正在生成回答...'
                      : '输入问题或请求... (Enter 发送, Shift+Enter 换行)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send/Stop button
          _buildActionButton(context, state),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AIAssistantState state) {
    if (state.isGenerating) {
      return _StopButton(
        onPressed: () {
          ref.read(aiAssistantProvider.notifier).stopGeneration();
        },
      );
    }

    return _SendButton(
      onPressed: _submit,
      enabled: _textController.text.trim().isNotEmpty,
    );
  }
}

/// Send button
class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _SendButton({
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? Theme.of(context).primaryColor
          : Theme.of(context).primaryColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.send,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Stop button for stopping generation
class _StopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StopButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade400,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.stop,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Quick action chips for common queries
class QuickActionChips extends ConsumerWidget {
  const QuickActionChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickActions = [
      ('总结文档', Icons.summarize),
      ('搜索知识库', Icons.search),
      ('翻译内容', Icons.translate),
      ('解释概念', Icons.lightbulb),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickActions.map((action) {
        return ActionChip(
          avatar: Icon(action.$2, size: 16),
          label: Text(action.$1, style: const TextStyle(fontSize: 12)),
          onPressed: () {
            // Pre-fill the input with the action
            // This would be connected to the input controller
          },
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

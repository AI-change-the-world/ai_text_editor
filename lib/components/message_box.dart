import 'package:ai_text_editor/notifiers/ai_chat_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class UserMessageBox extends StatelessWidget {
  const UserMessageBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(20)),
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          Expanded(child: Text(message))
        ],
      ),
    );
  }
}

class AiMessageBox extends ConsumerWidget {
  const AiMessageBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Column(
        children: [
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20)),
                child: Icon(
                  Icons.computer,
                  color: Colors.white,
                ),
              ),
              Expanded(child: GptMarkdown(message))
            ],
          ),
          SizedBox(
            height: 25,
            child: Row(
              children: [
                Expanded(child: SizedBox()),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4), // 设置圆角半径
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6), // 调整按钮大小
                    ),
                    onPressed: () {
                      if (ref.read(aiChatNotifierProvider).isGenerating) return;
                      ref
                          .read(editorNotifierProvider.notifier)
                          .applyAiResponse(message);
                    },
                    child: Text(
                      "Apply",
                      style: TextStyle(fontSize: 12),
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }
}

import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_state.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(editorNotifierProvider.select((v) => v.chatHistory));
    return ListView.builder(
      itemBuilder: (c, i) {
        return _buildItem(state[i]);
      },
      itemCount: state.length,
    );
  }

  Widget _buildItem(EditorChatHistory history) {
    return ExpansionTile(
      title: Tooltip(
        waitDuration: Duration(milliseconds: 500),
        message: history.q,
        child: AutoSizeText(
          history.q,
          maxLines: 1,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      children: [
        Container(
          padding: EdgeInsets.all(10),
          color: Colors.grey[100],
          height: 300,
          child: SingleChildScrollView(
            child: GptMarkdown(
              history.a,
            ),
          ),
        )
      ],
    );
  }
}

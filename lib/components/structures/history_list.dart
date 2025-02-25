import 'package:ai_text_editor/components/structures/history_item_widget.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(editorNotifierProvider.select((v) => v.chatHistory));
    return ListView.builder(
      itemBuilder: (c, i) {
        return HistoryItemWidget(
          history: state[i],
          index: i,
        );
      },
      itemCount: state.length,
    );
  }
}

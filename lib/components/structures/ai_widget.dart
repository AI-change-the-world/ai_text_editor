import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_chat_widget.dart';
import 'history_list.dart';

class AiWidget extends ConsumerStatefulWidget {
  const AiWidget({super.key});

  @override
  ConsumerState<AiWidget> createState() => _AiWidgetState();
}

class _AiWidgetState extends ConsumerState<AiWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider.select((v) => v.showAI));
    return AnimatedContainer(
      decoration: BoxDecoration(color: Colors.grey[100]),
      duration: Duration(milliseconds: 300),
      width: state ? Styles.structureWidth : 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                height: 30,
                text: "Chat",
              ),
              Tab(
                height: 30,
                text: "History",
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AiChatWidget(),
                HistoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

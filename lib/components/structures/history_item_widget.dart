import 'package:ai_text_editor/notifiers/editor_state.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class HistoryItemWidget extends StatefulWidget {
  const HistoryItemWidget(
      {super.key, required this.history, required this.index});
  final EditorChatHistory history;
  final int index;

  @override
  State<HistoryItemWidget> createState() => _HistoryItemWidgetState();
}

class _HistoryItemWidgetState extends State<HistoryItemWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.only(left: 10),
            height: 30,
            child: Tooltip(
              waitDuration: Duration(milliseconds: 500),
              message: widget.history.q,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  "${widget.index + 1}. ${widget.history.q}",
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 0, right: 5, top: 5, bottom: 5),
            child: FittedBox(
              child: Container(
                width: 221,
                constraints: BoxConstraints(maxHeight: 300, minHeight: 30),
                padding: EdgeInsets.all(10),
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  child: GptMarkdown(
                    style: TextStyle(fontSize: 14),
                    widget.history.a,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

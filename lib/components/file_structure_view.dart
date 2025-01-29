import 'package:ai_text_editor/models/markdown_model.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileStructureView extends ConsumerWidget {
  const FileStructureView({super.key, required this.models});
  final List<MarkdownModel> models;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(editorNotifierProvider.select((v) => v.showStructure));
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: state ? Styles.structureWidth : 0,
      child: ListView.builder(
        itemBuilder: (c, i) {
          if (models[i].tag == "h1") {
            return _wrapper(
                Text(
                  models[i].text,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                ),
                models[i].text,
                ref);
          } else if (models[i].tag == "h2") {
            return _wrapper(
                Text(
                  "  ${models[i].text}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                ),
                models[i].text,
                ref);
          } else if (models[i].tag == "h3") {
            return _wrapper(
                Text(
                  "   ${models[i].text}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                ),
                models[i].text,
                ref);
          } else if (models[i].tag == "h4") {
            return _wrapper(
                Text(
                  "    ${models[i].text}",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                ),
                models[i].text,
                ref);
          }
          return SizedBox(
            height: 0,
          );
        },
        itemCount: models.length,
      ),
    );
  }

  Widget _wrapper(Widget child, String content, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(editorNotifierProvider.notifier).scrollToText(content);
        },
        child: child,
      ),
    );
  }
}

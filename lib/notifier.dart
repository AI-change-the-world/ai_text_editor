import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditorNotifier extends Notifier {
  late final QuillController quillController = QuillController.basic();
  late final ScrollController scrollController = ScrollController();
  late final _deltaToMarkdown = DeltaToMarkdown();
  StreamController<String> quillTextChangeController =
      StreamController<String>();
  late final FocusNode focusNode = FocusNode();

  Stream<String> get quillTextChangeStream => quillTextChangeController.stream;

  @override
  build() {
    quillController.document.changes.listen((event) {
      // ref.read(editorNotifierProvider.notifier).getText();
      quillTextChangeController.add(getText());
    });
    ref.onDispose(() {
      quillController.dispose();
      scrollController.dispose();
    });
  }

  void scrollToText(String text) {
    final docPositions = quillController.document
        .search(text, caseSensitive: true, wholeWord: true);

    if (docPositions.isEmpty) {
      return;
    }

    _setCursorPosition(docPositions.first);
    _scrollToFocusNode();

    // if (docPositions.isNotEmpty) {
    //   final position = docPositions.first;
    //   final child = quillController.document.queryChild(position);
    //   print(child.node);
    //   if (child.node != null) {
    //     print(child.node!.offset);
    //     print(child.node!.runtimeType);

    //     // print((child.node as Line).);
    //   }
    // }
  }

  void _setCursorPosition(int position) {
    if (position != -1) {
      quillController.updateSelection(
        TextSelection.collapsed(offset: position),
        ChangeSource.local,
      );
    }
  }

  void _scrollToFocusNode() {
    final context = focusNode.context;
    if (context != null) {
      final renderObject = context.findRenderObject();
      if (renderObject != null) {
        final renderBox = renderObject as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        scrollController.jumpTo(offset.dy);
      }
    }
  }

  String getText() {
    return _deltaToMarkdown.convert(quillController.document.toDelta());
  }
}

final editorNotifierProvider =
    NotifierProvider<EditorNotifier, void>(EditorNotifier.new);

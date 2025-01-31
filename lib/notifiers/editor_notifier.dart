import 'dart:async';
import 'dart:math';

// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_state.dart';
import '../utils/styles.dart';

class EditorNotifier extends Notifier<EditorState> {
  late final QuillController quillController = QuillController.basic();
  late final ScrollController scrollController = ScrollController();
  late final _deltaToMarkdown = DeltaToMarkdown();
  late final _mdDocument = md.Document(encodeHtml: false);
  late final _mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);
  StreamController<String> quillTextChangeController =
      StreamController<String>();
  late final FocusNode focusNode = FocusNode();

  Stream<String> get quillTextChangeStream => quillTextChangeController.stream;

  @override
  EditorState build() {
    quillController.document.changes.listen((event) {
      // ref.read(editorNotifierProvider.notifier).getText();
      quillTextChangeController.add(getText());
    });
    ref.onDispose(() {
      quillController.dispose();
      scrollController.dispose();
    });

    return EditorState();
  }

  double getCurrentHeight(BuildContext context) {
    return MediaQuery.of(context).size.height - 30 - /*padding*/ 10 * 2;
  }

  double getCurrentWidth(BuildContext context) {
    return MediaQuery.of(context).size.width -
        (state.showStructure ? Styles.structureWidth : 0) -
        (state.showAI ? Styles.structureWidth : 0);
  }

  void changeToolbarPosition(ToolbarPosition position) {
    if (position != state.toolbarPosition) {
      state = state.copyWith(toolbarPosition: position);
    }
  }

  void toggleStructure() {
    state = state.copyWith(showStructure: !state.showStructure);
  }

  void toggleAi({bool open = true}) {
    if (state.showAI != open) {
      state = state.copyWith(showAI: open);
    }
  }

  void scrollToText(String text) {
    final docPositions = quillController.document
        .search(text, caseSensitive: true, wholeWord: true);

    if (docPositions.isEmpty) {
      return;
    }

    _setCursorPosition(docPositions.first);
    _scrollToFocusNode();
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

  void insertDataToEditor(Object data, TextSelection selection,
      {bool updateSelection = true}) {
    quillController.document.insert(selection.baseOffset, data);

    if (updateSelection) {
      if (data is String) {
        quillController.updateSelection(
            quillController.selection.copyWith(
                baseOffset: selection.baseOffset + data.length,
                extentOffset: selection.baseOffset + data.length),
            ChangeSource.local);
      } else {
        quillController.updateSelection(
            quillController.selection.copyWith(
                baseOffset: selection.baseOffset + 1,
                extentOffset: selection.baseOffset + 1),
            ChangeSource.local);
      }
    }
  }

  void setLoading(bool loading) {
    if (state.loading != loading) {
      state = state.copyWith(loading: loading);
    }
  }

  /// FIXME: could raise `The provided text position is not in the current node` exception
  void convertMarkdownToQuill(String markdown) {
    if (markdown.isEmpty) {
      return;
    }
    setLoading(true);
    Future.microtask(() {
      final delta = _mdToDelta.convert(markdown);

      quillController.document.replace(
          quillController.selection.baseOffset - markdown.length,
          markdown.length,
          delta);
    }).then((_) {
      setLoading(false);
    });
  }

  @experimental
  // ignore: unused_element
  void _mergeDelta(Delta originalDelta, Delta delta, Delta finalDelta) {
    int minLength = min(originalDelta.length, finalDelta.length);
    if (minLength == 0) {
      return;
    }
    int index = 0;
    for (int i = 0; i < minLength; i++) {
      final op1 = originalDelta.elementAt(i);
      final op2 = finalDelta.elementAt(i);
      if (op1 == op2) {
        index++;
        continue;
      } else {
        finalDelta.operations.insertAll(i + 1, delta.toList());
        break;
      }
    }

    finalDelta.operations.removeAt(index);
  }

  /// 计算Delta对象中插入的文本长度
  /// only support text
  // ignore: unused_element
  int _calculateDeltaTextLength(Delta delta) {
    int length = 0;

    for (final op in delta.toList()) {
      if (op.isInsert) {
        // 如果操作是插入文本，累加文本长度
        if (op.data is String) {
          length += (op.data as String).length;
        }
      }
    }

    return length;
  }
}

final editorNotifierProvider =
    NotifierProvider<EditorNotifier, EditorState>(EditorNotifier.new);

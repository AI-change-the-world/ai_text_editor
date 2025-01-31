import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
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

  void convertMarkdownToQuill(String markdown, TextSelection selection) {
    if (markdown.isEmpty) {
      return;
    }
    final delta = _mdToDelta.convert(markdown);

    print("delta: $delta");
    quillController.document
        .replace(selection.baseOffset - markdown.length, markdown.length, "");
    quillController.updateSelection(
        quillController.selection.copyWith(
            baseOffset: selection.baseOffset - markdown.length,
            extentOffset: selection.baseOffset - markdown.length),
        ChangeSource.local);

    var totalDelta = quillController.document.toDelta();
    // totalDelta.push(operation);

    quillController.compose(
        totalDelta, quillController.selection, ChangeSource.local);

    // quillController.updateSelection(
    //     quillController.selection.copyWith(
    //         baseOffset: quillController.selection.baseOffset + delta.length,
    //         extentOffset: quillController.selection.baseOffset + delta.length),
    //     ChangeSource.local);
  }
}

final editorNotifierProvider =
    NotifierProvider<EditorNotifier, EditorState>(EditorNotifier.new);

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ai_text_editor/isar/database.dart';
import 'package:ai_text_editor/isar/recent_files.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:isar/isar.dart';
import 'package:listview_screenshot/listview_screenshot.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';

import 'package:markdown/markdown.dart' as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor_state.dart';
import '../utils/styles.dart';

class CurrentPositionNotifier extends Notifier<double> {
  @override
  double build() {
    return 0;
  }

  changePosition(double s) {
    if (s != state) {
      state = s;
    }
  }
}

class SavedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  changeSavedStatus(bool saved) {
    if (saved != state) {
      state = saved;
    }
  }
}

class EditorNotifier extends Notifier<EditorState> {
  late final QuillController quillController = QuillController.basic();
  late final ScrollController scrollController = ScrollController();
  late final _deltaToMarkdown = DeltaToMarkdown();
  late final _mdDocument = md.Document(encodeHtml: false);
  late final _mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);
  late final FocusNode focusNode = FocusNode();
  late final IsarDatabase database = IsarDatabase();
  StreamController<String> quillTextChangeController =
      StreamController<String>();

  Stream<String> get quillTextChangeStream => quillTextChangeController.stream;

  @override
  EditorState build() {
    quillController.document.changes.listen((event) {
      // ref.read(editorNotifierProvider.notifier).getText();
      quillTextChangeController.add(getText());
      changeSavedStatus(true);
    });
    scrollController.addListener(() {
      final h = _getEditorHeight();
      final totalHeight = h + scrollController.position.maxScrollExtent;
      double currentHeight = (scrollController.position.pixels > 0
              ? scrollController.position.pixels
              : 0) +
          h;
      if (currentHeight > totalHeight) currentHeight = totalHeight;
      if (totalHeight == 0) {
        _changeCurrentPosition(0);
      } else {
        _changeCurrentPosition(currentHeight / totalHeight);
      }
    });
    ref.onDispose(() {
      quillController.dispose();
      scrollController.dispose();
    });

    return EditorState();
  }

  void _changeCurrentPosition(double p) {
    ref.read(currentPositionProvider.notifier).changePosition(p);
  }

  void setCurrentFilePath(String? path) {
    if (path != state.currentFilePath) {
      state = state.copyWith(currentFilePath: path);
    }
  }

  Future newDoc(String filepath) async {
    RecentFiles recentFiles = RecentFiles()
      ..path = filepath
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..lastEdited = DateTime.now().millisecondsSinceEpoch;

    database.isar!.writeTxn(() async {
      await database.isar!.recentFiles.put(recentFiles);
    });
  }

  Future updateDoc(String filepath) async {
    database.isar!.writeTxn(() async {
      final recentFiles = await database.isar!.recentFiles
          .filter()
          .pathEqualTo(filepath)
          .findFirst();
      if (recentFiles != null) {
        recentFiles.lastEdited = DateTime.now().millisecondsSinceEpoch;
        await database.isar!.recentFiles.put(recentFiles);
      }
    });
  }

  double _getEditorHeight() {
    final RenderBox renderBox =
        editorKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
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

  void changeSavedStatus(bool saved) {
    // if (saved != state.saved) state = state.copyWith(saved: saved);
    ref.read(savedNotifierProvider.notifier).changeSavedStatus(saved);
  }

  final firstCharChineseReg = RegExp(r'^\p{Script=Han}', unicode: true);
  final lastCharChineseReg = RegExp(r'\p{Script=Han}$', unicode: true);

  @experimental
  void scrollToText(String text) {
    bool isFirstCharChinese = firstCharChineseReg.hasMatch(text);
    bool isLastCharChinese = lastCharChineseReg.hasMatch(text);
    final docPositions = quillController.document.search(text,
        caseSensitive: true,
        wholeWord: !(isFirstCharChinese || isLastCharChinese));

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

  /// markdown string
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

  void addHistory(String q, String a) {
    state = state.copyWith(
      chatHistory: [
        EditorChatHistory(
          q: q,
          a: a,
          baseOffset: quillController.selection.baseOffset,
        ),
        ...state.chatHistory,
      ],
    );
  }

  String getJson() {
    return jsonEncode(quillController.document.toDelta().toJson());
  }

  GlobalKey editorKey = GlobalKey();

  Future<Uint8List?> getImage() async {
    try {
      WidgetShotRenderRepaintBoundary repaintBoundary =
          editorKey.currentContext!.findRenderObject()
              as WidgetShotRenderRepaintBoundary;
      var resultImage = await repaintBoundary.screenshotPng(
        backgroundColor: Colors.white,
      );

      return resultImage;
    } catch (e) {
      logger.e('截取图片失败: $e');
      return null;
    }
  }

  Future loadFromFile(File f) async {
    final s = await f.readAsString();
    try {
      final json = jsonDecode(s);
      quillController.document = Document.fromJson(json);
      quillController.moveCursorToEnd();
    } catch (e) {
      ToastUtils.error(null, title: e.toString());
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

      /// FIXME: not support some markdown syntax
      delta.operations.removeWhere((element) => element.value is Map);

      quillController.document.replace(
          quillController.selection.baseOffset - markdown.length,
          markdown.length,
          delta);

      /// partly solve `text position` exception
      quillController.moveCursorToEnd();
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

final currentPositionProvider =
    NotifierProvider<CurrentPositionNotifier, double>(
  CurrentPositionNotifier.new,
);

final savedNotifierProvider =
    NotifierProvider<SavedNotifier, bool>(SavedNotifier.new);

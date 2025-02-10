// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';
import 'package:ai_text_editor/embeds/table/table_embed.dart';
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

class SelectedStringNotifier extends Notifier<String> {
  @override
  String build() {
    return "";
  }

  changeSelectedString(String s) {
    if (s != state) {
      state = s;
    }
  }
}

class _CurrentGreyHint {
  final String text;
  final int baseOffset;

  _CurrentGreyHint({this.text = "", this.baseOffset = -1});

  _CurrentGreyHint copyWith({
    String? text,
    int? baseOffset,
  }) {
    return _CurrentGreyHint(
      text: text ?? this.text,
      baseOffset: baseOffset ?? this.baseOffset,
    );
  }

  bool get isNotEmpty => text.isNotEmpty;
  bool get isEmpty => text.isEmpty;

  int get length => text.length;

  @override
  String toString() {
    return "text: $text, baseOffset: $baseOffset";
  }
}

class EditorNotifier extends Notifier<EditorState> {
  late final QuillController quillController = QuillController.basic();
  late final ScrollController scrollController = ScrollController();
  late final _deltaToMarkdown = DeltaToMarkdown(customEmbedHandlers: {
    customTableEmbedType: customTableEmbedToMarkdown,
    customRollEmbedType: customRollEmbedToMarkdown,
    customImageEmbedType: customImageEmbedToMarkdown,
  });
  late final _mdDocument = md.Document(encodeHtml: false);
  late final _mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);
  late final FocusNode focusNode = FocusNode();
  late final IsarDatabase database = IsarDatabase();
  StreamController<String> quillTextChangeController =
      StreamController<String>();

  Stream<String> get quillTextChangeStream => quillTextChangeController.stream;

  bool _listening = false;
  String _currentHint = "";
  // String _currentGreyHint = "";
  _CurrentGreyHint _currentGreyHint = _CurrentGreyHint();

  late final List<String> suggestions = ["Alice", "Ack", "Bob", "Car"];

  Timer? _debounceTimer;

  void _insertGrayText(String suggestion) {
    final selection = quillController.selection;
    final baseOffset = selection.baseOffset;

    if (baseOffset > 0) {
      quillController.replaceText(
        baseOffset,
        0,
        suggestion,
        TextSelection.collapsed(offset: baseOffset),
      );

      // 设置灰色样式
      quillController.formatText(
        baseOffset,
        suggestion.length,
        ColorAttribute("#A0A0A0"), // 灰色字体
      );
    }
  }

  int _start = -1;
  int _end = -1;

  @override
  EditorState build() {
    quillController.onSelectionChanged = (selection) {
      // print("${selection.start} -> ${selection.end}");
      if (selection.start != selection.end) {
        _start = selection.start;
        _end = selection.end;
      }

      if (!selection.isCollapsed) {
        if (selection.end - selection.start > 0) {
          try {
            final selectedText = quillController.getPlainText();
            if (selectedText.trim() != "") {
              ref
                  .read(selectedNotifierProvider.notifier)
                  .changeSelectedString(selectedText);
            }
          } catch (_) {}
        }
      } else {
        ref.read(selectedNotifierProvider.notifier).changeSelectedString("");
      }
    };
    quillController.document.changes.listen((event) {
      _debounceTimer?.cancel();

      if (_listening) {
        if (_currentGreyHint.isNotEmpty &&
            _currentGreyHint.length > 1 &&
            event.change.operations.last.isInsert &&
            event.change.operations.last.data is String &&
            (event.change.operations.last.data as String).length == 1) {
          /// delete suggestion
          quillController.replaceText(quillController.selection.baseOffset,
              _currentGreyHint.length, "", null);
          _currentGreyHint = _currentGreyHint.copyWith(
              text: "", baseOffset: quillController.selection.baseOffset);
        }

        if (event.change.operations.last.isDelete &&
            event.change.operations.last.length == 1) {
          if (_currentHint.isEmpty) {
            _listening = false;
          }

          /// delete suggestion
          if (_currentGreyHint.isNotEmpty) {
            quillController.replaceText(quillController.selection.baseOffset,
                _currentGreyHint.length, "", null);
            _currentGreyHint = _currentGreyHint.copyWith(
                text: "", baseOffset: quillController.selection.baseOffset);
          }

          if (_currentHint.isNotEmpty) {
            _currentHint = _currentHint.substring(0, _currentHint.length - 1);
          }
        } else if (event.change.operations.last.isInsert) {
          if (event.change.operations.last.data is String &&
              (event.change.operations.last.data as String).length == 1) {
            _currentHint += event.change.operations.last.data.toString();
          }
        }

        if (_listening) {
          _debounceTimer = Timer(Duration(milliseconds: 1000), () {
            if (_currentHint.isNotEmpty) {
              final index = suggestions
                  .indexWhere((element) => element.startsWith(_currentHint));
              if (index != -1) {
                String suggestion = suggestions[index];
                suggestion = suggestion.substring(
                    _currentHint.length, suggestion.length);
                if (suggestion.isNotEmpty && _currentGreyHint.isEmpty) {
                  // _currentGreyHint = suggestion;
                  _currentGreyHint = _currentGreyHint.copyWith(
                      text: suggestion,
                      baseOffset: quillController.selection.baseOffset);
                  _insertGrayText(suggestion);
                }

                if (suggestion.isEmpty) {
                  _currentGreyHint = _currentGreyHint.copyWith(
                      text: "",
                      baseOffset: quillController.selection.baseOffset);
                }
              }
            }
          });
        }
      }

      if (event.change.operations.last.isInsert) {
        if (event.change.operations.last.data == "@") {
          _listening = true;
          // _debounceTimer = Timer(Duration(milliseconds: 1000), () {
          //   _insertGrayText("Alice");
          // });
        }
      }

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
      _debounceTimer?.cancel();
    });

    return EditorState();
  }

  /// 调整滚动条位置
  void _changeCurrentPosition(double p) {
    ref.read(currentPositionProvider.notifier).changePosition(p);
  }

  int getCurrentBaseOffset() {
    return quillController.selection.baseOffset;
  }

  void onEmbedTrigger(String uuid) {
    final l = quillController.document.search(uuid);
    if (l.isEmpty) {
      return;
    }
    quillController.updateSelection(
      TextSelection.collapsed(offset: l.first),
      ChangeSource.local,
    );
  }

  /// 修改表格数据
  void changeTable(Map data) {
    try {
      quillController.replaceText(
          quillController.selection.baseOffset,
          1,
          CustomTableEmbed(customTableEmbedType, jsonEncode(data)),
          quillController.selection);

      quillController.updateSelection(
        TextSelection.collapsed(
            offset: quillController.selection.baseOffset + 1),
        ChangeSource.local,
      );
    } catch (e) {
      logger.e("更新失败 $e");
    }
  }

  /// 设置当前文件路径
  void setCurrentFilePath(String? path) {
    if (path != state.currentFilePath) {
      state = state.copyWith(currentFilePath: path);
    }
  }

  /// 新建文件
  Future newDoc(String filepath) async {
    RecentFiles recentFiles = RecentFiles()
      ..path = filepath
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..lastEdited = DateTime.now().millisecondsSinceEpoch;

    database.isar!.writeTxn(() async {
      await database.isar!.recentFiles.put(recentFiles);
    });
  }

  /// 更新文件
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

  /// 获取组件高度
  double _getEditorHeight() {
    final RenderBox renderBox =
        editorKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  /// 获取当前窗口高度
  double getCurrentHeight(BuildContext context) {
    return MediaQuery.of(context).size.height - 30 - /*padding*/ 10 * 2;
  }

  /// 获取当前窗口宽度
  double getCurrentWidth(BuildContext context) {
    return MediaQuery.of(context).size.width -
        (state.showStructure ? Styles.structureWidth : 0) -
        (state.showAI ? Styles.structureWidth : 0);
  }

  /// 切换工具栏位置
  void changeToolbarPosition(ToolbarPosition position) {
    if (position != state.toolbarPosition) {
      state = state.copyWith(toolbarPosition: position);
    }
  }

  /// 打开/关闭结构栏
  void toggleStructure() {
    state = state.copyWith(showStructure: !state.showStructure);
  }

  /// 打开/关闭AI
  void toggleAi({bool open = true}) {
    if (state.showAI != open) {
      state = state.copyWith(showAI: open);
    }
  }

  /// 修改保存状态
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

  /// apply AI response
  void applyAiResponse(String mdString) {
    if (mdString.isNotEmpty) {
      final delta = _mdToDelta.convert(mdString);

      /// FIXME: not support some markdown syntax
      delta.operations.removeWhere((element) => element.value is Map);

      /// remove selected text if there is selected text
      if (quillController.selection.end != quillController.selection.start) {
        quillController.document.replace(
            quillController.selection.start,
            quillController.selection.end - quillController.selection.start,
            "");

        quillController.updateSelection(
            TextSelection(
                baseOffset: quillController.selection.start,
                extentOffset: quillController.selection.start),
            ChangeSource.local);
      }

      quillController.document
          .replace(quillController.selection.baseOffset, 0, delta);

      quillController.moveCursorToEnd();
    }
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
      quillTextChangeController.add(getText());
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

final selectedNotifierProvider =
    NotifierProvider<SelectedStringNotifier, String>(
        SelectedStringNotifier.new);

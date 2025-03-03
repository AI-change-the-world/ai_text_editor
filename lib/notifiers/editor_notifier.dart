// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ai_packages_core/ai_packages_core.dart' as core;
import 'package:ai_text_editor/embeds/formular/formular_embed.dart';
import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:ai_text_editor/embeds/ref/ref_embed.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';
import 'package:ai_text_editor/embeds/table/table_embed.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/models/json_error_model.dart';
import 'package:ai_text_editor/objectbox.g.dart';
import 'package:ai_text_editor/objectbox/database.dart';
import 'package:ai_text_editor/objectbox/recent_files.dart';
import 'package:ai_text_editor/src/rust/api/charts_api.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
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

class SpellCheckErrorNotifier extends Notifier<List<Errors>> {
  @override
  List<Errors> build() {
    return [];
  }

  changeSpellCheckError(List<Errors> errors) {
    state = errors;
  }
}

class EditorNotifier extends Notifier<EditorState> {
  late final QuillController quillController = QuillController.basic();
  late final ScrollController scrollController = ScrollController();
  late final _deltaToMarkdown = DeltaToMarkdown(customEmbedHandlers: {
    customTableEmbedType: customTableEmbedToMarkdown,
    customRollEmbedType: customRollEmbedToMarkdown,
    customImageEmbedType: customImageEmbedToMarkdown,
    customRefEmbedType: customImageEmbedToMarkdown,
    customFormularEmbedType: customFormularEmbedToMarkdown,
  });
  late final _mdDocument = md.Document(encodeHtml: false);
  late final _mdToDelta = MarkdownToDelta(markdownDocument: _mdDocument);
  late final FocusNode focusNode = FocusNode();
  late final ObxDatabase database = ObxDatabase.db;
  StreamController<String> quillTextChangeController =
      StreamController<String>.broadcast();

  Stream<String> get quillTextChangeStream => quillTextChangeController.stream;

  @override
  EditorState build() {
    quillController.onSelectionChanged = (selection) {
      // print("${selection.start} -> ${selection.end}");
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
    quillController.document.changes.listen((event) async {
      // ref.read(editorNotifierProvider.notifier).getText();
      quillTextChangeController.add(getText());
      changeSavedStatus(false);
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

  /// 调整滚动条位置
  void _changeCurrentPosition(double p) {
    ref.read(currentPositionProvider.notifier).changePosition(p);
  }

  /// 获取当前编辑器文本
  String getPlainText() {
    return quillController.document.toPlainText();
  }

  Future<void> spellCheck() async {
    if (GlobalModel.model == null) {
      ToastUtils.error(null, title: "请先选择模型");
      return;
    }
    final s = getPlainText();
    if (s.trim() == "") {
      ToastUtils.error(null, title: "请先输入文本");
      return;
    }
    setLoading(true);

    final prompt = APPConfig.spellCheckPrompt.replaceAll("{text}", s);
    core.ChatMessage message = core.ChatMessage(
        role: "user",
        content: prompt,
        createAt: DateTime.now().millisecondsSinceEpoch);

    final res = await GlobalModel.model!.chat([message]);
    setLoading(false);

    try {
      final r = res.replaceFirst("```json", "").replaceAll("```", "");
      final model = JsonErrorModel.fromJson(jsonDecode(r));
      ref
          .read(spellCheckErrorNotifierProvider.notifier)
          .changeSpellCheckError(model.errors ?? []);
      if (!state.showSpellCheck) toggleSpellCheck();
    } catch (_) {
      ToastUtils.error(null, title: " spell check error");
    }
  }

  void highlightText(String targetText) {
    final matches = quillController.document.search(targetText);
    if (matches.isEmpty) {
      return;
    }

    /// TODO: FIXME: 如果有多个一样targetText存在问题，只能显示第一个
    int start = matches[0];
    int length = targetText.length;

    quillController.updateSelection(
        TextSelection(
          baseOffset: start,
          extentOffset: start + length,
        ),
        ChangeSource.local);
  }

  void removeHighlight() {
    quillController.moveCursorToEnd();
  }

  void replaceCertainText(String targetText, String replaceText) {
    final matches = quillController.document.search(targetText);
    if (matches.isEmpty) {
      return;
    }

    int start = matches[0];
    int length = targetText.length;
    quillController.replaceText(start, length, replaceText, null);
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

  /// change dice
  void changeDice(Map data) {
    try {
      quillController.replaceText(
          quillController.selection.baseOffset,
          1,
          CustomRollEmbed(customRollEmbedType, jsonEncode(data)),
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

  /// change formular
  void changeFormular(Map data) {
    try {
      quillController.replaceText(
          quillController.selection.baseOffset,
          1,
          CustomFormularEmbed(customFormularEmbedType, jsonEncode(data)),
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
    RecentFiles recentFiles = RecentFiles(path: filepath)
      ..createdAt = DateTime.now().millisecondsSinceEpoch
      ..lastEdited = DateTime.now().millisecondsSinceEpoch;

    await database.recentFilesBox.putAsync(recentFiles);
  }

  /// 更新文件
  Future updateDoc(String filepath) async {
    final query = database.recentFilesBox
        .query(RecentFiles_.path.equals(filepath))
        .build();
    final files = query.find();
    if (files.isNotEmpty) {
      files.first.lastEdited = DateTime.now().millisecondsSinceEpoch;
      await database.recentFilesBox.putAsync(files.first);
    }
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
      state = state.copyWith(
          showAI: open, showSpellCheck: open ? false : state.showSpellCheck);
    }
  }

  /// 切换拼写检查
  void toggleSpellCheck() {
    state = state.copyWith(
        showSpellCheck: !state.showSpellCheck,
        showAI: !state.showSpellCheck ? false : state.showAI);
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

  /// mind graph
  Future mindGraph(BuildContext context) async {
    String text = quillController.getPlainText();
    if (text.trim().length < 20 && text.trim().isNotEmpty) {
      ToastUtils.info(context, title: "Text too short");
      return;
    }

    if (text.trim().isEmpty) {
      text = quillController.document.toPlainText();
      if (text.trim().length < 20) {
        ToastUtils.info(context, title: "Text too short");
        return;
      }
    }
    setLoading(true);

    final prompt = APPConfig.mindGraphPrompt.replaceAll("{text}", text);
    core.ChatMessage message = core.ChatMessage(
        role: "user",
        content: prompt,
        createAt: DateTime.now().millisecondsSinceEpoch);

    final res = await GlobalModel.model!.chat([message]);
    logger.d("res: $res");
    setLoading(false);
    try {
      final r = res.replaceFirst("```json", "").replaceAll("```", "");
      final _ = jsonDecode(r);

      final img = await newMindGraphChart(value: r, width: 1080, height: 720);
      if (img != null) {
        showGeneralDialog(
            barrierDismissible: true,
            barrierLabel: "Close",
            // ignore: use_build_context_synchronously
            context: context,
            pageBuilder: (c, _, __) {
              return Center(
                child: AlertDialog(
                  title: Text("Mind Graph"),
                  content: SizedBox(
                    width: 600,
                    height: 400,
                    child: Image.memory(img),
                  ),
                ),
              );
            });
      }
    } catch (_) {
      ToastUtils.error(null, title: "generate error");
    }
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

final spellCheckErrorNotifierProvider =
    NotifierProvider<SpellCheckErrorNotifier, List<Errors>>(
        SpellCheckErrorNotifier.new);

import 'dart:convert';

import 'package:ai_packages_core/ai_packages_core.dart';
import 'package:ai_text_editor/components/dialogs/select_or_input_file_url_dialog.dart';
import 'package:ai_text_editor/data/models/ai_model.dart';
import 'package:ai_text_editor/embeds/formular/formular_embed.dart';
import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:ai_text_editor/embeds/ref/ref_embed.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';
import 'package:ai_text_editor/embeds/table/table_embed.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'slash_command_menu.dart';

class SlashCommandHandler {
  SlashCommandHandler._();

  static WidgetRef? _ref;
  static OverlayEntry? _overlayEntry;
  static int _slashPosition = -1;
  static String _currentFilter = '';
  static int _selectedIndex = 0;
  static List<SlashCommandItem> _items = [];
  static QuillController? _controller;
  static BuildContext? _context;

  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  static List<SlashCommandItem> _buildItems(
      BuildContext context, QuillController controller) {
    return [
      // ========== AI Commands ==========
      SlashCommandItem(
        command: 'ai',
        description: 'Ask AI to help you write',
        icon: Icons.auto_awesome,
        category: SlashCommandCategory.ai,
        keywords: ['assistant', 'help', 'chat', '助手'],
        onSelect: () => _handleAi(context, controller),
      ),
      SlashCommandItem(
        command: 'rewrite',
        description: 'Rewrite selected text with AI',
        icon: Icons.edit_note,
        category: SlashCommandCategory.ai,
        keywords: ['改写', 'rephrase', 'modify', '重写'],
        onSelect: () => _handleRewrite(context, controller),
      ),
      SlashCommandItem(
        command: 'expand',
        description: 'Expand and elaborate on selected text',
        icon: Icons.expand,
        category: SlashCommandCategory.ai,
        keywords: ['扩展', 'elaborate', 'extend', '扩写'],
        onSelect: () => _handleExpand(context, controller),
      ),
      SlashCommandItem(
        command: 'summarize',
        description: 'Summarize selected text',
        icon: Icons.summarize,
        category: SlashCommandCategory.ai,
        keywords: ['摘要', 'summary', 'brief', '总结'],
        onSelect: () => _handleSummarize(context, controller),
      ),
      SlashCommandItem(
        command: 'translate',
        description: 'Translate selected text',
        icon: Icons.translate,
        category: SlashCommandCategory.ai,
        keywords: ['翻译', 'translation', '中文', 'english'],
        onSelect: () => _handleTranslate(context, controller),
      ),

      // ========== Format Commands ==========
      SlashCommandItem(
        command: 'h1',
        description: 'Heading 1',
        icon: Icons.title,
        category: SlashCommandCategory.format,
        keywords: ['heading', 'title', '标题'],
        onSelect: () => _handleHeading(controller, 1),
      ),
      SlashCommandItem(
        command: 'h2',
        description: 'Heading 2',
        icon: Icons.title,
        category: SlashCommandCategory.format,
        keywords: ['heading', 'subtitle', '标题'],
        onSelect: () => _handleHeading(controller, 2),
      ),
      SlashCommandItem(
        command: 'h3',
        description: 'Heading 3',
        icon: Icons.title,
        category: SlashCommandCategory.format,
        keywords: ['heading', '标题'],
        onSelect: () => _handleHeading(controller, 3),
      ),
      SlashCommandItem(
        command: 'quote',
        description: 'Block quote',
        icon: Icons.format_quote,
        category: SlashCommandCategory.format,
        keywords: ['blockquote', '引用', 'citation'],
        onSelect: () => _handleBlockQuote(controller),
      ),
      SlashCommandItem(
        command: 'code',
        description: 'Code block',
        icon: Icons.code,
        category: SlashCommandCategory.format,
        keywords: ['codeblock', '代码', 'programming'],
        onSelect: () => _handleCodeBlock(controller),
      ),
      SlashCommandItem(
        command: 'divider',
        description: 'Horizontal divider',
        icon: Icons.horizontal_rule,
        category: SlashCommandCategory.format,
        keywords: ['line', 'separator', '分割线'],
        onSelect: () => _handleDivider(controller),
      ),

      // ========== Insert Commands ==========
      SlashCommandItem(
        command: 'table',
        description: 'Insert a table',
        icon: Icons.table_chart,
        category: SlashCommandCategory.insert,
        keywords: ['grid', '表格', 'spreadsheet'],
        onSelect: () => _handleTable(context, controller),
      ),
      SlashCommandItem(
        command: 'image',
        description: 'Insert an image',
        icon: Icons.image,
        category: SlashCommandCategory.insert,
        keywords: ['picture', 'photo', '图片', '图像'],
        onSelect: () => _handleImage(context, controller),
      ),
      SlashCommandItem(
        command: 'link',
        description: 'Insert a reference link',
        icon: Icons.link,
        category: SlashCommandCategory.insert,
        keywords: ['url', 'href', '链接', 'reference'],
        onSelect: () => _handleRef(context, controller),
      ),
      SlashCommandItem(
        command: 'formular',
        description: 'Insert a math formula',
        icon: Icons.functions,
        category: SlashCommandCategory.insert,
        keywords: ['math', 'equation', '公式', 'latex'],
        onSelect: () => _handleFormular(context, controller),
      ),
      SlashCommandItem(
        command: 'roll',
        description: 'Insert a dice roll',
        icon: Icons.casino,
        category: SlashCommandCategory.insert,
        keywords: ['dice', 'random', '骰子'],
        onSelect: () => _handleRoll(context, controller),
      ),

      // ========== List Commands ==========
      SlashCommandItem(
        command: 'bullet',
        description: 'Bullet list',
        icon: Icons.format_list_bulleted,
        category: SlashCommandCategory.list,
        keywords: ['unordered', '无序列表', 'ul'],
        onSelect: () => _handleList(controller, Attribute.ul),
      ),
      SlashCommandItem(
        command: 'number',
        description: 'Numbered list',
        icon: Icons.format_list_numbered,
        category: SlashCommandCategory.list,
        keywords: ['ordered', '有序列表', 'ol'],
        onSelect: () => _handleList(controller, Attribute.ol),
      ),
      SlashCommandItem(
        command: 'checklist',
        description: 'Checklist / Todo list',
        icon: Icons.checklist,
        category: SlashCommandCategory.list,
        keywords: ['todo', 'checkbox', '待办', '清单'],
        onSelect: () => _handleChecklist(controller),
      ),
    ];
  }

  /// 获取过滤后的项目
  static List<SlashCommandItem> get _filteredItems {
    final filter = _currentFilter.toLowerCase();
    if (filter.isEmpty) return _items;
    return _items.where((item) {
      return item.command.toLowerCase().contains(filter) ||
          item.description.toLowerCase().contains(filter) ||
          item.keywords.any((k) => k.toLowerCase().contains(filter));
    }).toList();
  }

  /// 显示斜杠命令菜单
  static void show({
    required BuildContext context,
    required QuillController controller,
    required Offset position,
    required int slashPosition,
  }) {
    hide();
    _slashPosition = slashPosition;
    _currentFilter = '';
    _selectedIndex = 0;
    _controller = controller;
    _context = context;
    _items = _buildItems(context, controller);

    _overlayEntry = OverlayEntry(
      builder: (_) => _SlashCommandOverlayWidget(
        position: position,
        items: _items,
        filter: _currentFilter,
        selectedIndex: _selectedIndex,
        onDismiss: hide,
        onIndexChange: (index) {
          _selectedIndex = index;
          _overlayEntry?.markNeedsBuild();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 处理键盘事件 - 从编辑器调用
  static bool handleKeyEvent(KeyEvent event) {
    if (!isShowing) return false;
    if (event is! KeyDownEvent) return false;

    final filtered = _filteredItems;
    if (filtered.isEmpty) return false;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _selectedIndex = (_selectedIndex + 1) % filtered.length;
      _overlayEntry?.markNeedsBuild();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
      _overlayEntry?.markNeedsBuild();
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      if (_selectedIndex < filtered.length) {
        filtered[_selectedIndex].onSelect();
      }
      return true;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      hide();
      return true;
    }

    return false;
  }

  /// 更新过滤文本
  static void updateFilter(String filter) {
    _currentFilter = filter;
    _selectedIndex = 0; // 重置选中索引
    _overlayEntry?.markNeedsBuild();
  }

  /// 隐藏菜单
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _slashPosition = -1;
    _currentFilter = '';
    _selectedIndex = 0;
    _controller = null;
    _context = null;
  }

  static bool get isShowing => _overlayEntry != null;
  static int get slashPosition => _slashPosition;

  /// 删除斜杠和过滤文本
  static void _clearSlashCommand(QuillController controller) {
    if (_slashPosition >= 0) {
      final currentPos = controller.selection.baseOffset;
      final length = currentPos - _slashPosition;
      if (length > 0) {
        controller.replaceText(_slashPosition, length, '', null);
        controller.updateSelection(
          TextSelection.collapsed(offset: _slashPosition),
          ChangeSource.local,
        );
      }
    }
    hide();
  }

  /// 获取选中的文本
  static String _getSelectedText(QuillController controller) {
    final selection = controller.selection;
    if (selection.isCollapsed) return '';
    return controller.document.getPlainText(
      selection.start,
      selection.end - selection.start,
    );
  }

  // ========== AI Command Handlers ==========

  static void _handleAi(BuildContext context, QuillController controller) {
    _clearSlashCommand(controller);
    _ref?.read(editorNotifierProvider.notifier).toggleAi();
  }

  static Future<void> _handleRewrite(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);

    final selectedText = _getSelectedText(controller);
    if (selectedText.isEmpty) {
      ToastUtils.info(context, title: '请先选择要改写的文本');
      return;
    }

    await _processAICommand(
      context: context,
      controller: controller,
      selectedText: selectedText,
      prompt: '''请改写以下文本，保持原意但使用不同的表达方式，使其更加流畅自然：

$selectedText

请直接输出改写后的文本，不要添加任何解释。''',
      operationName: '改写',
    );
  }

  static Future<void> _handleExpand(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);

    final selectedText = _getSelectedText(controller);
    if (selectedText.isEmpty) {
      ToastUtils.info(context, title: '请先选择要扩展的文本');
      return;
    }

    await _processAICommand(
      context: context,
      controller: controller,
      selectedText: selectedText,
      prompt: '''请扩展以下文本，添加更多细节、例子或解释，使内容更加丰富完整：

$selectedText

请直接输出扩展后的文本，不要添加任何解释。''',
      operationName: '扩展',
    );
  }

  static Future<void> _handleSummarize(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);

    final selectedText = _getSelectedText(controller);
    if (selectedText.isEmpty) {
      ToastUtils.info(context, title: '请先选择要总结的文本');
      return;
    }

    await _processAICommand(
      context: context,
      controller: controller,
      selectedText: selectedText,
      prompt: '''请总结以下文本的核心内容，提取关键要点：

$selectedText

请直接输出摘要内容，不要添加任何解释。''',
      operationName: '总结',
      replaceSelection: false,
    );
  }

  static Future<void> _handleTranslate(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);

    final selectedText = _getSelectedText(controller);
    if (selectedText.isEmpty) {
      ToastUtils.info(context, title: '请先选择要翻译的文本');
      return;
    }

    // Show language selection dialog
    final targetLanguage = await showDialog<String>(
      context: context,
      builder: (ctx) => _TranslateLanguageDialog(),
    );

    if (targetLanguage == null) return;

    await _processAICommand(
      context: context,
      controller: controller,
      selectedText: selectedText,
      prompt: '''请将以下文本翻译成$targetLanguage，保持原文的语气和风格：

$selectedText

请直接输出翻译结果，不要添加任何解释。''',
      operationName: '翻译',
    );
  }

  /// 通用 AI 命令处理
  static Future<void> _processAICommand({
    required BuildContext context,
    required QuillController controller,
    required String selectedText,
    required String prompt,
    required String operationName,
    bool replaceSelection = true,
  }) async {
    if (GlobalModel.model == null) {
      ToastUtils.error(context, title: '请先配置 AI 模型');
      return;
    }

    _ref?.read(editorNotifierProvider.notifier).setLoading(true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final messages = [
        ChatMessage(
          role: 'user',
          content: prompt,
          createAt: now,
        ),
      ];

      final result = await GlobalModel.model!.chat(messages);

      if (result.isNotEmpty) {
        if (replaceSelection) {
          // Replace selected text with AI result
          final selection = controller.selection;
          if (!selection.isCollapsed) {
            controller.replaceText(
              selection.start,
              selection.end - selection.start,
              result.trim(),
              null,
            );
          }
        } else {
          // Insert after selection
          final insertPosition = controller.selection.end;
          controller.replaceText(
            insertPosition,
            0,
            '\n\n${result.trim()}',
            null,
          );
        }
      }
    } catch (e) {
      ToastUtils.error(context, title: '$operationName失败: $e');
    } finally {
      _ref?.read(editorNotifierProvider.notifier).setLoading(false);
    }
  }

  // ========== Insert Command Handlers ==========

  static void _handleTable(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);
    final result = await showGeneralDialog(
      barrierColor: Colors.white.withValues(alpha: 0.9),
      barrierDismissible: true,
      barrierLabel: 'table dialog',
      context: context,
      pageBuilder: (c, _, __) {
        return Center(
          child: _SimpleTableDialog(),
        );
      },
    );

    if (result != null && result is Map) {
      result['uuid'] = const Uuid().v4();
      final block = CustomTableEmbed(customTableEmbedType, jsonEncode(result));
      controller.replaceText(controller.selection.baseOffset, 0, block, null);
      _ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
            '\n',
            controller.selection.copyWith(
              baseOffset: controller.selection.baseOffset + 1,
            ),
          );
    }
  }

  static void _handleImage(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);
    final result = await showGeneralDialog(
      barrierColor: Colors.transparent,
      context: context,
      pageBuilder: (c, _, __) {
        return const Center(child: SelectOrInputFileUrlDialog());
      },
    );

    if (result != null && result is Map) {
      result['uuid'] = const Uuid().v4();
      final block = CustomImageEmbed(customImageEmbedType, jsonEncode(result));
      controller.replaceText(controller.selection.baseOffset, 0, block, null);
      _ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
            '\n',
            controller.selection.copyWith(
              baseOffset: controller.selection.baseOffset + 1,
            ),
          );
    }
  }

  static void _handleRef(
      BuildContext context, QuillController controller) async {
    _clearSlashCommand(controller);
    final result = await showGeneralDialog(
      barrierColor: Colors.transparent,
      context: context,
      pageBuilder: (c, _, __) {
        return const Center(
          child: SelectOrInputFileUrlDialog(
            showDescriptionInput: true,
            label: 'files',
            extensions: [],
          ),
        );
      },
    );

    if (result != null && result is Map) {
      result['uuid'] = const Uuid().v4();
      final block = CustomRefEmbed(customRefEmbedType, jsonEncode(result));
      controller.replaceText(controller.selection.baseOffset, 0, block, null);
      _ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
            '\n',
            controller.selection.copyWith(
              baseOffset: controller.selection.baseOffset + 1,
            ),
          );
    }
  }

  static void _handleFormular(
      BuildContext context, QuillController controller) {
    _clearSlashCommand(controller);
    final uuid = const Uuid().v4();
    final m = {'uuid': uuid, 'formular': '## Edit your formula here'};
    final block = CustomFormularEmbed(customFormularEmbedType, jsonEncode(m));
    controller.replaceText(controller.selection.baseOffset, 0, block, null);
  }

  static void _handleRoll(BuildContext context, QuillController controller) {
    _clearSlashCommand(controller);
    final uuid = const Uuid().v4();
    final block = CustomRollEmbed(
      customRollEmbedType,
      jsonEncode({'uuid': uuid}),
    );
    controller.replaceText(controller.selection.baseOffset, 0, block, null);
  }

  // ========== Format Command Handlers ==========

  static void _handleHeading(QuillController controller, int level) {
    _clearSlashCommand(controller);
    final attr = Attribute.header;
    controller.formatSelection(Attribute.fromKeyValue(attr.key, level));
  }

  static void _handleList(QuillController controller, Attribute attr) {
    _clearSlashCommand(controller);
    controller.formatSelection(attr);
  }

  static void _handleChecklist(QuillController controller) {
    _clearSlashCommand(controller);
    controller.formatSelection(Attribute.unchecked);
  }

  static void _handleBlockQuote(QuillController controller) {
    _clearSlashCommand(controller);
    controller.formatSelection(Attribute.blockQuote);
  }

  static void _handleCodeBlock(QuillController controller) {
    _clearSlashCommand(controller);
    controller.formatSelection(Attribute.codeBlock);
  }

  static void _handleDivider(QuillController controller) {
    _clearSlashCommand(controller);
    controller.replaceText(
      controller.selection.baseOffset,
      0,
      '───────────────────────────────\n',
      null,
    );
  }
}

/// Overlay Widget
class _SlashCommandOverlayWidget extends StatelessWidget {
  const _SlashCommandOverlayWidget({
    required this.position,
    required this.items,
    required this.filter,
    required this.selectedIndex,
    required this.onDismiss,
    required this.onIndexChange,
  });

  final Offset position;
  final List<SlashCommandItem> items;
  final String filter;
  final int selectedIndex;
  final VoidCallback onDismiss;
  final ValueChanged<int> onIndexChange;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 计算菜单位置，确保不超出屏幕
    double left = position.dx;
    double top = position.dy + 24;

    // 如果右边超出屏幕，向左调整
    if (left + 310 > screenSize.width) {
      left = screenSize.width - 320;
    }
    // 如果下边超出屏幕，向上显示
    if (top + 370 > screenSize.height) {
      top = position.dy - 380;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left.clamp(10, screenSize.width - 320),
          top: top.clamp(10, screenSize.height - 380),
          child: SlashCommandMenu(
            items: items,
            filterText: filter,
            selectedIndex: selectedIndex,
            onDismiss: onDismiss,
            onIndexChange: onIndexChange,
          ),
        ),
      ],
    );
  }
}

/// 简单的表格创建对话框
class _SimpleTableDialog extends StatefulWidget {
  @override
  State<_SimpleTableDialog> createState() => _SimpleTableDialogState();
}

class _SimpleTableDialogState extends State<_SimpleTableDialog> {
  int rows = 3;
  int cols = 3;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insert Table',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Rows: '),
                Expanded(
                  child: Slider(
                    value: rows.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: rows.toString(),
                    onChanged: (v) => setState(() => rows = v.toInt()),
                  ),
                ),
                Text('$rows'),
              ],
            ),
            Row(
              children: [
                const Text('Cols: '),
                Expanded(
                  child: Slider(
                    value: cols.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: cols.toString(),
                    onChanged: (v) => setState(() => cols = v.toInt()),
                  ),
                ),
                Text('$cols'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'rowCount': rows,
                      'colCount': cols,
                      'values': List.filled(rows * cols, ''),
                    });
                  },
                  child: const Text('Insert'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 翻译语言选择对话框
class _TranslateLanguageDialog extends StatelessWidget {
  final List<Map<String, String>> _languages = const [
    {'code': '中文', 'name': '中文 (Chinese)'},
    {'code': 'English', 'name': 'English'},
    {'code': '日本語', 'name': '日本語 (Japanese)'},
    {'code': '한국어', 'name': '한국어 (Korean)'},
    {'code': 'Français', 'name': 'Français (French)'},
    {'code': 'Deutsch', 'name': 'Deutsch (German)'},
    {'code': 'Español', 'name': 'Español (Spanish)'},
    {'code': 'Português', 'name': 'Português (Portuguese)'},
    {'code': 'Русский', 'name': 'Русский (Russian)'},
    {'code': 'Italiano', 'name': 'Italiano (Italian)'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择目标语言'),
      content: SizedBox(
        width: 280,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final lang = _languages[index];
            return ListTile(
              title: Text(lang['name']!),
              onTap: () => Navigator.pop(context, lang['code']),
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hoverColor: Colors.blue.withValues(alpha: 0.1),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

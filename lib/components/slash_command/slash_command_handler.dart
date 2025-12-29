import 'dart:convert';

import 'package:ai_text_editor/components/dialogs/select_or_input_file_url_dialog.dart';
import 'package:ai_text_editor/embeds/formular/formular_embed.dart';
import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:ai_text_editor/embeds/ref/ref_embed.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';
import 'package:ai_text_editor/embeds/table/table_embed.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
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
      SlashCommandItem(
        command: 'ai',
        description: 'Ask AI to help you write',
        icon: Icons.auto_awesome,
        onSelect: () => _handleAi(context, controller),
      ),
      SlashCommandItem(
        command: 'table',
        description: 'Insert a table',
        icon: Icons.table_chart,
        onSelect: () => _handleTable(context, controller),
      ),
      SlashCommandItem(
        command: 'image',
        description: 'Insert an image',
        icon: Icons.image,
        onSelect: () => _handleImage(context, controller),
      ),
      SlashCommandItem(
        command: 'ref',
        description: 'Insert a reference link',
        icon: Icons.link,
        onSelect: () => _handleRef(context, controller),
      ),
      SlashCommandItem(
        command: 'formular',
        description: 'Insert a math formula',
        icon: Icons.functions,
        onSelect: () => _handleFormular(context, controller),
      ),
      SlashCommandItem(
        command: 'roll',
        description: 'Insert a dice roll',
        icon: Icons.casino,
        onSelect: () => _handleRoll(context, controller),
      ),
      SlashCommandItem(
        command: 'h1',
        description: 'Heading 1',
        icon: Icons.title,
        onSelect: () => _handleHeading(controller, 1),
      ),
      SlashCommandItem(
        command: 'h2',
        description: 'Heading 2',
        icon: Icons.title,
        onSelect: () => _handleHeading(controller, 2),
      ),
      SlashCommandItem(
        command: 'h3',
        description: 'Heading 3',
        icon: Icons.title,
        onSelect: () => _handleHeading(controller, 3),
      ),
      SlashCommandItem(
        command: 'bullet',
        description: 'Bullet list',
        icon: Icons.format_list_bulleted,
        onSelect: () => _handleList(controller, Attribute.ul),
      ),
      SlashCommandItem(
        command: 'number',
        description: 'Numbered list',
        icon: Icons.format_list_numbered,
        onSelect: () => _handleList(controller, Attribute.ol),
      ),
      SlashCommandItem(
        command: 'quote',
        description: 'Block quote',
        icon: Icons.format_quote,
        onSelect: () => _handleBlockQuote(controller),
      ),
      SlashCommandItem(
        command: 'code',
        description: 'Code block',
        icon: Icons.code,
        onSelect: () => _handleCodeBlock(controller),
      ),
      SlashCommandItem(
        command: 'divider',
        description: 'Horizontal divider',
        icon: Icons.horizontal_rule,
        onSelect: () => _handleDivider(controller),
      ),
    ];
  }

  /// 获取过滤后的项目
  static List<SlashCommandItem> get _filteredItems {
    final filter = _currentFilter.toLowerCase();
    return _items
        .where((item) =>
            item.command.toLowerCase().contains(filter) ||
            item.description.toLowerCase().contains(filter))
        .toList();
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

  // ========== Command Handlers ==========

  static void _handleAi(BuildContext context, QuillController controller) {
    _clearSlashCommand(controller);
    _ref?.read(editorNotifierProvider.notifier).toggleAi();
  }

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

  static void _handleHeading(QuillController controller, int level) {
    _clearSlashCommand(controller);
    final attr = Attribute.header;
    controller.formatSelection(Attribute.fromKeyValue(attr.key, level));
  }

  static void _handleList(QuillController controller, Attribute attr) {
    _clearSlashCommand(controller);
    controller.formatSelection(attr);
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
    if (left + 280 > screenSize.width) {
      left = screenSize.width - 290;
    }
    // 如果下边超出屏幕，向上显示
    if (top + 300 > screenSize.height) {
      top = position.dy - 310;
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
          left: left.clamp(10, screenSize.width - 290),
          top: top.clamp(10, screenSize.height - 310),
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

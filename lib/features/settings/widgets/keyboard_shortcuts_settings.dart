import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/settings_notifier.dart';

/// 快捷键动作定义
class ShortcutAction {
  final String id;
  final String label;
  final String description;
  final String defaultShortcut;

  const ShortcutAction({
    required this.id,
    required this.label,
    required this.description,
    required this.defaultShortcut,
  });
}

/// 预定义的快捷键动作
const List<ShortcutAction> _shortcutActions = [
  ShortcutAction(
    id: 'openAIAssistant',
    label: '打开 AI 助手',
    description: '打开全局 AI 助手面板',
    defaultShortcut: 'Cmd+J',
  ),
  ShortcutAction(
    id: 'globalSearch',
    label: '全局搜索',
    description: '打开跨工作空间搜索',
    defaultShortcut: 'Cmd+Shift+F',
  ),
  ShortcutAction(
    id: 'newDocument',
    label: '新建文档',
    description: '在当前工作空间创建新文档',
    defaultShortcut: 'Cmd+N',
  ),
  ShortcutAction(
    id: 'saveDocument',
    label: '保存文档',
    description: '保存当前文档',
    defaultShortcut: 'Cmd+S',
  ),
  ShortcutAction(
    id: 'toggleFocusMode',
    label: '专注模式',
    description: '切换编辑器专注模式',
    defaultShortcut: 'Cmd+Shift+Enter',
  ),
  ShortcutAction(
    id: 'toggleSidebar',
    label: '切换侧边栏',
    description: '显示或隐藏侧边栏',
    defaultShortcut: 'Cmd+B',
  ),
];

/// 快捷键设置组件
/// 查看和自定义键盘快捷键
/// Requirements: 8.4
class KeyboardShortcutsSettings extends ConsumerStatefulWidget {
  const KeyboardShortcutsSettings({super.key});

  @override
  ConsumerState<KeyboardShortcutsSettings> createState() =>
      _KeyboardShortcutsSettingsState();
}

class _KeyboardShortcutsSettingsState
    extends ConsumerState<KeyboardShortcutsSettings> {
  String? _editingActionId;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 说明
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Platform.isMacOS
                      ? '点击快捷键可以自定义。使用 Cmd、Option、Shift、Ctrl 作为修饰键。'
                      : '点击快捷键可以自定义。使用 Ctrl、Alt、Shift 作为修饰键。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 快捷键列表
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // 表头
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '操作',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        '描述',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        '快捷键',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // 快捷键行
              ..._shortcutActions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                final isLast = index == _shortcutActions.length - 1;
                final currentShortcut = settings.keyboardShortcuts[action.id] ??
                    _convertShortcutForPlatform(action.defaultShortcut);

                return _buildShortcutRow(
                  action: action,
                  currentShortcut: currentShortcut,
                  isEditing: _editingActionId == action.id,
                  isLast: isLast,
                  onEdit: () {
                    setState(() {
                      _editingActionId = action.id;
                    });
                  },
                  onSave: (shortcut) {
                    notifier.setKeyboardShortcut(action.id, shortcut);
                    setState(() {
                      _editingActionId = null;
                    });
                  },
                  onCancel: () {
                    setState(() {
                      _editingActionId = null;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 重置按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showResetConfirmDialog(notifier),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('重置为默认'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade300),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _convertShortcutForPlatform(String shortcut) {
    if (Platform.isMacOS) {
      return shortcut;
    } else {
      return shortcut.replaceAll('Cmd', 'Ctrl').replaceAll('Option', 'Alt');
    }
  }

  Widget _buildShortcutRow({
    required ShortcutAction action,
    required String currentShortcut,
    required bool isEditing,
    required bool isLast,
    required VoidCallback onEdit,
    required ValueChanged<String> onSave,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              action.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              action.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: isEditing
                ? _ShortcutEditor(
                    initialShortcut: currentShortcut,
                    onSave: onSave,
                    onCancel: onCancel,
                  )
                : InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        currentShortcut,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmDialog(SettingsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置快捷键'),
        content: const Text('确定要将所有快捷键重置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('重置'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.resetKeyboardShortcuts();
    }
  }
}

/// 快捷键编辑器
class _ShortcutEditor extends StatefulWidget {
  final String initialShortcut;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const _ShortcutEditor({
    required this.initialShortcut,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ShortcutEditor> createState() => _ShortcutEditorState();
}

class _ShortcutEditorState extends State<_ShortcutEditor> {
  final FocusNode _focusNode = FocusNode();
  String _currentShortcut = '';
  bool _isRecording = true;

  @override
  void initState() {
    super.initState();
    _currentShortcut = widget.initialShortcut;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                _isRecording ? '按下快捷键...' : _currentShortcut,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: _isRecording ? Colors.grey.shade500 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => widget.onSave(_currentShortcut),
              child: Icon(Icons.check, size: 16, color: Colors.green.shade600),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: widget.onCancel,
              child: Icon(Icons.close, size: 16, color: Colors.red.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // 忽略单独的修饰键
    if (event.logicalKey == LogicalKeyboardKey.meta ||
        event.logicalKey == LogicalKeyboardKey.control ||
        event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.shift) {
      return;
    }

    // 构建快捷键字符串
    final parts = <String>[];

    if (HardwareKeyboard.instance.isMetaPressed) {
      parts.add(Platform.isMacOS ? 'Cmd' : 'Win');
    }
    if (HardwareKeyboard.instance.isControlPressed) {
      parts.add('Ctrl');
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      parts.add(Platform.isMacOS ? 'Option' : 'Alt');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      parts.add('Shift');
    }

    // 获取按键名称
    final keyLabel = _getKeyLabel(event.logicalKey);
    if (keyLabel != null) {
      parts.add(keyLabel);
    }

    if (parts.isNotEmpty) {
      setState(() {
        _currentShortcut = parts.join('+');
        _isRecording = false;
      });
    }
  }

  String? _getKeyLabel(LogicalKeyboardKey key) {
    // 字母键
    if (key.keyLabel.length == 1 && key.keyLabel.isNotEmpty) {
      return key.keyLabel.toUpperCase();
    }

    // 特殊键映射
    final specialKeys = {
      LogicalKeyboardKey.enter: 'Enter',
      LogicalKeyboardKey.escape: 'Esc',
      LogicalKeyboardKey.backspace: 'Backspace',
      LogicalKeyboardKey.delete: 'Delete',
      LogicalKeyboardKey.tab: 'Tab',
      LogicalKeyboardKey.space: 'Space',
      LogicalKeyboardKey.arrowUp: '↑',
      LogicalKeyboardKey.arrowDown: '↓',
      LogicalKeyboardKey.arrowLeft: '←',
      LogicalKeyboardKey.arrowRight: '→',
      LogicalKeyboardKey.home: 'Home',
      LogicalKeyboardKey.end: 'End',
      LogicalKeyboardKey.pageUp: 'PageUp',
      LogicalKeyboardKey.pageDown: 'PageDown',
      LogicalKeyboardKey.f1: 'F1',
      LogicalKeyboardKey.f2: 'F2',
      LogicalKeyboardKey.f3: 'F3',
      LogicalKeyboardKey.f4: 'F4',
      LogicalKeyboardKey.f5: 'F5',
      LogicalKeyboardKey.f6: 'F6',
      LogicalKeyboardKey.f7: 'F7',
      LogicalKeyboardKey.f8: 'F8',
      LogicalKeyboardKey.f9: 'F9',
      LogicalKeyboardKey.f10: 'F10',
      LogicalKeyboardKey.f11: 'F11',
      LogicalKeyboardKey.f12: 'F12',
    };

    return specialKeys[key];
  }
}

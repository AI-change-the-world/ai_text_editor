import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/settings_notifier.dart';

/// 通用设置组件
/// 配置应用的基本行为和编辑器选项
/// Requirements: 8.1
class GeneralSettings extends ConsumerWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 语言设置
        _buildSettingsCard(
          title: '语言',
          icon: Icons.language,
          children: [
            _buildDropdownSetting(
              label: '界面语言',
              description: '选择应用界面显示的语言',
              value: settings.language,
              items: const [
                DropdownMenuItem(value: 'zh_CN', child: Text('简体中文')),
                DropdownMenuItem(value: 'zh_TW', child: Text('繁體中文')),
                DropdownMenuItem(value: 'en_US', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setLanguage(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 编辑器设置
        _buildSettingsCard(
          title: '编辑器',
          icon: Icons.edit_note,
          children: [
            _buildSwitchSetting(
              label: '自动保存',
              description: '自动保存文档更改',
              value: settings.autoSave,
              onChanged: (value) => notifier.setAutoSave(value),
            ),
            if (settings.autoSave) ...[
              const Divider(height: 24),
              _buildSliderSetting(
                label: '自动保存间隔',
                description: '每 ${settings.autoSaveInterval} 秒自动保存一次',
                value: settings.autoSaveInterval.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                onChanged: (value) =>
                    notifier.setAutoSaveInterval(value.round()),
              ),
            ],
            const Divider(height: 24),
            _buildSwitchSetting(
              label: '显示字数统计',
              description: '在编辑器底部显示字数和字符数',
              value: settings.showWordCount,
              onChanged: (value) => notifier.setShowWordCount(value),
            ),
            const Divider(height: 24),
            _buildSwitchSetting(
              label: '拼写检查',
              description: '启用拼写检查功能',
              value: settings.spellCheck,
              onChanged: (value) => notifier.setSpellCheck(value),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI 助手设置
        _buildSettingsCard(
          title: 'AI 助手',
          icon: Icons.smart_toy,
          children: [
            _buildSwitchSetting(
              label: '显示悬浮按钮',
              description: '在界面右下角显示 AI 助手快捷按钮',
              value: settings.showFloatingButton,
              onChanged: (value) => notifier.setShowFloatingButton(value),
            ),
            const Divider(height: 24),
            _buildDropdownSetting(
              label: '默认搜索范围',
              description: '打开 AI 助手时的默认知识库搜索范围',
              value: settings.defaultSearchScope,
              items: const [
                DropdownMenuItem(value: 'current', child: Text('当前工作空间')),
                DropdownMenuItem(value: 'all', child: Text('所有工作空间')),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.setDefaultSearchScope(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // 设置项
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting<T>({
    required String label,
    required String description,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${value.round()}s',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.blue.shade600,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.blue.shade600,
            overlayColor: Colors.blue.shade100,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

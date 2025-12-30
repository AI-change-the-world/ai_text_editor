import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../i18n/translations.g.dart';
import '../../../utils/app_theme.dart';
import '../notifiers/settings_notifier.dart';

/// 通用设置组件
/// 配置应用的基本行为和编辑器选项
/// Requirements: 8.1
class GeneralSettings extends ConsumerWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 语言设置
        _buildSettingsCard(
          title: t.settings.language,
          icon: Icons.language,
          colors: colors,
          children: [
            _buildDropdownSetting(
              label: t.settings.language,
              description: t.settings.languageDesc,
              value: LocaleSettings.currentLocale,
              colors: colors,
              items: [
                DropdownMenuItem(
                    value: AppLocale.zh, child: const Text('简体中文')),
                DropdownMenuItem(
                    value: AppLocale.en, child: const Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  LocaleSettings.setLocale(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 编辑器设置
        _buildSettingsCard(
          title: t.settings.editor,
          icon: Icons.edit_note,
          colors: colors,
          children: [
            _buildSwitchSetting(
              label: t.settings.autoSave,
              description: t.settings.autoSaveDesc,
              value: settings.autoSave,
              colors: colors,
              onChanged: (value) => notifier.setAutoSave(value),
            ),
            if (settings.autoSave) ...[
              Divider(height: 24, color: colors.divider),
              _buildSliderSetting(
                label: t.settings.autoSaveInterval,
                description: t.settings
                    .autoSaveIntervalDesc(seconds: settings.autoSaveInterval),
                value: settings.autoSaveInterval.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                colors: colors,
                onChanged: (value) =>
                    notifier.setAutoSaveInterval(value.round()),
              ),
            ],
            Divider(height: 24, color: colors.divider),
            _buildSwitchSetting(
              label: t.settings.showWordCount,
              description: t.settings.showWordCountDesc,
              value: settings.showWordCount,
              colors: colors,
              onChanged: (value) => notifier.setShowWordCount(value),
            ),
            Divider(height: 24, color: colors.divider),
            _buildSwitchSetting(
              label: t.settings.spellCheck,
              description: t.settings.spellCheckDesc,
              value: settings.spellCheck,
              colors: colors,
              onChanged: (value) => notifier.setSpellCheck(value),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI 助手设置
        _buildSettingsCard(
          title: t.settings.aiAssistant,
          icon: Icons.smart_toy,
          colors: colors,
          children: [
            _buildSwitchSetting(
              label: t.settings.showFloatingButton,
              description: t.settings.showFloatingButtonDesc,
              value: settings.showFloatingButton,
              colors: colors,
              onChanged: (value) => notifier.setShowFloatingButton(value),
            ),
            Divider(height: 24, color: colors.divider),
            _buildDropdownSetting(
              label: t.settings.defaultSearchScope,
              description: t.settings.defaultSearchScopeDesc,
              value: settings.defaultSearchScope,
              colors: colors,
              items: [
                DropdownMenuItem(
                    value: 'current', child: Text(t.settings.currentWorkspace)),
                DropdownMenuItem(
                    value: 'all', child: Text(t.settings.allWorkspaces)),
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
    required AppColors colors,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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
    required AppColors colors,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: colors.primary,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting<T>({
    required String label,
    required String description,
    required T value,
    required AppColors colors,
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
            dropdownColor: colors.dialogBackground,
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
    required AppColors colors,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
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
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.border,
            thumbColor: colors.primary,
            overlayColor: colors.primaryLight,
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

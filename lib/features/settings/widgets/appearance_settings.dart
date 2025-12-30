import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_theme.dart';
import '../notifiers/settings_notifier.dart';

/// 外观设置组件
/// 自定义应用的外观，包括主题、字体和颜色
/// Requirements: 8.3
class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主题设置
        _buildSettingsCard(
          title: '主题',
          icon: Icons.dark_mode,
          colors: colors,
          children: [
            _buildThemeModeSelector(settings, notifier, colors),
          ],
        ),
        const SizedBox(height: 16),

        // 字体设置
        _buildSettingsCard(
          title: '字体',
          icon: Icons.text_fields,
          colors: colors,
          children: [
            _buildFontFamilySelector(settings, notifier, colors),
            const SizedBox(height: 20),
            _buildFontSizeSlider(settings, notifier, colors),
            const SizedBox(height: 20),
            _buildLineHeightSlider(settings, notifier, colors),
          ],
        ),
        const SizedBox(height: 16),

        // 预览
        _buildPreviewCard(settings, colors),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(
      AppSettings settings, SettingsNotifier notifier, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主题模式',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '选择应用的颜色主题',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeOption(
              icon: Icons.brightness_auto,
              label: '跟随系统',
              isSelected: settings.themeMode == ThemeMode.system,
              colors: colors,
              onTap: () => notifier.setThemeMode(ThemeMode.system),
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              icon: Icons.light_mode,
              label: '浅色',
              isSelected: settings.themeMode == ThemeMode.light,
              colors: colors,
              onTap: () => notifier.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              icon: Icons.dark_mode,
              label: '深色',
              isSelected: settings.themeMode == ThemeMode.dark,
              colors: colors,
              onTap: () => notifier.setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryLight : colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontFamilySelector(
      AppSettings settings, SettingsNotifier notifier, AppColors colors) {
    const fonts = [('System', '系统默认'), ('HanSansCN', '思源黑体'), ('song', '手写体')];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '字体',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '选择编辑器使用的字体',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fonts.map((font) {
            final isSelected = settings.fontFamily == font.$1;
            return ChoiceChip(
              label: Text(font.$2),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.setFontFamily(font.$1);
                }
              },
              selectedColor: colors.primaryLight,
              backgroundColor: colors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(
      AppSettings settings, SettingsNotifier notifier, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '字体大小',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${settings.fontSize.round()}px',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '调整编辑器的默认字体大小',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('12', style: TextStyle(fontSize: 12, color: colors.textHint)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: colors.border,
                  thumbColor: colors.primary,
                  overlayColor: colors.primaryLight,
                ),
                child: Slider(
                  value: settings.fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  onChanged: (value) => notifier.setFontSize(value),
                ),
              ),
            ),
            Text('24', style: TextStyle(fontSize: 12, color: colors.textHint)),
          ],
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider(
      AppSettings settings, SettingsNotifier notifier, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '行高',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              settings.lineHeight.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '调整文本行之间的间距',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('1.0', style: TextStyle(fontSize: 12, color: colors.textHint)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: colors.primary,
                  inactiveTrackColor: colors.border,
                  thumbColor: colors.primary,
                  overlayColor: colors.primaryLight,
                ),
                child: Slider(
                  value: settings.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  onChanged: (value) => notifier.setLineHeight(value),
                ),
              ),
            ),
            Text('2.5', style: TextStyle(fontSize: 12, color: colors.textHint)),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewCard(AppSettings settings, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  '预览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              '这是一段预览文本，用于展示当前的字体设置效果。\n\n'
              'This is a preview text to demonstrate the current font settings.\n\n'
              '你可以调整上方的设置来查看实时效果。',
              style: TextStyle(
                fontFamily: settings.fontFamily == 'System'
                    ? null
                    : settings.fontFamily,
                fontSize: settings.fontSize,
                height: settings.lineHeight,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

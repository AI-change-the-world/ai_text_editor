import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/general_settings.dart';
import '../widgets/ai_model_settings.dart';
import '../widgets/appearance_settings.dart';
import '../widgets/keyboard_shortcuts_settings.dart';
import '../widgets/settings_import_export.dart';

/// 设置页面分类
enum SettingsCategory {
  general('通用', Icons.settings),
  aiModel('AI 模型', Icons.smart_toy),
  appearance('外观', Icons.palette),
  shortcuts('快捷键', Icons.keyboard),
  importExport('导入/导出', Icons.import_export);

  final String label;
  final IconData icon;

  const SettingsCategory(this.label, this.icon);
}

/// 设置页面
/// 显示分类配置选项
/// Requirements: 8.1
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  SettingsCategory _selectedCategory = SettingsCategory.general;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Row(
        children: [
          // 左侧分类导航
          _buildCategoryNav(),
          // 右侧设置内容
          Expanded(
            child: _buildSettingsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNav() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: SettingsCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return _buildCategoryItem(category, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(SettingsCategory category, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              category.icon,
              size: 20,
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue.shade700 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类标题
            Text(
              _selectedCategory.label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getCategoryDescription(_selectedCategory),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            // 设置内容
            _buildCategoryContent(),
          ],
        ),
      ),
    );
  }

  String _getCategoryDescription(SettingsCategory category) {
    switch (category) {
      case SettingsCategory.general:
        return '配置应用的基本行为和编辑器选项';
      case SettingsCategory.aiModel:
        return '管理 AI 模型配置，包括提供商、API 密钥和参数';
      case SettingsCategory.appearance:
        return '自定义应用的外观，包括主题、字体和颜色';
      case SettingsCategory.shortcuts:
        return '查看和自定义键盘快捷键';
      case SettingsCategory.importExport:
        return '导入或导出应用设置';
    }
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case SettingsCategory.general:
        return const GeneralSettings();
      case SettingsCategory.aiModel:
        return const AIModelSettings();
      case SettingsCategory.appearance:
        return const AppearanceSettings();
      case SettingsCategory.shortcuts:
        return const KeyboardShortcutsSettings();
      case SettingsCategory.importExport:
        return const SettingsImportExport();
    }
  }
}

/// 显示设置页面
Future<void> showSettingsPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const SettingsPage(),
    ),
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 应用设置状态
/// Requirements: 8.1
class AppSettings {
  // 通用设置
  final String language;
  final bool autoSave;
  final int autoSaveInterval; // 秒
  final bool showWordCount;
  final bool spellCheck;

  // 外观设置
  final ThemeMode themeMode;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;

  // 快捷键设置
  final Map<String, String> keyboardShortcuts;

  // AI 助手设置
  final bool showFloatingButton;
  final String defaultSearchScope;

  const AppSettings({
    this.language = 'zh_CN',
    this.autoSave = true,
    this.autoSaveInterval = 30,
    this.showWordCount = true,
    this.spellCheck = false,
    this.themeMode = ThemeMode.system,
    this.fontFamily = 'System',
    this.fontSize = 16.0,
    this.lineHeight = 1.6,
    this.keyboardShortcuts = const {},
    this.showFloatingButton = true,
    this.defaultSearchScope = 'current',
  });

  AppSettings copyWith({
    String? language,
    bool? autoSave,
    int? autoSaveInterval,
    bool? showWordCount,
    bool? spellCheck,
    ThemeMode? themeMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    Map<String, String>? keyboardShortcuts,
    bool? showFloatingButton,
    String? defaultSearchScope,
  }) {
    return AppSettings(
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      showWordCount: showWordCount ?? this.showWordCount,
      spellCheck: spellCheck ?? this.spellCheck,
      themeMode: themeMode ?? this.themeMode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      keyboardShortcuts: keyboardShortcuts ?? this.keyboardShortcuts,
      showFloatingButton: showFloatingButton ?? this.showFloatingButton,
      defaultSearchScope: defaultSearchScope ?? this.defaultSearchScope,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'autoSave': autoSave,
      'autoSaveInterval': autoSaveInterval,
      'showWordCount': showWordCount,
      'spellCheck': spellCheck,
      'themeMode': themeMode.index,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'keyboardShortcuts': keyboardShortcuts,
      'showFloatingButton': showFloatingButton,
      'defaultSearchScope': defaultSearchScope,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: json['language'] as String? ?? 'zh_CN',
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveInterval: json['autoSaveInterval'] as int? ?? 30,
      showWordCount: json['showWordCount'] as bool? ?? true,
      spellCheck: json['spellCheck'] as bool? ?? false,
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
      fontFamily: json['fontFamily'] as String? ?? 'System',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      keyboardShortcuts:
          Map<String, String>.from(json['keyboardShortcuts'] as Map? ?? {}),
      showFloatingButton: json['showFloatingButton'] as bool? ?? true,
      defaultSearchScope: json['defaultSearchScope'] as String? ?? 'current',
    );
  }

  /// 获取默认快捷键
  static Map<String, String> get defaultShortcuts => {
        'openAIAssistant': 'Cmd+J',
        'globalSearch': 'Cmd+Shift+F',
        'newDocument': 'Cmd+N',
        'saveDocument': 'Cmd+S',
        'toggleFocusMode': 'Cmd+Shift+Enter',
        'toggleSidebar': 'Cmd+B',
      };
}

/// 设置状态管理
/// Requirements: 8.1
class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsFileName = 'app_settings.json';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<File> _getSettingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_settingsFileName');
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      // 加载失败时使用默认设置
      state = const AppSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      final jsonStr = jsonEncode(state.toJson());
      await file.writeAsString(jsonStr);
    } catch (e) {
      // 保存失败时忽略
    }
  }

  /// 更新语言
  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  /// 更新自动保存设置
  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSave: enabled);
    await _saveSettings();
  }

  /// 更新自动保存间隔
  Future<void> setAutoSaveInterval(int seconds) async {
    state = state.copyWith(autoSaveInterval: seconds);
    await _saveSettings();
  }

  /// 更新显示字数统计
  Future<void> setShowWordCount(bool show) async {
    state = state.copyWith(showWordCount: show);
    await _saveSettings();
  }

  /// 更新拼写检查
  Future<void> setSpellCheck(bool enabled) async {
    state = state.copyWith(spellCheck: enabled);
    await _saveSettings();
  }

  /// 更新主题模式
  /// Requirements: 8.3
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// 更新字体
  Future<void> setFontFamily(String fontFamily) async {
    state = state.copyWith(fontFamily: fontFamily);
    await _saveSettings();
  }

  /// 更新字体大小
  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _saveSettings();
  }

  /// 更新行高
  Future<void> setLineHeight(double height) async {
    state = state.copyWith(lineHeight: height);
    await _saveSettings();
  }

  /// 更新快捷键
  /// Requirements: 8.4
  Future<void> setKeyboardShortcut(String action, String shortcut) async {
    final shortcuts = Map<String, String>.from(state.keyboardShortcuts);
    shortcuts[action] = shortcut;
    state = state.copyWith(keyboardShortcuts: shortcuts);
    await _saveSettings();
  }

  /// 重置快捷键为默认值
  Future<void> resetKeyboardShortcuts() async {
    state = state.copyWith(keyboardShortcuts: AppSettings.defaultShortcuts);
    await _saveSettings();
  }

  /// 更新悬浮按钮显示
  Future<void> setShowFloatingButton(bool show) async {
    state = state.copyWith(showFloatingButton: show);
    await _saveSettings();
  }

  /// 更新默认搜索范围
  Future<void> setDefaultSearchScope(String scope) async {
    state = state.copyWith(defaultSearchScope: scope);
    await _saveSettings();
  }

  /// 导出设置
  /// Requirements: 8.5
  Future<String> exportSettings() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/settings_export.json');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(state.toJson());
    await file.writeAsString(jsonStr);
    return file.path;
  }

  /// 导入设置
  /// Requirements: 8.6
  Future<bool> importSettings(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      state = AppSettings.fromJson(json);
      await _saveSettings();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 重置所有设置
  Future<void> resetAllSettings() async {
    state = const AppSettings();
    await _saveSettings();
  }
}

/// 设置 Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

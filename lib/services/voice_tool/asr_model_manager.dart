import 'dart:convert';

import 'package:flutter/services.dart';

import 'local_asr_service.dart';

/// ASR 配置管理器
/// 负责从 config.json 加载 ASR 配置
class ASRConfigManager {
  ASRConfigManager._();

  static ASRConfigManager? _instance;
  static ASRConfigManager get instance => _instance ??= ASRConfigManager._();

  ASRConfig? _config;

  /// 获取当前配置
  ASRConfig? get config => _config;

  /// 是否已加载配置
  bool get isLoaded => _config != null;

  /// 从 assets/config.json 加载配置
  Future<ASRConfig> loadConfig() async {
    if (_config != null) return _config!;

    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _config = ASRConfig.fromJson(json);
      return _config!;
    } catch (e) {
      throw Exception('Failed to load ASR config from assets/config.json: $e');
    }
  }

  /// 从 Map 加载配置（用于测试或动态配置）
  ASRConfig loadFromMap(Map<String, dynamic> json) {
    _config = ASRConfig.fromJson(json);
    return _config!;
  }

  /// 检查配置是否有效
  ConfigValidationResult validateConfig() {
    if (_config == null) {
      return ConfigValidationResult(
        isValid: false,
        errors: ['Config not loaded'],
      );
    }

    final errors = <String>[];

    // 检查是否至少配置了一种模型
    if (!_config!.hasOnlineModel && !_config!.hasOfflineModel) {
      errors.add(
          'No ASR model configured. Please set either online or offline model in config.json');
    }

    // 如果配置了非流式模型但没有 VAD，给出警告
    if (_config!.hasOfflineModel && !_config!.hasVad) {
      errors.add(
          'Offline model configured but VAD is missing. VAD is recommended for offline recognition.');
    }

    return ConfigValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      hasOnlineModel: _config!.hasOnlineModel,
      hasOfflineModel: _config!.hasOfflineModel,
      hasVad: _config!.hasVad,
    );
  }

  /// 清除配置
  void clearConfig() {
    _config = null;
  }
}

/// 配置验证结果
class ConfigValidationResult {
  const ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
    this.hasOnlineModel = false,
    this.hasOfflineModel = false,
    this.hasVad = false,
  });

  final bool isValid;
  final List<String> errors;
  final bool hasOnlineModel;
  final bool hasOfflineModel;
  final bool hasVad;

  @override
  String toString() {
    return 'ConfigValidationResult(isValid: $isValid, errors: $errors, '
        'hasOnlineModel: $hasOnlineModel, hasOfflineModel: $hasOfflineModel, hasVad: $hasVad)';
  }
}

/// Translate tool for the AI Agent system
///
/// This tool enables text translation using AI models with
/// automatic language detection and format preservation.
/// Requirements: 7.8
library;

import 'package:ai_packages_core/ai_packages_core.dart';

import '../../data/models/ai_model.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Translate tool implementation.
///
/// Translates text between languages:
/// - Automatic source language detection
/// - Support for multiple target languages
/// - Preserves formatting and semantics
///
/// Requirements: 7.8
class TranslateTool implements ITool {
  /// Creates a new [TranslateTool].
  TranslateTool();

  /// Creates a [TranslateTool] using default configuration.
  factory TranslateTool.withDefaults() {
    return TranslateTool();
  }

  @override
  String get name => 'translate';

  @override
  String get description => '''
翻译文本：
- 自动检测源语言
- 支持多种目标语言（中文、英文、日文、韩文、法文、德文、西班牙文等）
- 保持格式和语义
- 可选择正式或非正式语气
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'text': {
            'type': 'string',
            'description': '要翻译的文本',
          },
          'target_language': {
            'type': 'string',
            'description':
                '目标语言代码或名称 (如: zh, en, ja, ko, fr, de, es, 或 中文, English, 日本語)',
          },
          'source_language': {
            'type': 'string',
            'description': '源语言代码（可选，默认自动检测）',
          },
          'tone': {
            'type': 'string',
            'enum': ['formal', 'informal', 'neutral'],
            'default': 'neutral',
            'description': '翻译语气：formal(正式)、informal(非正式)、neutral(中性)',
          },
          'preserve_formatting': {
            'type': 'boolean',
            'default': true,
            'description': '是否保留原文格式（如换行、列表等）',
          },
        },
        'required': ['text', 'target_language'],
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      // Check if AI model is available
      if (GlobalModel.model == null) {
        return ToolResult.failure('AI模型未配置，无法进行翻译');
      }

      // Extract parameters
      final text = parameters['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return ToolResult.failure('翻译文本不能为空');
      }

      final targetLanguage = parameters['target_language'] as String?;
      if (targetLanguage == null || targetLanguage.trim().isEmpty) {
        return ToolResult.failure('目标语言不能为空');
      }

      final sourceLanguage = parameters['source_language'] as String?;
      final toneStr = (parameters['tone'] as String?) ?? 'neutral';
      final preserveFormatting =
          (parameters['preserve_formatting'] as bool?) ?? true;

      // Normalize language names
      final targetLangName = _normalizeLanguage(targetLanguage);
      final sourceLangName =
          sourceLanguage != null ? _normalizeLanguage(sourceLanguage) : null;

      // Build translation prompt
      final prompt = _buildTranslationPrompt(
        text: text,
        targetLanguage: targetLangName,
        sourceLanguage: sourceLangName,
        tone: toneStr,
        preserveFormatting: preserveFormatting,
      );

      // Call AI model
      final now = DateTime.now().millisecondsSinceEpoch;
      final messages = [
        ChatMessage(
          role: 'system',
          content: _getSystemPrompt(),
          createAt: now,
        ),
        ChatMessage(
          role: 'user',
          content: prompt,
          createAt: now,
        ),
      ];

      final translation = await GlobalModel.model!.chat(messages);

      // Build response
      final responseData = {
        'translation': translation.trim(),
        'target_language': targetLangName,
        'source_language': sourceLangName ?? 'auto-detected',
        'tone': toneStr,
        'original_text': text,
        'original_length': text.length,
        'translation_length': translation.trim().length,
      };

      return ToolResult.success(data: responseData);
    } catch (e) {
      return ToolResult.failure('翻译失败: $e');
    }
  }

  String _getSystemPrompt() {
    return '''你是一个专业的翻译助手。请准确翻译用户提供的文本，注意：
1. 保持原文的语义和语气
2. 使用自然流畅的目标语言表达
3. 保留专有名词、技术术语的准确性
4. 如果原文有格式（如列表、换行），请保持格式
5. 只输出翻译结果，不要添加解释或注释''';
  }

  String _buildTranslationPrompt({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    required String tone,
    required bool preserveFormatting,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('请将以下文本翻译成$targetLanguage。');

    if (sourceLanguage != null) {
      buffer.writeln('源语言：$sourceLanguage');
    }

    // Add tone instruction
    switch (tone) {
      case 'formal':
        buffer.writeln('请使用正式、书面的语气。');
        break;
      case 'informal':
        buffer.writeln('请使用轻松、口语化的语气。');
        break;
      case 'neutral':
      default:
        buffer.writeln('请使用中性、自然的语气。');
        break;
    }

    if (preserveFormatting) {
      buffer.writeln('请保留原文的格式（换行、列表等）。');
    }

    buffer.writeln();
    buffer.writeln('原文：');
    buffer.writeln(text);

    return buffer.toString();
  }

  /// Normalize language code or name to a readable name
  String _normalizeLanguage(String language) {
    final lower = language.toLowerCase().trim();

    // Language code mappings
    final codeToName = {
      'zh': '中文',
      'zh-cn': '简体中文',
      'zh-tw': '繁体中文',
      'zh-hk': '繁体中文',
      'en': 'English',
      'en-us': 'American English',
      'en-gb': 'British English',
      'ja': '日本語',
      'ko': '한국어',
      'fr': 'Français',
      'de': 'Deutsch',
      'es': 'Español',
      'pt': 'Português',
      'ru': 'Русский',
      'it': 'Italiano',
      'ar': 'العربية',
      'hi': 'हिन्दी',
      'th': 'ไทย',
      'vi': 'Tiếng Việt',
      'nl': 'Nederlands',
      'pl': 'Polski',
      'tr': 'Türkçe',
      'sv': 'Svenska',
      'da': 'Dansk',
      'no': 'Norsk',
      'fi': 'Suomi',
      'el': 'Ελληνικά',
      'he': 'עברית',
      'id': 'Bahasa Indonesia',
      'ms': 'Bahasa Melayu',
    };

    // Check if it's a known code
    if (codeToName.containsKey(lower)) {
      return codeToName[lower]!;
    }

    // Common name variations
    final nameVariations = {
      'chinese': '中文',
      'english': 'English',
      'japanese': '日本語',
      'korean': '한국어',
      'french': 'Français',
      'german': 'Deutsch',
      'spanish': 'Español',
      'portuguese': 'Português',
      'russian': 'Русский',
      'italian': 'Italiano',
      'arabic': 'العربية',
      'hindi': 'हिन्दी',
      'thai': 'ไทย',
      'vietnamese': 'Tiếng Việt',
      'dutch': 'Nederlands',
      'polish': 'Polski',
      'turkish': 'Türkçe',
      'swedish': 'Svenska',
      'danish': 'Dansk',
      'norwegian': 'Norsk',
      'finnish': 'Suomi',
      'greek': 'Ελληνικά',
      'hebrew': 'עברית',
      'indonesian': 'Bahasa Indonesia',
      'malay': 'Bahasa Melayu',
      '中文': '中文',
      '英文': 'English',
      '日文': '日本語',
      '韩文': '한국어',
      '法文': 'Français',
      '德文': 'Deutsch',
      '西班牙文': 'Español',
    };

    if (nameVariations.containsKey(lower)) {
      return nameVariations[lower]!;
    }

    // Return as-is if not recognized
    return language;
  }
}

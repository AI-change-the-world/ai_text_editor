/// Summary tool for the AI Agent system
///
/// This tool enables text and document summarization using AI models.
/// Requirements: 7.6
library;

import 'package:ai_packages_core/ai_packages_core.dart';

import '../document_service.dart';
import '../../data/models/ai_model.dart';
import 'tool_interface.dart';
import 'tool_result.dart';

/// Summary style options
enum SummaryStyle {
  brief,
  detailed,
  bulletPoints,
}

/// Summary tool implementation.
///
/// Summarizes text or documents:
/// - Generate brief summaries
/// - Extract key points
/// - Support different summary styles
///
/// Requirements: 7.6
class SummaryTool implements ITool {
  final DocumentService? _documentService;

  /// Creates a new [SummaryTool].
  ///
  /// [documentService] - Optional document service for document summarization.
  SummaryTool({
    DocumentService? documentService,
  }) : _documentService = documentService;

  /// Creates a [SummaryTool] using singleton services.
  factory SummaryTool.withDefaults() {
    return SummaryTool(
      documentService: DocumentService.instance,
    );
  }

  @override
  String get name => 'summarize';

  @override
  String get description => '''
对文本或文档进行摘要：
- 生成简短摘要
- 提取关键要点
- 支持指定摘要长度和风格
- 可以直接提供文本或指定文档ID
''';

  @override
  Map<String, dynamic> get parametersSchema => {
        'type': 'object',
        'properties': {
          'text': {
            'type': 'string',
            'description': '要摘要的文本内容',
          },
          'document_id': {
            'type': 'string',
            'description': '要摘要的文档ID（与text二选一）',
          },
          'max_length': {
            'type': 'integer',
            'default': 200,
            'description': '摘要最大字数，默认200字',
          },
          'style': {
            'type': 'string',
            'enum': ['brief', 'detailed', 'bullet_points'],
            'default': 'brief',
            'description': '摘要风格：brief(简短)、detailed(详细)、bullet_points(要点列表)',
          },
          'language': {
            'type': 'string',
            'default': 'auto',
            'description': '输出语言，默认auto自动检测',
          },
        },
      };

  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    try {
      // Check if AI model is available
      if (GlobalModel.model == null) {
        return ToolResult.failure('AI模型未配置，无法生成摘要');
      }

      // Get text to summarize
      String? textToSummarize;
      String? documentId;
      String? documentTitle;

      if (parameters.containsKey('text') && parameters['text'] != null) {
        textToSummarize = parameters['text'] as String;
      } else if (parameters.containsKey('document_id') &&
          parameters['document_id'] != null) {
        documentId = parameters['document_id'] as String;

        if (_documentService == null) {
          return ToolResult.failure('文档服务不可用');
        }

        final document = await _documentService.getDocument(documentId);
        if (document == null) {
          return ToolResult.failure('文档不存在: $documentId');
        }

        documentTitle = document.title;
        final contentData =
            await _documentService.getDocumentContent(documentId);
        textToSummarize = contentData?.plainText;

        if (textToSummarize == null || textToSummarize.isEmpty) {
          return ToolResult.failure('文档内容为空');
        }
      }

      if (textToSummarize == null || textToSummarize.trim().isEmpty) {
        return ToolResult.failure('请提供要摘要的文本或文档ID');
      }

      // Parse parameters
      final maxLength = (parameters['max_length'] as int?) ?? 200;
      final styleStr = (parameters['style'] as String?) ?? 'brief';
      final language = (parameters['language'] as String?) ?? 'auto';
      final style = _parseStyle(styleStr);

      // Build prompt based on style
      final prompt = _buildSummaryPrompt(
        text: textToSummarize,
        maxLength: maxLength,
        style: style,
        language: language,
      );

      // Call AI model
      final now = DateTime.now().millisecondsSinceEpoch;
      final messages = [
        ChatMessage(
          role: 'system',
          content: _getSystemPrompt(style),
          createAt: now,
        ),
        ChatMessage(
          role: 'user',
          content: prompt,
          createAt: now,
        ),
      ];

      final summary = await GlobalModel.model!.chat(messages);

      // Build response
      final responseData = {
        'summary': summary.trim(),
        'style': styleStr,
        'max_length': maxLength,
        'original_length': textToSummarize.length,
        if (documentId != null) 'document_id': documentId,
        if (documentTitle != null) 'document_title': documentTitle,
      };

      // Include citation if summarizing a document
      List<SourceCitation>? citations;
      if (documentId != null) {
        citations = [
          SourceCitation(
            workspaceId: '', // Would need workspace lookup
            workspaceName: '',
            documentId: documentId,
            documentTitle: documentTitle ?? '',
            snippet: textToSummarize.length > 200
                ? '${textToSummarize.substring(0, 200)}...'
                : textToSummarize,
          ),
        ];
      }

      return ToolResult.success(
        data: responseData,
        citations: citations,
      );
    } catch (e) {
      return ToolResult.failure('摘要生成失败: $e');
    }
  }

  SummaryStyle _parseStyle(String style) {
    switch (style.toLowerCase()) {
      case 'detailed':
        return SummaryStyle.detailed;
      case 'bullet_points':
      case 'bulletpoints':
        return SummaryStyle.bulletPoints;
      case 'brief':
      default:
        return SummaryStyle.brief;
    }
  }

  String _getSystemPrompt(SummaryStyle style) {
    switch (style) {
      case SummaryStyle.brief:
        return '你是一个专业的文本摘要助手。请生成简洁、准确的摘要，抓住核心要点。';
      case SummaryStyle.detailed:
        return '你是一个专业的文本摘要助手。请生成详细的摘要，包含主要观点和支持细节。';
      case SummaryStyle.bulletPoints:
        return '你是一个专业的文本摘要助手。请以要点列表的形式提取关键信息，每个要点简洁明了。';
    }
  }

  String _buildSummaryPrompt({
    required String text,
    required int maxLength,
    required SummaryStyle style,
    required String language,
  }) {
    final styleInstruction = switch (style) {
      SummaryStyle.brief => '请生成一段简短的摘要',
      SummaryStyle.detailed => '请生成一段详细的摘要，包含主要观点和关键细节',
      SummaryStyle.bulletPoints => '请以要点列表的形式提取关键信息（使用 - 作为列表符号）',
    };

    final languageInstruction = language == 'auto'
        ? '请使用与原文相同的语言输出'
        : '请使用${_getLanguageName(language)}输出';

    return '''
$styleInstruction，控制在$maxLength字以内。$languageInstruction。

原文内容：
$text
''';
  }

  String _getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'zh':
      case 'chinese':
        return '中文';
      case 'en':
      case 'english':
        return '英文';
      case 'ja':
      case 'japanese':
        return '日文';
      case 'ko':
      case 'korean':
        return '韩文';
      case 'fr':
      case 'french':
        return '法文';
      case 'de':
      case 'german':
        return '德文';
      case 'es':
      case 'spanish':
        return '西班牙文';
      default:
        return code;
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'document_service.dart';

/// 搜索引擎类型
enum SearchEngine {
  google,
  bing,
  duckDuckGo,
}

/// 搜索结果项
class DeepSearchResultItem {
  /// 结果标题
  final String title;

  /// 结果 URL
  final String url;

  /// 结果摘要/描述
  final String snippet;

  /// 来源域名
  final String domain;

  /// 是否已提取内容
  bool isContentExtracted;

  /// 提取的内容
  String? extractedContent;

  DeepSearchResultItem({
    required this.title,
    required this.url,
    required this.snippet,
    required this.domain,
    this.isContentExtracted = false,
    this.extractedContent,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'snippet': snippet,
        'domain': domain,
        'isContentExtracted': isContentExtracted,
        'extractedContent': extractedContent,
      };

  factory DeepSearchResultItem.fromJson(Map<String, dynamic> json) {
    return DeepSearchResultItem(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      snippet: json['snippet'] ?? '',
      domain: json['domain'] ?? '',
      isContentExtracted: json['isContentExtracted'] ?? false,
      extractedContent: json['extractedContent'],
    );
  }
}

/// 深度搜索结果
class DeepSearchResult {
  /// 搜索查询
  final String query;

  /// 搜索引擎
  final SearchEngine engine;

  /// 搜索结果列表
  final List<DeepSearchResultItem> items;

  /// 搜索时间 (毫秒)
  final int searchTimeMs;

  /// 是否成功
  final bool success;

  /// 错误信息
  final String? error;

  DeepSearchResult({
    required this.query,
    required this.engine,
    required this.items,
    this.searchTimeMs = 0,
    this.success = true,
    this.error,
  });

  factory DeepSearchResult.error(
      String query, SearchEngine engine, String error) {
    return DeepSearchResult(
      query: query,
      engine: engine,
      items: [],
      success: false,
      error: error,
    );
  }
}

/// 内容提取结果
class ExtractedContent {
  /// 页面标题
  final String title;

  /// 主要文本内容
  final String content;

  /// 源 URL
  final String sourceUrl;

  /// 提取时间
  final DateTime extractedAt;

  /// 字数统计
  final int wordCount;

  /// 图片 URL 列表
  final List<String> imageUrls;

  ExtractedContent({
    required this.title,
    required this.content,
    required this.sourceUrl,
    required this.extractedAt,
    required this.wordCount,
    this.imageUrls = const [],
  });
}

/// 自动研究报告
class ResearchReport {
  /// 研究主题
  final String topic;

  /// 摘要
  final String summary;

  /// 来源列表
  final List<DeepSearchResultItem> sources;

  /// 生成时间
  final DateTime generatedAt;

  ResearchReport({
    required this.topic,
    required this.summary,
    required this.sources,
    required this.generatedAt,
  });
}

/// 深度搜索服务接口
/// Requirements: 6.1, 6.2, 6.4, 6.5
abstract class IDeepSearchService {
  /// 执行搜索引擎查询
  /// Requirements: 6.1, 6.2
  Future<DeepSearchResult> search(
    String query, {
    SearchEngine engine,
    int maxResults,
  });

  /// 提取网页内容
  /// Requirements: 6.4
  Future<ExtractedContent> extractContent(String url);

  /// 保存到知识库
  /// Requirements: 6.5
  Future<void> saveToKnowledgeBase(
    String workspaceId,
    ExtractedContent content, {
    List<String>? tags,
  });

  /// 自动研究模式 - 搜索并编译报告
  /// Requirements: 6.6
  Future<ResearchReport> autoResearch(
    String query, {
    int topN,
    SearchEngine engine,
  });

  /// 获取搜索引擎 URL
  String getSearchUrl(String query, SearchEngine engine);
}

/// 深度搜索服务实现
/// Requirements: 6.1, 6.2, 6.4, 6.5
class DeepSearchService implements IDeepSearchService {
  final IDocumentService _documentService;

  /// HTTP 客户端
  final http.Client _httpClient;

  /// 用户代理
  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  DeepSearchService(this._documentService, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static DeepSearchService? _instance;
  static DeepSearchService get instance {
    _instance ??= DeepSearchService(DocumentService.instance);
    return _instance!;
  }

  /// 重置单例 (用于测试)
  static void resetInstance() {
    _instance = null;
  }

  /// 获取搜索引擎 URL
  /// Requirements: 6.1
  @override
  String getSearchUrl(String query, SearchEngine engine) {
    final encodedQuery = Uri.encodeComponent(query);
    switch (engine) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=$encodedQuery';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=$encodedQuery';
      case SearchEngine.duckDuckGo:
        return 'https://duckduckgo.com/?q=$encodedQuery';
    }
  }

  /// 执行搜索引擎查询
  /// Requirements: 6.1, 6.2
  @override
  Future<DeepSearchResult> search(
    String query, {
    SearchEngine engine = SearchEngine.duckDuckGo,
    int maxResults = 10,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 使用 DuckDuckGo HTML 搜索 (不需要 API key)
      final results = await _searchDuckDuckGo(query, maxResults);

      stopwatch.stop();

      return DeepSearchResult(
        query: query,
        engine: engine,
        items: results,
        searchTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return DeepSearchResult.error(query, engine, e.toString());
    }
  }

  /// DuckDuckGo HTML 搜索
  Future<List<DeepSearchResultItem>> _searchDuckDuckGo(
    String query,
    int maxResults,
  ) async {
    final url =
        'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}';

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {
        'User-Agent': _userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      },
    );

    if (response.statusCode != 200) {
      throw DeepSearchException(
          'Search failed with status ${response.statusCode}');
    }

    return _parseDuckDuckGoResults(response.body, maxResults);
  }

  /// 解析 DuckDuckGo HTML 搜索结果
  List<DeepSearchResultItem> _parseDuckDuckGoResults(
      String html, int maxResults) {
    final results = <DeepSearchResultItem>[];

    // 使用正则表达式提取搜索结果
    // DuckDuckGo HTML 结果格式: <a class="result__a" href="...">title</a>
    final resultPattern = RegExp(
      r'<a[^>]*class="result__a"[^>]*href="([^"]*)"[^>]*>([^<]*)</a>',
      caseSensitive: false,
    );

    final snippetPattern = RegExp(
      r'<a[^>]*class="result__snippet"[^>]*>([^<]*(?:<[^>]*>[^<]*)*)</a>',
      caseSensitive: false,
    );

    final resultMatches = resultPattern.allMatches(html).toList();
    final snippetMatches = snippetPattern.allMatches(html).toList();

    for (int i = 0;
        i < resultMatches.length && results.length < maxResults;
        i++) {
      final match = resultMatches[i];
      var url = match.group(1) ?? '';
      final title = _decodeHtmlEntities(match.group(2) ?? '');

      // DuckDuckGo 使用重定向 URL，需要提取实际 URL
      if (url.contains('uddg=')) {
        final uddgMatch = RegExp(r'uddg=([^&]+)').firstMatch(url);
        if (uddgMatch != null) {
          url = Uri.decodeComponent(uddgMatch.group(1) ?? '');
        }
      }

      // 跳过无效 URL
      if (url.isEmpty || !url.startsWith('http')) continue;

      // 获取对应的摘要
      String snippet = '';
      if (i < snippetMatches.length) {
        snippet = _decodeHtmlEntities(
            _stripHtmlTags(snippetMatches[i].group(1) ?? ''));
      }

      // 提取域名
      final domain = _extractDomain(url);

      results.add(DeepSearchResultItem(
        title: title,
        url: url,
        snippet: snippet,
        domain: domain,
      ));
    }

    return results;
  }

  /// 解码 HTML 实体
  String _decodeHtmlEntities(String text) {
    // 常见 HTML 实体映射
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&nbsp;': ' ',
      '&ndash;': '–',
      '&mdash;': '—',
      '&lsquo;': ''',
      '&rsquo;': ''',
      '&ldquo;': '"',
      '&rdquo;': '"',
      '&hellip;': '…',
      '&copy;': '©',
      '&reg;': '®',
      '&trade;': '™',
    };

    var result = text;
    entities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    // 处理数字实体 &#123; 或 &#x7B;
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final code = int.tryParse(match.group(1) ?? '');
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        final code = int.tryParse(match.group(1) ?? '', radix: 16);
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      },
    );

    return result;
  }

  /// 移除 HTML 标签
  String _stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 提取域名
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return '';
    }
  }

  /// 提取网页内容
  /// Requirements: 6.4
  @override
  Future<ExtractedContent> extractContent(String url) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5,zh-CN;q=0.3',
        },
      );

      if (response.statusCode != 200) {
        throw ContentExtractionException(
            'Failed to fetch URL: ${response.statusCode}');
      }

      return _parseHtmlContent(response.body, url);
    } catch (e) {
      if (e is ContentExtractionException) rethrow;
      throw ContentExtractionException('Failed to extract content: $e');
    }
  }

  /// 解析 HTML 内容
  ExtractedContent _parseHtmlContent(String html, String sourceUrl) {
    // 提取标题
    final title = _extractTitle(html);

    // 提取主要内容
    final content = _extractMainContent(html);

    // 提取图片 URL
    final imageUrls = _extractImageUrls(html, sourceUrl);

    // 计算字数
    final wordCount = _countWords(content);

    return ExtractedContent(
      title: title,
      content: content,
      sourceUrl: sourceUrl,
      extractedAt: DateTime.now(),
      wordCount: wordCount,
      imageUrls: imageUrls,
    );
  }

  /// 提取页面标题
  String _extractTitle(String html) {
    // 尝试从 <title> 标签提取
    final titleMatch =
        RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false)
            .firstMatch(html);
    if (titleMatch != null) {
      return _decodeHtmlEntities(titleMatch.group(1)?.trim() ?? '');
    }

    // 尝试从 og:title 提取
    final ogTitleMatch = RegExp(
      r'<meta[^>]*property="og:title"[^>]*content="([^"]*)"',
      caseSensitive: false,
    ).firstMatch(html);
    if (ogTitleMatch != null) {
      return _decodeHtmlEntities(ogTitleMatch.group(1) ?? '');
    }

    // 尝试从 <h1> 提取
    final h1Match =
        RegExp(r'<h1[^>]*>([^<]*)</h1>', caseSensitive: false).firstMatch(html);
    if (h1Match != null) {
      return _decodeHtmlEntities(h1Match.group(1)?.trim() ?? '');
    }

    return 'Untitled';
  }

  /// 提取主要内容
  String _extractMainContent(String html) {
    // 移除脚本和样式
    var cleanHtml = html
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<noscript[^>]*>[\s\S]*?</noscript>', caseSensitive: false),
            '')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->', caseSensitive: false), '');

    // 尝试提取 article 或 main 内容
    String? mainContent;

    // 尝试 <article>
    final articleMatch = RegExp(
      r'<article[^>]*>([\s\S]*?)</article>',
      caseSensitive: false,
    ).firstMatch(cleanHtml);
    if (articleMatch != null) {
      mainContent = articleMatch.group(1);
    }

    // 尝试 <main>
    if (mainContent == null) {
      final mainMatch = RegExp(
        r'<main[^>]*>([\s\S]*?)</main>',
        caseSensitive: false,
      ).firstMatch(cleanHtml);
      if (mainMatch != null) {
        mainContent = mainMatch.group(1);
      }
    }

    // 尝试常见的内容容器
    if (mainContent == null) {
      final contentPatterns = [
        r'<div[^>]*class="[^"]*content[^"]*"[^>]*>([\s\S]*?)</div>',
        r'<div[^>]*id="content"[^>]*>([\s\S]*?)</div>',
        r'<div[^>]*class="[^"]*post[^"]*"[^>]*>([\s\S]*?)</div>',
        r'<div[^>]*class="[^"]*article[^"]*"[^>]*>([\s\S]*?)</div>',
      ];

      for (final pattern in contentPatterns) {
        final match =
            RegExp(pattern, caseSensitive: false).firstMatch(cleanHtml);
        if (match != null) {
          mainContent = match.group(1);
          break;
        }
      }
    }

    // 如果没有找到特定容器，使用 body
    if (mainContent == null) {
      final bodyMatch = RegExp(
        r'<body[^>]*>([\s\S]*?)</body>',
        caseSensitive: false,
      ).firstMatch(cleanHtml);
      if (bodyMatch != null) {
        mainContent = bodyMatch.group(1);
      }
    }

    mainContent ??= cleanHtml;

    // 移除导航、页脚等非内容元素
    mainContent = mainContent
        .replaceAll(
            RegExp(r'<nav[^>]*>[\s\S]*?</nav>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<header[^>]*>[\s\S]*?</header>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<footer[^>]*>[\s\S]*?</footer>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<aside[^>]*>[\s\S]*?</aside>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<form[^>]*>[\s\S]*?</form>', caseSensitive: false), '');

    // 转换为纯文本
    final text = _htmlToText(mainContent);

    // 清理多余空白
    return _cleanText(text);
  }

  /// HTML 转纯文本
  String _htmlToText(String html) {
    // 将块级元素转换为换行
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</tr>', caseSensitive: false), '\n');

    // 移除所有 HTML 标签
    text = _stripHtmlTags(text);

    // 解码 HTML 实体
    text = _decodeHtmlEntities(text);

    return text;
  }

  /// 清理文本
  String _cleanText(String text) {
    return text
        // 移除多余空白行
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        // 移除行首尾空白
        .split('\n')
        .map((line) => line.trim())
        .join('\n')
        // 移除首尾空白
        .trim();
  }

  /// 提取图片 URL
  List<String> _extractImageUrls(String html, String baseUrl) {
    final imageUrls = <String>[];
    final imgPattern = RegExp(r'<img[^>]*src="([^"]*)"', caseSensitive: false);

    for (final match in imgPattern.allMatches(html)) {
      var imgUrl = match.group(1) ?? '';
      if (imgUrl.isEmpty) continue;

      // 转换相对 URL 为绝对 URL
      if (!imgUrl.startsWith('http')) {
        try {
          final baseUri = Uri.parse(baseUrl);
          imgUrl = baseUri.resolve(imgUrl).toString();
        } catch (e) {
          continue;
        }
      }

      // 过滤小图标和跟踪像素
      if (_isValidImageUrl(imgUrl)) {
        imageUrls.add(imgUrl);
      }
    }

    return imageUrls;
  }

  /// 检查是否为有效的图片 URL
  bool _isValidImageUrl(String url) {
    final lowerUrl = url.toLowerCase();

    // 排除常见的图标和跟踪像素
    if (lowerUrl.contains('favicon') ||
        lowerUrl.contains('icon') ||
        lowerUrl.contains('logo') ||
        lowerUrl.contains('pixel') ||
        lowerUrl.contains('tracking') ||
        lowerUrl.contains('analytics') ||
        lowerUrl.contains('1x1') ||
        lowerUrl.contains('spacer')) {
      return false;
    }

    // 检查是否为图片扩展名
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  /// 计算字数
  int _countWords(String text) {
    if (text.isEmpty) return 0;

    // 中文字符计数
    final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
    final chineseCount = chineseRegex.allMatches(text).length;

    // 英文单词计数
    final englishText = text.replaceAll(chineseRegex, ' ');
    final englishWords = englishText
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && RegExp(r'[a-zA-Z]').hasMatch(word))
        .length;

    return chineseCount + englishWords;
  }

  /// 保存到知识库
  /// Requirements: 6.5
  @override
  Future<void> saveToKnowledgeBase(
    String workspaceId,
    ExtractedContent content, {
    List<String>? tags,
  }) async {
    // 构建 Markdown 格式的文档内容
    final markdownContent = _buildMarkdownDocument(content);

    // 创建文档
    await _documentService.createDocument(
      workspaceId,
      CreateDocumentRequest(
        title: content.title,
        initialContent: markdownContent,
        tags: [
          'web-import',
          ...(tags ?? []),
        ],
      ),
    );
  }

  /// 构建 Markdown 文档
  String _buildMarkdownDocument(ExtractedContent content) {
    final buffer = StringBuffer();

    // 标题
    buffer.writeln('# ${content.title}');
    buffer.writeln();

    // 元信息
    buffer
        .writeln('> **Source:** [${content.sourceUrl}](${content.sourceUrl})');
    buffer.writeln('> **Extracted:** ${content.extractedAt.toIso8601String()}');
    buffer.writeln('> **Word Count:** ${content.wordCount}');
    buffer.writeln();

    // 分隔线
    buffer.writeln('---');
    buffer.writeln();

    // 主要内容
    buffer.writeln(content.content);

    // 如果有图片，添加图片部分
    if (content.imageUrls.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## Images');
      buffer.writeln();
      for (final imageUrl in content.imageUrls.take(10)) {
        buffer.writeln('![]($imageUrl)');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// 自动研究模式
  /// Requirements: 6.6
  @override
  Future<ResearchReport> autoResearch(
    String query, {
    int topN = 5,
    SearchEngine engine = SearchEngine.duckDuckGo,
  }) async {
    // 1. 执行搜索
    final searchResult = await search(query, engine: engine, maxResults: topN);

    if (!searchResult.success || searchResult.items.isEmpty) {
      return ResearchReport(
        topic: query,
        summary: 'No results found for the query.',
        sources: [],
        generatedAt: DateTime.now(),
      );
    }

    // 2. 提取每个结果的内容
    final extractedContents = <ExtractedContent>[];
    for (final item in searchResult.items) {
      try {
        final content = await extractContent(item.url);
        extractedContents.add(content);
        item.isContentExtracted = true;
        item.extractedContent = content.content;
      } catch (e) {
        debugPrint('Failed to extract content from ${item.url}: $e');
      }
    }

    // 3. 编译摘要报告
    final summary = _compileResearchSummary(query, extractedContents);

    return ResearchReport(
      topic: query,
      summary: summary,
      sources: searchResult.items,
      generatedAt: DateTime.now(),
    );
  }

  /// 编译研究摘要
  String _compileResearchSummary(
    String topic,
    List<ExtractedContent> contents,
  ) {
    if (contents.isEmpty) {
      return 'No content could be extracted from the search results.';
    }

    final buffer = StringBuffer();
    buffer.writeln('# Research Report: $topic');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln(
        'This report compiles information from ${contents.length} sources.');
    buffer.writeln();

    for (int i = 0; i < contents.length; i++) {
      final content = contents[i];
      buffer.writeln('### Source ${i + 1}: ${content.title}');
      buffer.writeln();
      buffer.writeln('**URL:** ${content.sourceUrl}');
      buffer.writeln();

      // 提取前 500 字作为摘要
      final excerpt = content.content.length > 500
          ? '${content.content.substring(0, 500)}...'
          : content.content;
      buffer.writeln(excerpt);
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// 深度搜索异常
class DeepSearchException implements Exception {
  final String message;
  DeepSearchException(this.message);

  @override
  String toString() => 'DeepSearchException: $message';
}

/// 内容提取异常
class ContentExtractionException implements Exception {
  final String message;
  ContentExtractionException(this.message);

  @override
  String toString() => 'ContentExtractionException: $message';
}

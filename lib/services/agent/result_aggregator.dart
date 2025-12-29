/// Result aggregator for the AI Agent system
///
/// This file implements result aggregation and citation generation
/// for combining outputs from multiple tool executions.
/// Requirements: 4.5, 7.10
library;

import '../tools/tool_result.dart';
import 'task_plan.dart';

/// Aggregated result from multiple tool executions.
///
/// Contains the combined context, deduplicated citations,
/// and metadata about the aggregation.
///
/// Requirements: 7.10
class AggregatedResult {
  /// Combined context from all results.
  final String context;

  /// Deduplicated list of citations.
  final List<SourceCitation> citations;

  /// Number of successful tool executions.
  final int successCount;

  /// Number of failed tool executions.
  final int failureCount;

  /// Total number of results processed.
  final int totalCount;

  /// Whether any results were found.
  final bool hasResults;

  /// Summary of results by tool.
  final Map<String, ToolResultSummary> toolSummaries;

  /// Creates a new [AggregatedResult].
  const AggregatedResult({
    required this.context,
    required this.citations,
    required this.successCount,
    required this.failureCount,
    required this.totalCount,
    required this.hasResults,
    required this.toolSummaries,
  });

  /// Creates an empty result.
  factory AggregatedResult.empty() {
    return const AggregatedResult(
      context: '',
      citations: [],
      successCount: 0,
      failureCount: 0,
      totalCount: 0,
      hasResults: false,
      toolSummaries: {},
    );
  }

  /// Whether all executions were successful.
  bool get allSuccessful => failureCount == 0 && totalCount > 0;

  /// Whether any executions failed.
  bool get hasFailures => failureCount > 0;

  /// Success rate as a percentage.
  double get successRate =>
      totalCount > 0 ? (successCount / totalCount) * 100 : 0;
}

/// Summary of a single tool's results.
class ToolResultSummary {
  /// Name of the tool.
  final String toolName;

  /// Whether the execution was successful.
  final bool success;

  /// Number of results returned (for search tools).
  final int resultCount;

  /// Brief description of the result.
  final String summary;

  /// Creates a new [ToolResultSummary].
  const ToolResultSummary({
    required this.toolName,
    required this.success,
    required this.resultCount,
    required this.summary,
  });
}

/// Aggregates results from multiple tool executions.
///
/// The [ResultAggregator] handles:
/// - Combining context from multiple sources
/// - Deduplicating citations
/// - Generating summaries
/// - Formatting output for LLM consumption
///
/// Requirements: 4.5, 7.10
class ResultAggregator {
  /// Maximum length for context (to avoid token limits).
  final int maxContextLength;

  /// Maximum number of citations to include.
  final int maxCitations;

  /// Creates a new [ResultAggregator].
  ResultAggregator({
    this.maxContextLength = 8000,
    this.maxCitations = 10,
  });

  /// Aggregates results from a task plan.
  ///
  /// [plan] - The executed task plan with results.
  ///
  /// Returns an [AggregatedResult] with combined context and citations.
  AggregatedResult aggregateFromPlan(TaskPlan plan) {
    final results = plan.results;
    if (results.isEmpty) {
      return AggregatedResult.empty();
    }

    final contextParts = <String>[];
    final allCitations = <SourceCitation>[];
    final toolSummaries = <String, ToolResultSummary>{};
    int successCount = 0;
    int failureCount = 0;

    for (final task in plan.tasks) {
      final result = results[task.id];
      if (result == null) continue;

      if (result.success) {
        successCount++;

        // Extract context from result
        final context = _extractContext(task.toolName, result);
        if (context.isNotEmpty) {
          contextParts.add(context);
        }

        // Collect citations
        if (result.citations != null) {
          allCitations.addAll(result.citations!);
        }

        // Generate summary
        toolSummaries[task.id] = _generateToolSummary(task.toolName, result);
      } else {
        failureCount++;
        toolSummaries[task.id] = ToolResultSummary(
          toolName: task.toolName,
          success: false,
          resultCount: 0,
          summary: result.error ?? 'Unknown error',
        );
      }
    }

    // Combine and truncate context
    final combinedContext = _combineContext(contextParts);

    // Deduplicate citations
    final uniqueCitations = _deduplicateCitations(allCitations);

    return AggregatedResult(
      context: combinedContext,
      citations: uniqueCitations.take(maxCitations).toList(),
      successCount: successCount,
      failureCount: failureCount,
      totalCount: results.length,
      hasResults: contextParts.isNotEmpty,
      toolSummaries: toolSummaries,
    );
  }

  /// Aggregates results from a map of tool results.
  ///
  /// [results] - Map of tool name to result.
  ///
  /// Returns an [AggregatedResult] with combined context and citations.
  AggregatedResult aggregateFromResults(Map<String, ToolResult> results) {
    if (results.isEmpty) {
      return AggregatedResult.empty();
    }

    final contextParts = <String>[];
    final allCitations = <SourceCitation>[];
    final toolSummaries = <String, ToolResultSummary>{};
    int successCount = 0;
    int failureCount = 0;

    for (final entry in results.entries) {
      final toolName = entry.key;
      final result = entry.value;

      if (result.success) {
        successCount++;

        final context = _extractContext(toolName, result);
        if (context.isNotEmpty) {
          contextParts.add(context);
        }

        if (result.citations != null) {
          allCitations.addAll(result.citations!);
        }

        toolSummaries[toolName] = _generateToolSummary(toolName, result);
      } else {
        failureCount++;
        toolSummaries[toolName] = ToolResultSummary(
          toolName: toolName,
          success: false,
          resultCount: 0,
          summary: result.error ?? 'Unknown error',
        );
      }
    }

    final combinedContext = _combineContext(contextParts);
    final uniqueCitations = _deduplicateCitations(allCitations);

    return AggregatedResult(
      context: combinedContext,
      citations: uniqueCitations.take(maxCitations).toList(),
      successCount: successCount,
      failureCount: failureCount,
      totalCount: results.length,
      hasResults: contextParts.isNotEmpty,
      toolSummaries: toolSummaries,
    );
  }

  /// Extracts context from a tool result.
  String _extractContext(String toolName, ToolResult result) {
    if (result.data == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('【$toolName 结果】');

    if (result.data is Map) {
      final data = result.data as Map<String, dynamic>;

      // Handle search results
      if (data.containsKey('results')) {
        final results = data['results'] as List;
        final totalCount = data['total_count'] ?? results.length;

        buffer.writeln('找到 $totalCount 条相关结果：\n');

        for (int i = 0; i < results.length && i < 5; i++) {
          final item = results[i];
          if (item is Map) {
            final title = item['document_title'] ?? item['title'] ?? '未知文档';
            final snippet = item['snippet'] ?? '';
            final score = item['score'] ?? item['similarity_score'];

            buffer.writeln('${i + 1}. 【$title】');
            if (score != null) {
              buffer.writeln('   相关度: ${(score * 100).toStringAsFixed(1)}%');
            }
            buffer.writeln('   $snippet');
            buffer.writeln();
          }
        }

        if (results.length > 5) {
          buffer.writeln('... 还有 ${results.length - 5} 条结果');
        }
      }
      // Handle translation results
      else if (data.containsKey('translated_text')) {
        buffer.writeln('翻译结果：');
        buffer.writeln(data['translated_text']);
      }
      // Handle summary results
      else if (data.containsKey('summary')) {
        buffer.writeln('摘要：');
        buffer.writeln(data['summary']);
      }
      // Handle document results
      else if (data.containsKey('content')) {
        buffer.writeln('文档内容：');
        final content = data['content'] as String;
        buffer.writeln(
            content.length > 500 ? '${content.substring(0, 500)}...' : content);
      }
      // Generic map handling
      else {
        buffer.writeln(data.toString());
      }
    } else if (result.data is String) {
      buffer.writeln(result.data);
    } else {
      buffer.writeln(result.data.toString());
    }

    return buffer.toString();
  }

  /// Generates a summary for a tool result.
  ToolResultSummary _generateToolSummary(String toolName, ToolResult result) {
    int resultCount = 0;
    String summary = '';

    if (result.data is Map) {
      final data = result.data as Map<String, dynamic>;

      if (data.containsKey('results')) {
        final results = data['results'] as List;
        resultCount = results.length;
        summary = '找到 $resultCount 条结果';
      } else if (data.containsKey('translated_text')) {
        resultCount = 1;
        summary = '翻译完成';
      } else if (data.containsKey('summary')) {
        resultCount = 1;
        summary = '摘要生成完成';
      } else {
        resultCount = 1;
        summary = '执行成功';
      }
    } else {
      resultCount = 1;
      summary = '执行成功';
    }

    return ToolResultSummary(
      toolName: toolName,
      success: true,
      resultCount: resultCount,
      summary: summary,
    );
  }

  /// Combines multiple context parts into a single string.
  String _combineContext(List<String> parts) {
    if (parts.isEmpty) return '';

    final combined = parts.join('\n---\n');

    // Truncate if too long
    if (combined.length > maxContextLength) {
      return '${combined.substring(0, maxContextLength)}...\n[内容已截断]';
    }

    return combined;
  }

  /// Deduplicates citations based on document ID and snippet.
  List<SourceCitation> _deduplicateCitations(List<SourceCitation> citations) {
    final seen = <String>{};
    final unique = <SourceCitation>[];

    for (final citation in citations) {
      // Create a unique key based on document and snippet
      final key = '${citation.documentId}:${citation.snippet.hashCode}';

      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(citation);
      }
    }

    // Sort by score (highest first)
    unique.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));

    return unique;
  }

  /// Formats citations for display.
  ///
  /// [citations] - List of citations to format.
  /// [format] - Output format ('markdown', 'text', 'html').
  ///
  /// Returns formatted citation string.
  String formatCitations(
    List<SourceCitation> citations, {
    String format = 'markdown',
  }) {
    if (citations.isEmpty) return '';

    final buffer = StringBuffer();

    switch (format) {
      case 'markdown':
        buffer.writeln('\n## 来源引用\n');
        for (int i = 0; i < citations.length; i++) {
          final c = citations[i];
          buffer
              .writeln('${i + 1}. **${c.documentTitle}** (${c.workspaceName})');
          buffer.writeln('   > ${_truncateSnippet(c.snippet, 100)}');
          buffer.writeln();
        }
        break;

      case 'text':
        buffer.writeln('\n来源引用：\n');
        for (int i = 0; i < citations.length; i++) {
          final c = citations[i];
          buffer.writeln('${i + 1}. ${c.documentTitle} (${c.workspaceName})');
          buffer.writeln('   "${_truncateSnippet(c.snippet, 100)}"');
          buffer.writeln();
        }
        break;

      case 'html':
        buffer.writeln('<div class="citations">');
        buffer.writeln('<h3>来源引用</h3>');
        buffer.writeln('<ol>');
        for (final c in citations) {
          buffer.writeln('<li>');
          buffer.writeln(
              '<strong>${_escapeHtml(c.documentTitle)}</strong> (${_escapeHtml(c.workspaceName)})');
          buffer.writeln(
              '<blockquote>${_escapeHtml(_truncateSnippet(c.snippet, 100))}</blockquote>');
          buffer.writeln('</li>');
        }
        buffer.writeln('</ol>');
        buffer.writeln('</div>');
        break;
    }

    return buffer.toString();
  }

  /// Truncates a snippet to a maximum length.
  String _truncateSnippet(String snippet, int maxLength) {
    if (snippet.length <= maxLength) return snippet;
    return '${snippet.substring(0, maxLength)}...';
  }

  /// Escapes HTML special characters.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

/// Tool result and source citation classes
///
/// This file defines the result types returned by tool executions,
/// including success/failure states and source citations for
/// knowledge base queries.
library;

/// Represents the result of a tool execution.
///
/// A [ToolResult] contains information about whether the execution
/// was successful, any data returned, error messages if applicable,
/// and source citations for knowledge-based queries.
class ToolResult {
  /// Whether the tool execution was successful.
  final bool success;

  /// The data returned by the tool execution.
  ///
  /// The type and structure of this data depends on the specific tool.
  /// May be null if the tool doesn't return data or if execution failed.
  final dynamic data;

  /// Error message if the execution failed.
  ///
  /// Will be null if [success] is true.
  final String? error;

  /// Source citations for the result.
  ///
  /// When a tool retrieves information from the knowledge base,
  /// it should include citations to the source documents.
  /// This enables the AI to provide proper attribution in responses.
  final List<SourceCitation>? citations;

  /// Creates a new [ToolResult].
  const ToolResult({
    required this.success,
    this.data,
    this.error,
    this.citations,
  });

  /// Creates a successful result with optional data and citations.
  factory ToolResult.success({
    dynamic data,
    List<SourceCitation>? citations,
  }) {
    return ToolResult(
      success: true,
      data: data,
      citations: citations,
    );
  }

  /// Creates a failed result with an error message.
  factory ToolResult.failure(String error) {
    return ToolResult(
      success: false,
      error: error,
    );
  }

  /// Creates a result with no data (successful but empty).
  factory ToolResult.empty() {
    return const ToolResult(success: true);
  }

  /// Converts the result to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data,
      if (error != null) 'error': error,
      if (citations != null && citations!.isNotEmpty)
        'citations': citations!.map((c) => c.toJson()).toList(),
    };
  }

  /// Creates a [ToolResult] from a JSON map.
  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      success: json['success'] as bool,
      data: json['data'],
      error: json['error'] as String?,
      citations: json['citations'] != null
          ? (json['citations'] as List)
              .map((c) => SourceCitation.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'ToolResult.success(data: $data, citations: ${citations?.length ?? 0})';
    } else {
      return 'ToolResult.failure(error: $error)';
    }
  }
}

/// Represents a citation to a source document in the knowledge base.
///
/// When the AI retrieves information from documents, it should include
/// [SourceCitation] objects to enable proper attribution and allow
/// users to navigate to the original source.
class SourceCitation {
  /// The ID of the workspace containing the source document.
  final String workspaceId;

  /// The name of the workspace for display purposes.
  final String workspaceName;

  /// The ID of the source document.
  final String documentId;

  /// The title of the source document.
  final String documentTitle;

  /// A snippet of text from the source that was used.
  ///
  /// This should be the relevant passage that was retrieved
  /// and used to generate the response.
  final String snippet;

  /// The starting character offset of the snippet in the document.
  ///
  /// Used for precise navigation to the source location.
  /// May be null if offset information is not available.
  final int? startOffset;

  /// The ending character offset of the snippet in the document.
  ///
  /// Used for precise navigation to the source location.
  /// May be null if offset information is not available.
  final int? endOffset;

  /// The relevance score of this citation (0.0 to 1.0).
  ///
  /// Higher scores indicate more relevant matches.
  /// May be null if scoring is not applicable.
  final double? score;

  /// Creates a new [SourceCitation].
  const SourceCitation({
    required this.workspaceId,
    required this.workspaceName,
    required this.documentId,
    required this.documentTitle,
    required this.snippet,
    this.startOffset,
    this.endOffset,
    this.score,
  });

  /// Converts the citation to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'documentId': documentId,
      'documentTitle': documentTitle,
      'snippet': snippet,
      if (startOffset != null) 'startOffset': startOffset,
      if (endOffset != null) 'endOffset': endOffset,
      if (score != null) 'score': score,
    };
  }

  /// Creates a [SourceCitation] from a JSON map.
  factory SourceCitation.fromJson(Map<String, dynamic> json) {
    return SourceCitation(
      workspaceId: json['workspaceId'] as String,
      workspaceName: json['workspaceName'] as String,
      documentId: json['documentId'] as String,
      documentTitle: json['documentTitle'] as String,
      snippet: json['snippet'] as String,
      startOffset: json['startOffset'] as int?,
      endOffset: json['endOffset'] as int?,
      score: json['score'] as double?,
    );
  }

  /// Creates a copy of this citation with some fields replaced.
  SourceCitation copyWith({
    String? workspaceId,
    String? workspaceName,
    String? documentId,
    String? documentTitle,
    String? snippet,
    int? startOffset,
    int? endOffset,
    double? score,
  }) {
    return SourceCitation(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      snippet: snippet ?? this.snippet,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      score: score ?? this.score,
    );
  }

  @override
  String toString() {
    return 'SourceCitation(workspace: $workspaceName, document: $documentTitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SourceCitation &&
        other.workspaceId == workspaceId &&
        other.documentId == documentId &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset;
  }

  @override
  int get hashCode {
    return Object.hash(workspaceId, documentId, startOffset, endOffset);
  }
}

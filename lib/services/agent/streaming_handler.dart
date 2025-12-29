/// Streaming response handler for the AI Agent system
///
/// This file implements streaming response handling for real-time
/// AI responses with typing animation support.
/// Requirements: 7.9
library;

import 'dart:async';

import 'package:ai_packages_core/ai_packages_core.dart';

import '../../data/models/ai_model.dart';
import '../tools/tool_result.dart';
import 'agent_response.dart';

/// Configuration for streaming behavior.
class StreamingConfig {
  /// Delay between chunks for typing animation effect (milliseconds).
  final int chunkDelayMs;

  /// Whether to buffer chunks for smoother output.
  final bool bufferChunks;

  /// Minimum buffer size before emitting.
  final int minBufferSize;

  /// Maximum time to wait before flushing buffer (milliseconds).
  final int maxBufferWaitMs;

  /// Creates a new [StreamingConfig].
  const StreamingConfig({
    this.chunkDelayMs = 0,
    this.bufferChunks = false,
    this.minBufferSize = 10,
    this.maxBufferWaitMs = 100,
  });

  /// Default configuration with no delays.
  static const StreamingConfig fast = StreamingConfig();

  /// Configuration with typing animation effect.
  static const StreamingConfig animated = StreamingConfig(
    chunkDelayMs: 20,
    bufferChunks: true,
    minBufferSize: 5,
    maxBufferWaitMs: 50,
  );

  /// Configuration for smooth output.
  static const StreamingConfig smooth = StreamingConfig(
    bufferChunks: true,
    minBufferSize: 20,
    maxBufferWaitMs: 100,
  );
}

/// Handles streaming responses from the AI model.
///
/// The [StreamingHandler] provides:
/// - Buffered streaming for smoother output
/// - Typing animation effects
/// - Error handling and recovery
/// - Response aggregation
///
/// Requirements: 7.9
class StreamingHandler {
  final StreamingConfig config;

  /// Creates a new [StreamingHandler].
  StreamingHandler({this.config = StreamingConfig.fast});

  /// Streams a chat response from the AI model.
  ///
  /// [messages] - The chat messages to send.
  /// [onChunk] - Optional callback for each chunk.
  ///
  /// Returns a stream of [AgentResponse] objects.
  Stream<AgentResponse> streamChat(
    List<ChatMessage<String>> messages, {
    void Function(String chunk)? onChunk,
  }) async* {
    if (GlobalModel.model == null) {
      yield AgentResponse.error('AI 模型未配置');
      return;
    }

    try {
      final buffer = StringBuffer();
      Timer? flushTimer;

      await for (final chunk in GlobalModel.model!.streamChat(messages)) {
        onChunk?.call(chunk);

        if (config.bufferChunks) {
          buffer.write(chunk);

          // Check if we should flush
          if (buffer.length >= config.minBufferSize) {
            yield AgentResponse.streaming(buffer.toString());
            buffer.clear();
            flushTimer?.cancel();
          } else {
            // Set up a timer to flush after max wait time
            flushTimer?.cancel();
            flushTimer = Timer(
              Duration(milliseconds: config.maxBufferWaitMs),
              () {
                // Timer callback - buffer will be flushed in next iteration
              },
            );
          }
        } else {
          yield AgentResponse.streaming(chunk);
        }

        // Add delay for typing animation
        if (config.chunkDelayMs > 0) {
          await Future.delayed(Duration(milliseconds: config.chunkDelayMs));
        }
      }

      // Flush remaining buffer
      if (buffer.isNotEmpty) {
        yield AgentResponse.streaming(buffer.toString());
      }

      flushTimer?.cancel();
    } catch (e) {
      yield AgentResponse.error('流式响应失败: $e');
    }
  }

  /// Streams a response with context from tool results.
  ///
  /// [query] - The user's query.
  /// [context] - Context from tool results.
  /// [citations] - Source citations to append.
  /// [systemPrompt] - Optional custom system prompt.
  ///
  /// Returns a stream of [AgentResponse] objects.
  Stream<AgentResponse> streamWithContext({
    required String query,
    required String context,
    List<SourceCitation>? citations,
    String? systemPrompt,
  }) async* {
    if (GlobalModel.model == null) {
      // No model available, return raw context
      yield AgentResponse.streaming(context);
      if (citations != null && citations.isNotEmpty) {
        yield AgentResponse.citations(citations);
      }
      yield AgentResponse.done();
      return;
    }

    final effectiveSystemPrompt = systemPrompt ??
        '''
基于以下检索到的信息回答用户的问题。
如果信息不足以回答问题，请诚实地说明。
回答要准确、简洁、有帮助。

检索到的信息：
$context
''';

    final messages = [
      ChatMessage<String>(
        role: 'system',
        content: effectiveSystemPrompt,
        createAt: DateTime.now().millisecondsSinceEpoch,
      ),
      ChatMessage<String>(
        role: 'user',
        content: query,
        createAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    yield* streamChat(messages);

    // Append citations after streaming completes
    if (citations != null && citations.isNotEmpty) {
      yield AgentResponse.citations(citations);
    }

    yield AgentResponse.done();
  }

  /// Streams a simple response without context.
  ///
  /// [query] - The user's query.
  /// [systemPrompt] - Optional system prompt.
  ///
  /// Returns a stream of [AgentResponse] objects.
  Stream<AgentResponse> streamSimple({
    required String query,
    String? systemPrompt,
  }) async* {
    if (GlobalModel.model == null) {
      yield AgentResponse.error('AI 模型未配置');
      return;
    }

    final messages = [
      if (systemPrompt != null)
        ChatMessage<String>(
          role: 'system',
          content: systemPrompt,
          createAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ChatMessage<String>(
        role: 'user',
        content: query,
        createAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    yield* streamChat(messages);
    yield AgentResponse.done();
  }

  /// Collects a streamed response into a single string.
  ///
  /// [stream] - The response stream to collect.
  ///
  /// Returns the complete response text.
  Future<String> collectResponse(Stream<AgentResponse> stream) async {
    final buffer = StringBuffer();

    await for (final response in stream) {
      if (response.isStreaming) {
        buffer.write(response.streamingChunk);
      }
    }

    return buffer.toString();
  }

  /// Transforms a stream to add typing animation.
  ///
  /// [stream] - The original stream.
  /// [delayMs] - Delay between characters.
  ///
  /// Returns a stream with character-by-character output.
  Stream<AgentResponse> withTypingAnimation(
    Stream<AgentResponse> stream, {
    int delayMs = 20,
  }) async* {
    await for (final response in stream) {
      if (response.isStreaming) {
        final text = response.streamingChunk ?? '';
        for (final char in text.split('')) {
          yield AgentResponse.streaming(char);
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } else {
        yield response;
      }
    }
  }
}

/// Manages multiple concurrent streaming sessions.
class StreamingSessionManager {
  final Map<String, StreamController<AgentResponse>> _sessions = {};

  /// Creates a new streaming session.
  ///
  /// [sessionId] - Unique identifier for the session.
  ///
  /// Returns a stream controller for the session.
  StreamController<AgentResponse> createSession(String sessionId) {
    // Close existing session if any
    _sessions[sessionId]?.close();

    final controller = StreamController<AgentResponse>.broadcast();
    _sessions[sessionId] = controller;
    return controller;
  }

  /// Gets an existing session.
  ///
  /// [sessionId] - The session identifier.
  ///
  /// Returns the stream controller, or null if not found.
  StreamController<AgentResponse>? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Closes a session.
  ///
  /// [sessionId] - The session identifier.
  void closeSession(String sessionId) {
    _sessions[sessionId]?.close();
    _sessions.remove(sessionId);
  }

  /// Closes all sessions.
  void closeAll() {
    for (final controller in _sessions.values) {
      controller.close();
    }
    _sessions.clear();
  }

  /// Gets the number of active sessions.
  int get activeSessionCount => _sessions.length;

  /// Checks if a session exists.
  bool hasSession(String sessionId) => _sessions.containsKey(sessionId);
}

/// Extension methods for streaming responses.
extension StreamingResponseExtensions on Stream<AgentResponse> {
  /// Filters to only streaming chunks.
  Stream<String> get streamingChunks {
    return where((r) => r.isStreaming).map((r) => r.streamingChunk ?? '');
  }

  /// Collects all streaming chunks into a single string.
  Future<String> collectText() async {
    final buffer = StringBuffer();
    await for (final response in this) {
      if (response.isStreaming) {
        buffer.write(response.streamingChunk);
      }
    }
    return buffer.toString();
  }

  /// Gets the first error response, if any.
  Future<AgentResponse?> get firstError async {
    await for (final response in this) {
      if (response.isError) return response;
    }
    return null;
  }

  /// Gets all citations from the stream.
  Future<List<SourceCitation>> collectCitations() async {
    final citations = <SourceCitation>[];
    await for (final response in this) {
      if (response.isCitations) {
        citations.addAll(response.citationsList ?? []);
      }
    }
    return citations;
  }
}

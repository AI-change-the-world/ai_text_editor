import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';

/// 嵌入结果
/// Requirements: 4.1
class EmbeddingResult {
  final String text;
  final List<double> embedding;
  final bool fromCache;

  EmbeddingResult({
    required this.text,
    required this.embedding,
    this.fromCache = false,
  });
}

/// 批量嵌入结果
/// Requirements: 4.2
class BatchEmbeddingResult {
  final List<EmbeddingResult> results;
  final int successCount;
  final int failureCount;
  final int cacheHitCount;

  BatchEmbeddingResult({
    required this.results,
    required this.successCount,
    required this.failureCount,
    required this.cacheHitCount,
  });
}

/// 嵌入提供商类型
enum EmbeddingProvider {
  openai,
  ollama,
  custom,
}

/// 嵌入配置
class EmbeddingConfig {
  final EmbeddingProvider provider;
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final int dimensions;

  const EmbeddingConfig({
    this.provider = EmbeddingProvider.openai,
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.modelName = 'text-embedding-ada-002',
    this.dimensions = 1536,
  });

  /// OpenAI 默认配置
  static EmbeddingConfig openai({
    required String apiKey,
    String baseUrl = 'https://api.openai.com/v1',
    String modelName = 'text-embedding-ada-002',
  }) {
    return EmbeddingConfig(
      provider: EmbeddingProvider.openai,
      apiKey: apiKey,
      baseUrl: baseUrl,
      modelName: modelName,
      dimensions: 1536,
    );
  }

  /// Ollama 本地配置
  static EmbeddingConfig ollama({
    String baseUrl = 'http://localhost:11434',
    String modelName = 'nomic-embed-text',
    int dimensions = 768,
  }) {
    return EmbeddingConfig(
      provider: EmbeddingProvider.ollama,
      apiKey: '',
      baseUrl: baseUrl,
      modelName: modelName,
      dimensions: dimensions,
    );
  }
}

/// 缓存统计
class CacheStats {
  final int totalEntries;
  final int hitCount;
  final int missCount;
  final double hitRate;
  final int expiredCount;

  CacheStats({
    required this.totalEntries,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
    required this.expiredCount,
  });
}

/// 嵌入服务接口
/// Requirements: 4.1, 4.2, 4.8
abstract class IEmbeddingService {
  /// 获取单个文本的嵌入向量
  /// Requirements: 4.1
  Future<List<double>> getEmbedding(String text);

  /// 批量获取嵌入向量
  /// Requirements: 4.2
  Future<BatchEmbeddingResult> getBatchEmbeddings(List<String> texts);

  /// 更新配置
  void updateConfig(EmbeddingConfig config);

  /// 获取当前配置
  EmbeddingConfig get config;

  /// 清除缓存
  /// Requirements: 4.8
  Future<void> clearCache();

  /// 获取缓存统计
  Future<CacheStats> getCacheStats();

  /// 为文档块生成嵌入
  Future<void> generateChunkEmbeddings(String documentId);

  /// 批量为文档块生成嵌入
  Future<void> generateBatchChunkEmbeddings(List<String> documentIds);
}

/// 嵌入服务实现
/// Requirements: 4.1, 4.2, 4.8
class EmbeddingService implements IEmbeddingService {
  final ObxDatabase _db;
  EmbeddingConfig _config;

  /// 缓存统计
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// HTTP 客户端
  final http.Client _httpClient;

  /// 批量处理大小
  static const int _batchSize = 20;

  /// 缓存过期时间 (默认 0 表示永不过期)
  final int _cacheExpirationMs;

  EmbeddingService(
    this._db, {
    EmbeddingConfig? config,
    http.Client? httpClient,
    int cacheExpirationDays = 0,
  })  : _config = config ?? const EmbeddingConfig(),
        _httpClient = httpClient ?? http.Client(),
        _cacheExpirationMs = cacheExpirationDays > 0
            ? cacheExpirationDays * 24 * 60 * 60 * 1000
            : 0;

  /// 获取单例实例
  static EmbeddingService? _instance;

  /// 获取单例实例（懒加载）
  static EmbeddingService get instance {
    _instance ??= EmbeddingService(ObxDatabase.db);
    return _instance!;
  }

  /// 重置单例 (用于测试)
  static void resetInstance() {
    _instance = null;
  }

  @override
  EmbeddingConfig get config => _config;

  @override
  void updateConfig(EmbeddingConfig config) {
    _config = config;
  }

  /// 计算文本哈希
  String _computeHash(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 从缓存获取嵌入
  /// Requirements: 4.8
  EmbeddingCache? _getFromCache(String text) {
    final hash = _computeHash(text);

    final query =
        _db.embeddingCacheBox.query(EmbeddingCache_.textHash.equals(hash));
    final result = query.build().findFirst();
    query.build().close();

    if (result != null && !result.isExpired && result.text == text) {
      // 更新访问统计
      result.accessCount++;
      result.lastAccessedAt = DateTime.now().millisecondsSinceEpoch;
      _db.embeddingCacheBox.put(result);
      _cacheHits++;
      return result;
    }

    // 如果过期，删除缓存
    if (result != null && result.isExpired) {
      _db.embeddingCacheBox.remove(result.id);
    }

    _cacheMisses++;
    return null;
  }

  /// 保存到缓存
  /// Requirements: 4.8
  void _saveToCache(String text, List<double> embedding) {
    final hash = _computeHash(text);
    final now = DateTime.now().millisecondsSinceEpoch;

    // 检查是否已存在
    final existingQuery =
        _db.embeddingCacheBox.query(EmbeddingCache_.textHash.equals(hash));
    final existing = existingQuery.build().findFirst();
    existingQuery.build().close();

    if (existing != null) {
      // 更新现有缓存
      existing.embeddingJson = jsonEncode(embedding);
      existing.modelName = _config.modelName;
      existing.lastAccessedAt = now;
      if (_cacheExpirationMs > 0) {
        existing.expiresAt = now + _cacheExpirationMs;
      }
      _db.embeddingCacheBox.put(existing);
    } else {
      // 创建新缓存
      final cache = EmbeddingCache(
        textHash: hash,
        text: text,
        embeddingJson: jsonEncode(embedding),
        modelName: _config.modelName,
        createdAt: now,
        expiresAt: _cacheExpirationMs > 0 ? now + _cacheExpirationMs : 0,
        lastAccessedAt: now,
      );
      _db.embeddingCacheBox.put(cache);
    }
  }

  /// 获取单个文本的嵌入向量
  /// Requirements: 4.1
  @override
  Future<List<double>> getEmbedding(String text) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Text cannot be empty');
    }

    // 先检查缓存
    final cached = _getFromCache(text);
    if (cached != null) {
      return cached.embedding;
    }

    // 调用 API 获取嵌入
    final embedding = await _callEmbeddingApi(text);

    // 保存到缓存
    _saveToCache(text, embedding);

    return embedding;
  }

  /// 调用嵌入 API
  /// Requirements: 4.1
  Future<List<double>> _callEmbeddingApi(String text) async {
    switch (_config.provider) {
      case EmbeddingProvider.openai:
        return _callOpenAIEmbedding(text);
      case EmbeddingProvider.ollama:
        return _callOllamaEmbedding(text);
      case EmbeddingProvider.custom:
        return _callOpenAIEmbedding(text); // 使用 OpenAI 兼容格式
    }
  }

  /// 调用 OpenAI 嵌入 API
  Future<List<double>> _callOpenAIEmbedding(String text) async {
    final url = Uri.parse('${_config.baseUrl}/embeddings');

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      },
      body: jsonEncode({
        'model': _config.modelName,
        'input': text,
      }),
    );

    if (response.statusCode != 200) {
      throw EmbeddingException(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> embeddingData = data['data'][0]['embedding'];
    return embeddingData.map((e) => (e as num).toDouble()).toList();
  }

  /// 调用 Ollama 嵌入 API
  Future<List<double>> _callOllamaEmbedding(String text) async {
    final url = Uri.parse('${_config.baseUrl}/api/embeddings');

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _config.modelName,
        'prompt': text,
      }),
    );

    if (response.statusCode != 200) {
      throw EmbeddingException(
        'Ollama API error: ${response.statusCode} - ${response.body}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> embeddingData = data['embedding'];
    return embeddingData.map((e) => (e as num).toDouble()).toList();
  }

  /// 批量获取嵌入向量
  /// Requirements: 4.2
  @override
  Future<BatchEmbeddingResult> getBatchEmbeddings(List<String> texts) async {
    final results = <EmbeddingResult>[];
    int successCount = 0;
    int failureCount = 0;
    int cacheHitCount = 0;

    // 分离缓存命中和需要请求的文本
    final textsToFetch = <String>[];
    final cachedResults = <String, EmbeddingResult>{};

    for (final text in texts) {
      if (text.trim().isEmpty) {
        failureCount++;
        continue;
      }

      final cached = _getFromCache(text);
      if (cached != null) {
        cachedResults[text] = EmbeddingResult(
          text: text,
          embedding: cached.embedding,
          fromCache: true,
        );
        cacheHitCount++;
      } else {
        textsToFetch.add(text);
      }
    }

    // 批量请求未缓存的文本
    if (textsToFetch.isNotEmpty) {
      // 分批处理
      for (int i = 0; i < textsToFetch.length; i += _batchSize) {
        final batch = textsToFetch.skip(i).take(_batchSize).toList();

        try {
          final batchEmbeddings = await _callBatchEmbeddingApi(batch);

          for (int j = 0; j < batch.length; j++) {
            final text = batch[j];
            final embedding = batchEmbeddings[j];

            // 保存到缓存
            _saveToCache(text, embedding);

            cachedResults[text] = EmbeddingResult(
              text: text,
              embedding: embedding,
              fromCache: false,
            );
            successCount++;
          }
        } catch (e) {
          // 批量失败时，尝试单个请求
          for (final text in batch) {
            try {
              final embedding = await _callEmbeddingApi(text);
              _saveToCache(text, embedding);

              cachedResults[text] = EmbeddingResult(
                text: text,
                embedding: embedding,
                fromCache: false,
              );
              successCount++;
            } catch (_) {
              failureCount++;
            }
          }
        }
      }
    }

    // 按原始顺序组装结果
    for (final text in texts) {
      final result = cachedResults[text];
      if (result != null) {
        results.add(result);
      }
    }

    return BatchEmbeddingResult(
      results: results,
      successCount: successCount + cacheHitCount,
      failureCount: failureCount,
      cacheHitCount: cacheHitCount,
    );
  }

  /// 批量调用嵌入 API
  Future<List<List<double>>> _callBatchEmbeddingApi(List<String> texts) async {
    switch (_config.provider) {
      case EmbeddingProvider.openai:
      case EmbeddingProvider.custom:
        return _callOpenAIBatchEmbedding(texts);
      case EmbeddingProvider.ollama:
        // Ollama 不支持批量，逐个请求
        final results = <List<double>>[];
        for (final text in texts) {
          results.add(await _callOllamaEmbedding(text));
        }
        return results;
    }
  }

  /// 批量调用 OpenAI 嵌入 API
  Future<List<List<double>>> _callOpenAIBatchEmbedding(
      List<String> texts) async {
    final url = Uri.parse('${_config.baseUrl}/embeddings');

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      },
      body: jsonEncode({
        'model': _config.modelName,
        'input': texts,
      }),
    );

    if (response.statusCode != 200) {
      throw EmbeddingException(
        'OpenAI API error: ${response.statusCode} - ${response.body}',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> dataList = data['data'];

    // 按 index 排序确保顺序正确
    dataList.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    return dataList.map((item) {
      final List<dynamic> embeddingData = item['embedding'];
      return embeddingData.map((e) => (e as num).toDouble()).toList();
    }).toList();
  }

  /// 清除缓存
  /// Requirements: 4.8
  @override
  Future<void> clearCache() async {
    _db.embeddingCacheBox.removeAll();
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// 获取缓存统计
  @override
  Future<CacheStats> getCacheStats() async {
    final totalEntries = _db.embeddingCacheBox.count();

    // 统计过期条目
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredQuery = _db.embeddingCacheBox.query(
      EmbeddingCache_.expiresAt.greaterThan(0) &
          EmbeddingCache_.expiresAt.lessThan(now),
    );
    final expiredCount = expiredQuery.build().count();
    expiredQuery.build().close();

    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

    return CacheStats(
      totalEntries: totalEntries,
      hitCount: _cacheHits,
      missCount: _cacheMisses,
      hitRate: hitRate,
      expiredCount: expiredCount,
    );
  }

  /// 为文档块生成嵌入
  @override
  Future<void> generateChunkEmbeddings(String documentId) async {
    // 获取文档的所有块
    final query = _db.documentChunkBox
        .query(DocumentChunk_.documentId.equals(documentId))
        .order(DocumentChunk_.chunkIndex);
    final chunks = query.build().find();
    query.build().close();

    if (chunks.isEmpty) {
      return;
    }

    // 获取需要生成嵌入的块文本
    final textsToEmbed = chunks
        .where((chunk) => chunk.embedding == null || chunk.embedding!.isEmpty)
        .map((chunk) => chunk.chunkText)
        .toList();

    if (textsToEmbed.isEmpty) {
      return;
    }

    // 批量生成嵌入
    final batchResult = await getBatchEmbeddings(textsToEmbed);

    // 更新块的嵌入
    int resultIndex = 0;
    for (final chunk in chunks) {
      if (chunk.embedding == null || chunk.embedding!.isEmpty) {
        if (resultIndex < batchResult.results.length) {
          chunk.embedding = batchResult.results[resultIndex].embedding;
          resultIndex++;
        }
      }
    }

    // 批量保存
    _db.documentChunkBox.putMany(chunks);
  }

  /// 批量为文档块生成嵌入
  @override
  Future<void> generateBatchChunkEmbeddings(List<String> documentIds) async {
    for (final documentId in documentIds) {
      await generateChunkEmbeddings(documentId);
    }
  }
}

/// 嵌入异常
class EmbeddingException implements Exception {
  final String message;
  final int? statusCode;

  EmbeddingException(this.message, [this.statusCode]);

  @override
  String toString() => 'EmbeddingException: $message';
}

import 'dart:convert';

import 'package:objectbox/objectbox.dart';

/// 嵌入缓存实体
/// 用于缓存文本的向量嵌入，避免重复调用 API
/// Requirements: 4.8
@Entity()
class EmbeddingCache {
  @Id()
  int id = 0;

  /// 文本内容的哈希值 (用于快速查找)
  @Unique()
  String textHash;

  /// 原始文本 (用于验证哈希碰撞)
  String text;

  /// 嵌入向量 (JSON 序列化存储)
  String embeddingJson;

  /// 使用的模型名称
  String modelName;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 过期时间 (毫秒时间戳, 0 表示永不过期)
  int expiresAt;

  /// 访问次数 (用于 LRU 缓存策略)
  int accessCount;

  /// 最后访问时间 (毫秒时间戳)
  int lastAccessedAt;

  EmbeddingCache({
    this.id = 0,
    required this.textHash,
    required this.text,
    required this.embeddingJson,
    required this.modelName,
    int? createdAt,
    this.expiresAt = 0,
    this.accessCount = 0,
    int? lastAccessedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        lastAccessedAt =
            lastAccessedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取嵌入向量
  List<double> get embedding {
    final List<dynamic> decoded = jsonDecode(embeddingJson);
    return decoded.map((e) => (e as num).toDouble()).toList();
  }

  /// 设置嵌入向量
  set embedding(List<double> value) {
    embeddingJson = jsonEncode(value);
  }

  /// 检查是否过期
  bool get isExpired {
    if (expiresAt == 0) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  /// 创建空缓存条目
  static EmbeddingCache empty() {
    return EmbeddingCache(
      textHash: '',
      text: '',
      embeddingJson: '[]',
      modelName: '',
    );
  }

  /// 复制并修改
  EmbeddingCache copyWith({
    int? id,
    String? textHash,
    String? text,
    String? embeddingJson,
    String? modelName,
    int? createdAt,
    int? expiresAt,
    int? accessCount,
    int? lastAccessedAt,
  }) {
    return EmbeddingCache(
      id: id ?? this.id,
      textHash: textHash ?? this.textHash,
      text: text ?? this.text,
      embeddingJson: embeddingJson ?? this.embeddingJson,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

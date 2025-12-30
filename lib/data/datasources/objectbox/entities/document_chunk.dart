import 'package:objectbox/objectbox.dart';

/// 文档切片实体
/// 将文档分块存储，支持全文检索和向量检索
@Entity()
class DocumentChunk {
  @Id()
  int id = 0;

  /// 关联的文档 ID
  @Index()
  String documentId;

  /// 所属工作空间 ID
  @Index()
  String workspaceId;

  /// 块索引 (在文档中的顺序)
  int chunkIndex;

  /// 块文本内容
  String chunkText;

  /// 块在原文中的起始位置（字符偏移）
  int startOffset;

  /// 块在原文中的结束位置（字符偏移）
  int endOffset;

  /// 是否已向量化
  bool isEmbedded;

  /// 向量嵌入 - 使用 ObjectBox HNSW 索引
  /// 维度: 1536 (OpenAI text-embedding-ada-002) 或其他模型
  /// 距离类型: 余弦相似度
  @HnswIndex(dimensions: 1536, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  DocumentChunk({
    this.id = 0,
    required this.documentId,
    required this.workspaceId,
    required this.chunkIndex,
    required this.chunkText,
    this.startOffset = 0,
    this.endOffset = 0,
    this.isEmbedded = false,
    this.embedding,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 创建空文档块
  static DocumentChunk empty() {
    return DocumentChunk(
      documentId: '',
      workspaceId: '',
      chunkIndex: 0,
      chunkText: '',
    );
  }

  /// 复制并修改
  DocumentChunk copyWith({
    int? id,
    String? documentId,
    String? workspaceId,
    int? chunkIndex,
    String? chunkText,
    int? startOffset,
    int? endOffset,
    bool? isEmbedded,
    List<double>? embedding,
    int? createdAt,
    int? updatedAt,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      workspaceId: workspaceId ?? this.workspaceId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText ?? this.chunkText,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

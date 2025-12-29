import 'package:objectbox/objectbox.dart';

/// 文档向量块实体 (用于语义搜索)
/// 将文档分块并存储向量嵌入，支持 HNSW 向量索引
/// Requirements: 4.1, 4.2
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

  /// 向量嵌入 - 使用 ObjectBox HNSW 索引
  /// 维度: 1536 (OpenAI text-embedding-ada-002)
  /// 距离类型: 余弦相似度
  @HnswIndex(dimensions: 1536, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  DocumentChunk({
    this.id = 0,
    required this.documentId,
    required this.workspaceId,
    required this.chunkIndex,
    required this.chunkText,
    this.embedding,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

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
    List<double>? embedding,
    int? createdAt,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      workspaceId: workspaceId ?? this.workspaceId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      chunkText: chunkText ?? this.chunkText,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

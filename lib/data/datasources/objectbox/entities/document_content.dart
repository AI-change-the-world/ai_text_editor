import 'package:objectbox/objectbox.dart';

/// 文档内容实体
/// 存储文档的完整内容，支持多种格式
@Entity()
class DocumentContent {
  @Id()
  int id = 0;

  /// 关联的文档 ID
  @Unique()
  String documentId;

  /// 所属工作空间 ID
  @Index()
  String workspaceId;

  /// Quill Delta JSON (编辑器原始格式)
  String deltaJson;

  /// 纯文本内容 (用于全文检索)
  String plainText;

  /// Markdown 格式 (用于导出和 AI 上下文)
  String markdown;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  DocumentContent({
    this.id = 0,
    required this.documentId,
    required this.workspaceId,
    this.deltaJson = '',
    this.plainText = '',
    this.markdown = '',
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 创建空文档内容
  static DocumentContent empty() {
    return DocumentContent(
      documentId: '',
      workspaceId: '',
    );
  }

  /// 复制并修改
  DocumentContent copyWith({
    int? id,
    String? documentId,
    String? workspaceId,
    String? deltaJson,
    String? plainText,
    String? markdown,
    int? updatedAt,
  }) {
    return DocumentContent(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      workspaceId: workspaceId ?? this.workspaceId,
      deltaJson: deltaJson ?? this.deltaJson,
      plainText: plainText ?? this.plainText,
      markdown: markdown ?? this.markdown,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

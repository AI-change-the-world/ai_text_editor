import 'package:objectbox/objectbox.dart';

/// 文档内容实体 (用于全文检索)
/// 存储文档的完整文本内容，支持全文搜索
/// Requirements: 5.4
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

  /// 文档标题
  String title;

  /// 文档内容 (纯文本)
  String content;

  /// 标签列表 (JSON 序列化存储)
  String tagsJson;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  DocumentContent({
    this.id = 0,
    required this.documentId,
    required this.workspaceId,
    required this.title,
    required this.content,
    this.tagsJson = '[]',
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取标签列表
  List<String> get tags {
    if (tagsJson.isEmpty || tagsJson == '[]') return [];
    final content = tagsJson.substring(1, tagsJson.length - 1);
    if (content.isEmpty) return [];
    return content.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
  }

  /// 设置标签列表
  set tags(List<String> value) {
    tagsJson = '[${value.map((e) => '"$e"').join(',')}]';
  }

  /// 创建空文档内容
  static DocumentContent empty() {
    return DocumentContent(
      documentId: '',
      workspaceId: '',
      title: '',
      content: '',
    );
  }

  /// 复制并修改
  DocumentContent copyWith({
    int? id,
    String? documentId,
    String? workspaceId,
    String? title,
    String? content,
    String? tagsJson,
    int? updatedAt,
  }) {
    return DocumentContent(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      tagsJson: tagsJson ?? this.tagsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:objectbox/objectbox.dart';

/// 文档元数据实体
/// 存储文档的基本信息，支持文件夹结构
/// Requirements: 1.4, 1.5
@Entity()
class DocumentMeta {
  @Id()
  int id = 0;

  /// 唯一标识符
  @Unique()
  String uuid;

  /// 所属工作空间 ID
  @Index()
  String workspaceId;

  /// 文档标题
  String title;

  /// 父文件夹 ID，null 表示根目录
  String? parentFolderId;

  /// 文档文件路径
  String filePath;

  /// 字数统计
  int wordCount;

  /// 字符数统计
  int characterCount;

  /// 是否为文件夹
  bool isFolder;

  /// 排序顺序
  int sortOrder;

  /// 标签列表 (JSON 序列化存储)
  String tagsJson;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  DocumentMeta({
    this.id = 0,
    required this.uuid,
    required this.workspaceId,
    required this.title,
    this.parentFolderId,
    required this.filePath,
    this.wordCount = 0,
    this.characterCount = 0,
    this.isFolder = false,
    this.sortOrder = 0,
    this.tagsJson = '[]',
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取标签列表
  List<String> get tags {
    if (tagsJson.isEmpty || tagsJson == '[]') return [];
    // 简单解析 JSON 数组
    final content = tagsJson.substring(1, tagsJson.length - 1);
    if (content.isEmpty) return [];
    return content.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
  }

  /// 设置标签列表
  set tags(List<String> value) {
    tagsJson = '[${value.map((e) => '"$e"').join(',')}]';
  }

  /// 创建空文档元数据
  static DocumentMeta empty() {
    return DocumentMeta(
      uuid: '',
      workspaceId: '',
      title: '',
      filePath: '',
    );
  }

  /// 复制并修改
  DocumentMeta copyWith({
    int? id,
    String? uuid,
    String? workspaceId,
    String? title,
    String? parentFolderId,
    String? filePath,
    int? wordCount,
    int? characterCount,
    bool? isFolder,
    int? sortOrder,
    String? tagsJson,
    int? createdAt,
    int? updatedAt,
  }) {
    return DocumentMeta(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      filePath: filePath ?? this.filePath,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      isFolder: isFolder ?? this.isFolder,
      sortOrder: sortOrder ?? this.sortOrder,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

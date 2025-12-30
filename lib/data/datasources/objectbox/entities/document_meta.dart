import 'package:objectbox/objectbox.dart';

/// 检索方式枚举
enum SearchMode {
  fulltext, // 仅全文检索
  vector, // 仅向量检索
  hybrid, // 混合检索（全文+向量）
  none, // 未索引
}

/// 文档元数据实体
/// 存储文档的基本信息，支持文件夹结构
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

  /// 字数统计
  int wordCount;

  /// 字符数统计
  int characterCount;

  /// 是否为文件夹
  bool isFolder;

  /// 排序顺序
  int sortOrder;

  /// 检索方式 (存储为 int)
  int searchModeIndex;

  /// 是否已索引（全文）
  bool isIndexed;

  /// 是否已向量化
  bool isEmbedded;

  /// 标签列表 (JSON 序列化存储)
  String tagsJson;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  /// 最后访问时间 (毫秒时间戳)
  int lastAccessedAt;

  DocumentMeta({
    this.id = 0,
    required this.uuid,
    required this.workspaceId,
    required this.title,
    this.parentFolderId,
    this.wordCount = 0,
    this.characterCount = 0,
    this.isFolder = false,
    this.sortOrder = 0,
    this.searchModeIndex = 0, // SearchMode.fulltext
    this.isIndexed = false,
    this.isEmbedded = false,
    this.tagsJson = '[]',
    int? createdAt,
    int? updatedAt,
    int? lastAccessedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        lastAccessedAt =
            lastAccessedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取检索方式
  SearchMode get searchMode => SearchMode.values[searchModeIndex];

  /// 设置检索方式
  set searchMode(SearchMode value) {
    searchModeIndex = value.index;
  }

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

  /// 创建空文档元数据
  static DocumentMeta empty() {
    return DocumentMeta(
      uuid: '',
      workspaceId: '',
      title: '',
    );
  }

  /// 复制并修改
  DocumentMeta copyWith({
    int? id,
    String? uuid,
    String? workspaceId,
    String? title,
    String? parentFolderId,
    int? wordCount,
    int? characterCount,
    bool? isFolder,
    int? sortOrder,
    int? searchModeIndex,
    bool? isIndexed,
    bool? isEmbedded,
    String? tagsJson,
    int? createdAt,
    int? updatedAt,
    int? lastAccessedAt,
  }) {
    return DocumentMeta(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      wordCount: wordCount ?? this.wordCount,
      characterCount: characterCount ?? this.characterCount,
      isFolder: isFolder ?? this.isFolder,
      sortOrder: sortOrder ?? this.sortOrder,
      searchModeIndex: searchModeIndex ?? this.searchModeIndex,
      isIndexed: isIndexed ?? this.isIndexed,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

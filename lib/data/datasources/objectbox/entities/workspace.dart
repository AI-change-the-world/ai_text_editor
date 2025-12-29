import 'package:objectbox/objectbox.dart';

/// 工作空间实体
/// 用户的顶层组织单元，代表一个知识领域
/// Requirements: 1.2
@Entity()
class Workspace {
  @Id()
  int id = 0;

  /// 唯一标识符
  @Unique()
  String uuid;

  /// 工作空间名称
  String name;

  /// 工作空间描述
  String? description;

  /// 图标 (emoji 或图标名称)
  String? icon;

  /// 主题色 (hex 格式)
  String? colorTheme;

  /// 分类标签
  String? category;

  /// 是否置顶
  bool isPinned;

  /// 是否已归档
  bool isArchived;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  /// 最后访问时间 (毫秒时间戳)
  int lastAccessedAt;

  Workspace({
    this.id = 0,
    required this.uuid,
    required this.name,
    this.description,
    this.icon,
    this.colorTheme,
    this.category,
    this.isPinned = false,
    this.isArchived = false,
    int? createdAt,
    int? updatedAt,
    int? lastAccessedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
        lastAccessedAt =
            lastAccessedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 创建空工作空间
  static Workspace empty() {
    return Workspace(
      uuid: '',
      name: '',
    );
  }

  /// 复制并修改
  Workspace copyWith({
    int? id,
    String? uuid,
    String? name,
    String? description,
    String? icon,
    String? colorTheme,
    String? category,
    bool? isPinned,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
    int? lastAccessedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorTheme: colorTheme ?? this.colorTheme,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}

import 'package:objectbox/objectbox.dart';

/// 聊天历史实体
/// 存储 AI 对话会话
/// Requirements: 7.11
@Entity()
class ChatHistory {
  @Id()
  int id = 0;

  /// 唯一标识符
  @Unique()
  String uuid;

  /// 关联的工作空间 ID (可选)
  @Index()
  String? workspaceId;

  /// 关联的文档 ID (可选)
  String? documentId;

  /// 对话标题
  String title;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  ChatHistory({
    this.id = 0,
    required this.uuid,
    this.workspaceId,
    this.documentId,
    required this.title,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 创建空聊天历史
  static ChatHistory empty() {
    return ChatHistory(
      uuid: '',
      title: '',
    );
  }

  /// 复制并修改
  ChatHistory copyWith({
    int? id,
    String? uuid,
    String? workspaceId,
    String? documentId,
    String? title,
    int? createdAt,
    int? updatedAt,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      workspaceId: workspaceId ?? this.workspaceId,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 聊天消息实体
/// 存储单条聊天消息
/// Requirements: 7.11
@Entity()
class ChatMessage {
  @Id()
  int id = 0;

  /// 所属聊天历史 ID
  @Index()
  String chatHistoryId;

  /// 消息角色 (user, assistant, system)
  String role;

  /// 消息内容
  String content;

  /// 来源引用 (文档ID列表，JSON 序列化)
  String? citationsJson;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  ChatMessage({
    this.id = 0,
    required this.chatHistoryId,
    required this.role,
    required this.content,
    this.citationsJson,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取引用列表
  List<String> get citations {
    if (citationsJson == null ||
        citationsJson!.isEmpty ||
        citationsJson == '[]') {
      return [];
    }
    final content = citationsJson!.substring(1, citationsJson!.length - 1);
    if (content.isEmpty) return [];
    return content.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
  }

  /// 设置引用列表
  set citations(List<String> value) {
    citationsJson = '[${value.map((e) => '"$e"').join(',')}]';
  }

  /// 创建空聊天消息
  static ChatMessage empty() {
    return ChatMessage(
      chatHistoryId: '',
      role: 'user',
      content: '',
    );
  }

  /// 复制并修改
  ChatMessage copyWith({
    int? id,
    String? chatHistoryId,
    String? role,
    String? content,
    String? citationsJson,
    int? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatHistoryId: chatHistoryId ?? this.chatHistoryId,
      role: role ?? this.role,
      content: content ?? this.content,
      citationsJson: citationsJson ?? this.citationsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

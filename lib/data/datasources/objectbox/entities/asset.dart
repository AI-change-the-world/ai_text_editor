import 'package:objectbox/objectbox.dart';

/// 资产类型枚举
enum AssetType {
  image,
  pdf,
  audio,
  video,
  other,
}

/// 资产实体
/// 工作空间中的非文档内容（图片、音频、视频、PDF等）
/// Requirements: 1.5, 3.1-3.4
@Entity()
class Asset {
  @Id()
  int id = 0;

  /// 唯一标识符
  @Unique()
  String uuid;

  /// 所属工作空间 ID
  @Index()
  String workspaceId;

  /// 资产名称
  String name;

  /// 文件路径
  String filePath;

  /// MIME 类型
  String mimeType;

  /// 文件大小 (字节)
  int fileSize;

  /// 资产类型 (存储为 int)
  int typeIndex;

  /// 提取的文本内容 (PDF 文本、OCR 结果、音频转写等)
  String? extractedText;

  /// 缩略图路径
  String? thumbnailPath;

  /// 创建时间 (毫秒时间戳)
  int createdAt;

  /// 更新时间 (毫秒时间戳)
  int updatedAt;

  Asset({
    this.id = 0,
    required this.uuid,
    required this.workspaceId,
    required this.name,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    this.typeIndex = 4, // AssetType.other
    this.extractedText,
    this.thumbnailPath,
    int? createdAt,
    int? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 获取资产类型
  AssetType get type => AssetType.values[typeIndex];

  /// 设置资产类型
  set type(AssetType value) {
    typeIndex = value.index;
  }

  /// 根据 MIME 类型推断资产类型
  static AssetType inferTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return AssetType.image;
    } else if (mimeType == 'application/pdf') {
      return AssetType.pdf;
    } else if (mimeType.startsWith('audio/')) {
      return AssetType.audio;
    } else if (mimeType.startsWith('video/')) {
      return AssetType.video;
    }
    return AssetType.other;
  }

  /// 创建空资产
  static Asset empty() {
    return Asset(
      uuid: '',
      workspaceId: '',
      name: '',
      filePath: '',
      mimeType: '',
      fileSize: 0,
    );
  }

  /// 复制并修改
  Asset copyWith({
    int? id,
    String? uuid,
    String? workspaceId,
    String? name,
    String? filePath,
    String? mimeType,
    int? fileSize,
    int? typeIndex,
    String? extractedText,
    String? thumbnailPath,
    int? createdAt,
    int? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      typeIndex: typeIndex ?? this.typeIndex,
      extractedText: extractedText ?? this.extractedText,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

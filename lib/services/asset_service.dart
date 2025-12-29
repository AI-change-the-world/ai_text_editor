import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/datasources/objectbox/objectbox.dart';
import '../objectbox.g.dart';

/// 资产上传请求
/// Requirements: 1.5
class UploadAssetRequest {
  final String workspaceId;
  final String name;
  final Uint8List data;
  final String mimeType;

  UploadAssetRequest({
    required this.workspaceId,
    required this.name,
    required this.data,
    required this.mimeType,
  });
}

/// 资产预览
/// Requirements: 3.4
class AssetPreview {
  final String assetId;
  final String name;
  final AssetType type;
  final String? thumbnailPath;
  final String? extractedText;
  final Map<String, dynamic> metadata;

  AssetPreview({
    required this.assetId,
    required this.name,
    required this.type,
    this.thumbnailPath,
    this.extractedText,
    this.metadata = const {},
  });
}

/// OCR 配置
class OCRConfig {
  final String apiKey;
  final String baseUrl;
  final String modelName;

  const OCRConfig({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.modelName = 'gpt-4o',
  });
}

/// 资产服务接口
/// Requirements: 1.5, 3.1-3.4
abstract class IAssetService {
  /// 上传资产
  /// Requirements: 1.5
  Future<Asset> uploadAsset(UploadAssetRequest request);

  /// 获取资产
  Future<Asset?> getAsset(String assetId);

  /// 删除资产
  Future<void> deleteAsset(String assetId);

  /// OCR 识别图片文字 (使用大模型 Vision API)
  /// Requirements: 3.2
  Future<String> ocrImage(String assetId);

  /// 直接对图片数据进行 OCR
  /// Requirements: 3.2
  Future<String> ocrImageData(Uint8List imageData, {String? mimeType});

  /// 获取资产预览
  /// Requirements: 3.4
  Future<AssetPreview> getAssetPreview(String assetId);

  /// 获取工作空间的所有资产
  Future<List<Asset>> getWorkspaceAssets(String workspaceId);

  /// 更新 OCR 配置
  void updateOCRConfig(OCRConfig config);
}

/// 资产服务实现
/// Requirements: 1.5, 3.2, 3.4
class AssetService implements IAssetService {
  final ObxDatabase _db;
  final Uuid _uuid = const Uuid();
  final http.Client _httpClient;
  OCRConfig _ocrConfig;

  AssetService(
    this._db, {
    OCRConfig? ocrConfig,
    http.Client? httpClient,
  })  : _ocrConfig = ocrConfig ?? const OCRConfig(),
        _httpClient = httpClient ?? http.Client();

  /// 获取单例实例
  static AssetService? _instance;

  /// 获取单例实例（懒加载）
  static AssetService get instance {
    _instance ??= AssetService(ObxDatabase.db);
    return _instance!;
  }

  /// 重置单例 (用于测试)
  static void resetInstance() {
    _instance = null;
  }

  @override
  void updateOCRConfig(OCRConfig config) {
    _ocrConfig = config;
  }

  /// 获取资产存储目录
  Future<Directory> _getAssetDirectory(String workspaceId) async {
    final appDir = await getApplicationSupportDirectory();
    final assetDir =
        Directory(p.join(appDir.path, 'AITextEditor', 'assets', workspaceId));
    if (!await assetDir.exists()) {
      await assetDir.create(recursive: true);
    }
    return assetDir;
  }

  /// 上传资产
  /// Requirements: 1.5
  @override
  Future<Asset> uploadAsset(UploadAssetRequest request) async {
    final assetId = _uuid.v4();
    final assetDir = await _getAssetDirectory(request.workspaceId);

    // 生成文件名
    final extension = _getExtensionFromMime(request.mimeType);
    final fileName = '$assetId$extension';
    final filePath = p.join(assetDir.path, fileName);

    // 保存文件
    final file = File(filePath);
    await file.writeAsBytes(request.data);

    // 推断资产类型
    final assetType = Asset.inferTypeFromMime(request.mimeType);

    // 创建资产记录
    final asset = Asset(
      uuid: assetId,
      workspaceId: request.workspaceId,
      name: request.name,
      filePath: filePath,
      mimeType: request.mimeType,
      fileSize: request.data.length,
      typeIndex: assetType.index,
    );

    // 保存到数据库
    _db.assetBox.put(asset);

    return asset;
  }

  /// 从 MIME 类型获取文件扩展名
  String _getExtensionFromMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/jpeg':
        return '.jpg';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'application/pdf':
        return '.pdf';
      case 'audio/mpeg':
        return '.mp3';
      case 'audio/wav':
        return '.wav';
      case 'video/mp4':
        return '.mp4';
      default:
        return '';
    }
  }

  /// 获取资产
  @override
  Future<Asset?> getAsset(String assetId) async {
    final query = _db.assetBox.query(Asset_.uuid.equals(assetId));
    final result = query.build().findFirst();
    query.build().close();
    return result;
  }

  /// 删除资产
  @override
  Future<void> deleteAsset(String assetId) async {
    final asset = await getAsset(assetId);
    if (asset == null) return;

    // 删除文件
    final file = File(asset.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // 删除缩略图
    if (asset.thumbnailPath != null) {
      final thumbnail = File(asset.thumbnailPath!);
      if (await thumbnail.exists()) {
        await thumbnail.delete();
      }
    }

    // 删除数据库记录
    _db.assetBox.remove(asset.id);
  }

  /// OCR 识别图片文字 (使用大模型 Vision API)
  /// Requirements: 3.2
  @override
  Future<String> ocrImage(String assetId) async {
    final asset = await getAsset(assetId);
    if (asset == null) {
      throw AssetException('Asset not found: $assetId');
    }

    if (asset.type != AssetType.image) {
      throw AssetException('Asset is not an image: ${asset.type}');
    }

    // 读取图片数据
    final file = File(asset.filePath);
    if (!await file.exists()) {
      throw AssetException('Asset file not found: ${asset.filePath}');
    }

    final imageData = await file.readAsBytes();
    final extractedText =
        await ocrImageData(imageData, mimeType: asset.mimeType);

    // 更新资产的提取文本
    asset.extractedText = extractedText;
    asset.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _db.assetBox.put(asset);

    return extractedText;
  }

  /// 直接对图片数据进行 OCR
  /// Requirements: 3.2
  @override
  Future<String> ocrImageData(Uint8List imageData, {String? mimeType}) async {
    if (_ocrConfig.apiKey.isEmpty) {
      throw AssetException('OCR API key not configured');
    }

    final base64Image = base64Encode(imageData);
    final mediaType = mimeType ?? 'image/png';

    final url = Uri.parse('${_ocrConfig.baseUrl}/chat/completions');

    final response = await _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_ocrConfig.apiKey}',
      },
      body: jsonEncode({
        'model': _ocrConfig.modelName,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    '请识别这张图片中的所有文字内容，并按照原始布局格式输出。如果图片中没有文字，请回复"图片中没有检测到文字"。',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mediaType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 4096,
      }),
    );

    if (response.statusCode != 200) {
      throw AssetException(
        'OCR API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    return content;
  }

  /// 获取资产预览
  /// Requirements: 3.4
  @override
  Future<AssetPreview> getAssetPreview(String assetId) async {
    final asset = await getAsset(assetId);
    if (asset == null) {
      throw AssetException('Asset not found: $assetId');
    }

    return AssetPreview(
      assetId: asset.uuid,
      name: asset.name,
      type: asset.type,
      thumbnailPath: asset.thumbnailPath,
      extractedText: asset.extractedText,
      metadata: {
        'fileSize': asset.fileSize,
        'mimeType': asset.mimeType,
        'createdAt': asset.createdAt,
        'updatedAt': asset.updatedAt,
      },
    );
  }

  /// 获取工作空间的所有资产
  @override
  Future<List<Asset>> getWorkspaceAssets(String workspaceId) async {
    final query = _db.assetBox
        .query(Asset_.workspaceId.equals(workspaceId))
        .order(Asset_.createdAt, flags: Order.descending);
    final results = query.build().find();
    query.build().close();
    return results;
  }
}

/// 资产异常
class AssetException implements Exception {
  final String message;

  AssetException(this.message);

  @override
  String toString() => 'AssetException: $message';
}

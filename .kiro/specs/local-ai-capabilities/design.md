# Design Document: 内容采集工具

## Overview

本设计文档描述了内容采集工具层的技术实现，包括语音转录工具和深度搜索工具的优化。这些工具作为独立模块，负责从外部来源采集内容并以标准化格式保存到工作空间。

### 设计目标

1. **模块化**: 每个工具独立，可单独开发和测试
2. **标准化输出**: 所有工具输出统一格式，便于工作空间处理
3. **离线优先**: 语音转录支持本地处理，保护隐私
4. **无缝集成**: 工具与工作空间紧密集成，一键保存

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  VoiceToolView  │  │ DeepSearchView  │  │  WorkspaceView  │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
└───────────┼─────────────────────┼─────────────────────┼──────────┘
            │                     │                     │
┌───────────┼─────────────────────┼─────────────────────┼──────────┐
│           ▼                     ▼                     │          │
│  ┌─────────────────┐  ┌─────────────────┐            │          │
│  │VoiceToolNotifier│  │SearchToolNotifier│            │          │
│  └────────┬────────┘  └────────┬────────┘            │          │
│           │                     │                     │          │
│           ▼                     ▼                     ▼          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    ContentToolOutput                      │   │
│  │  { body, sourceType, metadata, timestamp, summary? }     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   WorkspaceService                        │   │
│  │              saveContent(output, workspaceId)             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         State Layer                              │
└──────────────────────────────────────────────────────────────────┘
            │
┌───────────┼──────────────────────────────────────────────────────┐
│           ▼                                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │
│  │  LocalASRService│  │  CloudASRService│  │ SummaryService  │   │
│  │  (sherpa_onnx)  │  │  (OpenAI etc.)  │  │                 │   │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘   │
│                         Service Layer                             │
└───────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. ContentToolOutput - 标准化输出格式

所有内容采集工具的输出都遵循此格式：

```dart
/// 内容来源类型
enum ContentSourceType {
  transcription,  // 语音转录
  deepSearch,     // 深度搜索
  manual,         // 手动创建
  import,         // 文件导入
}

/// 内容工具标准输出
class ContentToolOutput {
  /// 内容主体 (Markdown 格式)
  final String body;
  
  /// 来源类型
  final ContentSourceType sourceType;
  
  /// 来源元数据
  final ContentMetadata metadata;
  
  /// 创建时间
  final DateTime timestamp;
  
  /// 可选的摘要
  final String? summary;
  
  /// 可选的标题
  final String? title;
}

/// 内容元数据
class ContentMetadata {
  /// 来源 URL (深度搜索)
  final String? sourceUrl;
  
  /// 音频文件名 (语音转录)
  final String? audioFileName;
  
  /// 音频时长
  final Duration? audioDuration;
  
  /// 转录引擎 (local/cloud)
  final String? transcriptionEngine;
  
  /// 搜索关键词
  final String? searchQuery;
  
  /// 额外元数据
  final Map<String, dynamic> extra;
}
```

### 2. VoiceToolService - 语音转录服务

```dart
/// 转录配置
class TranscriptionConfig {
  /// 使用本地引擎
  final bool preferLocal;
  
  /// 语言
  final String language; // 'zh', 'en'
  
  /// 是否生成时间戳
  final bool withTimestamps;
  
  /// 转录模式
  final TranscriptionMode mode;
}

/// 转录进度
class TranscriptionProgress {
  final double progress; // 0.0 - 1.0
  final String? currentText;
  final Duration? processedDuration;
}

/// 转录结果
class TranscriptionResult {
  final String text;
  final List<TimestampedSegment>? segments;
  final Duration duration;
  final String engine; // 'local' or 'cloud'
}

/// 转录模式
enum TranscriptionMode {
  /// 非流式：处理完整音频文件后返回结果
  offline,
  /// 流式：实时处理音频流，边录边转
  streaming,
}

/// 流式转录事件
class StreamingTranscriptionEvent {
  /// 当前识别的文本片段
  final String text;
  /// 是否为最终结果（非中间结果）
  final bool isFinal;
  /// 时间戳
  final Duration timestamp;
}

/// 语音转录服务接口
abstract class VoiceToolService {
  /// 支持的音频格式
  List<String> get supportedFormats;
  
  /// 检查本地引擎是否可用
  Future<bool> isLocalEngineAvailable();
  
  /// 非流式转录：处理音频文件
  Stream<TranscriptionProgress> transcribeFile(
    String audioPath,
    TranscriptionConfig config,
  );
  
  /// 流式转录：开始实时识别
  Future<void> startStreamingTranscription(TranscriptionConfig config);
  
  /// 流式转录：输入音频数据
  Future<void> feedAudioData(Uint8List audioData);
  
  /// 流式转录：获取实时结果流
  Stream<StreamingTranscriptionEvent> get streamingResults;
  
  /// 流式转录：停止并获取最终结果
  Future<TranscriptionResult> stopStreamingTranscription();
  
  /// 获取转录结果（非流式模式）
  Future<TranscriptionResult> getResult();
  
  /// 取消转录
  Future<void> cancel();
}
```

### 3. LocalASRService - 本地语音识别服务

```dart
/// ASR 模型信息
class ASRModel {
  final String id;
  final String name;
  final String language;
  final int sizeBytes;
  final bool isDownloaded;
  final String? localPath;
  /// 是否支持流式识别
  final bool supportsStreaming;
}

/// 本地 ASR 服务 (基于 sherpa_onnx)
class LocalASRService implements VoiceToolService {
  /// 获取可用模型列表
  Future<List<ASRModel>> getAvailableModels();
  
  /// 下载模型
  Stream<double> downloadModel(String modelId);
  
  /// 删除模型
  Future<void> deleteModel(String modelId);
  
  /// 加载模型（指定模式）
  Future<void> loadModel(String modelId, {TranscriptionMode mode = TranscriptionMode.offline});
  
  /// 卸载模型
  Future<void> unloadModel();
  
  /// 获取当前加载的模型
  ASRModel? get currentModel;
  
  /// 检查当前模型是否支持流式
  bool get supportsStreaming;
}
```

### 4. DeepSearchService - 深度搜索服务增强

```dart
/// 搜索结果保存请求
class SaveSearchResultRequest {
  final List<SearchResult> results;
  final String workspaceId;
  final bool generateSummary;
}

/// 深度搜索服务扩展
extension DeepSearchSaveExtension on DeepSearchService {
  /// 保存搜索结果到工作空间
  Future<List<String>> saveToWorkspace(SaveSearchResultRequest request);
  
  /// 获取搜索历史
  Future<List<SearchHistoryItem>> getSearchHistory({int limit = 10});
  
  /// 清除搜索历史
  Future<void> clearSearchHistory();
}

/// 搜索历史项
class SearchHistoryItem {
  final String query;
  final DateTime timestamp;
  final int resultCount;
}
```

### 5. WorkspaceService - 工作空间服务扩展

```dart
/// 工作空间服务扩展
extension WorkspaceContentExtension on WorkspaceService {
  /// 从工具输出创建文档
  Future<String> createFromToolOutput(
    ContentToolOutput output,
    String workspaceId,
  );
  
  /// 按来源类型筛选文档
  Future<List<Document>> filterBySourceType(
    String workspaceId,
    ContentSourceType type,
  );
  
  /// 获取文档来源信息
  Future<ContentMetadata?> getDocumentMetadata(String documentId);
}
```

## Data Models

### 文档元数据扩展

```dart
/// 扩展 DocumentMeta 实体
@Entity()
class DocumentMeta {
  // ... 现有字段 ...
  
  /// 内容来源类型
  String? sourceType;
  
  /// 来源元数据 JSON
  String? sourceMetadataJson;
  
  /// 关联文档 ID (如转录和摘要的关联)
  String? relatedDocumentId;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Audio Format Support
*For any* audio file with extension in {mp3, wav, m4a, flac}, the Voice_Tool import operation should succeed and return a valid file handle.
**Validates: Requirements 1.3**

### Property 2: Workspace Save Consistency
*For any* ContentToolOutput and valid workspace ID, saving the output should create a document in that workspace with matching content and metadata.
**Validates: Requirements 1.6, 5.3**

### Property 3: Transcription Progress Monotonicity
*For any* transcription operation, the progress values emitted should be monotonically increasing from 0.0 to 1.0.
**Validates: Requirements 2.5**

### Property 4: Streaming Transcription Ordering
*For any* streaming transcription session, the events should be emitted in chronological order (timestamp[i] <= timestamp[i+1]), and final results should not be followed by non-final results for the same segment.
**Validates: Requirements 1.4**

### Property 5: Summary Length Ordering
*For any* transcript content, generating summaries with different length settings should produce outputs where: length(brief) < length(standard) < length(detailed).
**Validates: Requirements 3.4**

### Property 6: Search History Persistence
*For any* sequence of N distinct searches, the search history should contain at most N items, ordered by recency.
**Validates: Requirements 4.5**

### Property 7: Batch Save Cardinality
*For any* batch save operation with N selected results, exactly N documents should be created in the target workspace.
**Validates: Requirements 5.4**

### Property 8: Tool Output Completeness
*For any* ContentToolOutput, the fields {body, sourceType, metadata, timestamp} must be non-null and sourceType must be a valid enum value.
**Validates: Requirements 6.1, 6.2**

### Property 9: Source Type Filtering
*For any* workspace with documents of mixed source types, filtering by type X should return only documents where sourceType equals X.
**Validates: Requirements 6.4**

## Error Handling

### 语音转录错误

| 错误类型               | 处理方式                   |
| ---------------------- | -------------------------- |
| 不支持的音频格式       | 显示支持格式列表，建议转换 |
| 模型未下载             | 提示下载或切换到云端       |
| 模型加载失败           | 自动回退到云端，显示提示   |
| 网络不可用且无本地模型 | 显示错误，建议下载模型     |
| 转录超时               | 允许重试或取消             |

### 深度搜索错误

| 错误类型       | 处理方式                   |
| -------------- | -------------------------- |
| 网络错误       | 显示重试选项               |
| 内容提取失败   | 保存原始 URL，标记提取失败 |
| 工作空间不存在 | 提示选择其他工作空间       |
| 保存失败       | 显示错误详情，允许重试     |

## Testing Strategy

### 单元测试

- ContentToolOutput 序列化/反序列化
- 音频格式验证逻辑
- 搜索历史管理
- 元数据解析

### 属性测试

使用 `fast_check` 或类似库进行属性测试：

- Property 1-8 的自动化验证
- 随机输入生成和边界测试

### 集成测试

- 语音转录端到端流程
- 深度搜索保存流程
- 工作空间筛选功能

### 模拟测试

- 网络断开场景
- 模型加载失败场景
- 大文件处理场景

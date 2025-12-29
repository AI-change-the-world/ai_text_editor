# Design Document: 智能知识工作台 (Knowledge Workspace Platform)

## Overview

本设计文档描述将现有 AI Text Editor 升级为「智能知识工作台」的技术方案。该平台基于 Flutter 构建，支持 macOS、Windows、Linux 桌面端，核心特性包括：

- **多工作空间管理**: 用户可创建多个独立的知识域，每个空间自动具备搜索和 AI 能力
- **多模态内容处理**: 支持文档、图片、PDF、音频等多种内容类型的统一管理和检索
- **智能检索**: 基于向量数据库的语义搜索和 RAG 问答，支持跨空间检索
- **全局 AI 助手**: 随时可用的 AI 入口，支持多模型配置和范围选择
- **Deep Search**: 内嵌 WebView 实现网页搜索和内容提取

### 技术栈选型

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| UI 框架 | Flutter 3.x | 跨平台桌面应用 |
| 状态管理 | Riverpod | 现有项目已使用 |
| 富文本编辑 | flutter_quill | 现有项目已使用 |
| 本地数据库 | ObjectBox | 现有项目已使用，支持向量检索和全文检索 |
| 向量检索 | ObjectBox Vector Search | ObjectBox 内置 HNSW 向量索引 |
| 全文检索 | ObjectBox Full-Text Search | ObjectBox 内置 FTS 支持 |
| WebView | webview_flutter | Deep Search 功能 |
| PDF 处理 | syncfusion_flutter_pdf / pdf_text | PDF 文本提取 |
| OCR | google_mlkit_text_recognition | 图片文字识别 |
| 音频转写 | whisper.cpp (via FFI) | 本地语音转文字 |
| Rust 集成 | flutter_rust_bridge | 现有项目已使用，用于高性能计算 |



## Architecture

### 整体架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Presentation Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Workspace  │  │   Editor    │  │  AI Panel   │  │   Search    │    │
│  │  Selector   │  │   View      │  │   View      │  │   View      │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Settings   │  │   Tools     │  │ Deep Search │  │   Asset     │    │
│  │   View      │  │   View      │  │   View      │  │  Viewer     │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           State Management (Riverpod)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Workspace  │  │   Editor    │  │     AI      │  │   Search    │    │
│  │  Notifier   │  │  Notifier   │  │  Notifier   │  │  Notifier   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Service Layer                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │  Workspace  │  │  Document   │  │     AI      │  │   Search    │    │
│  │  Service    │  │  Service    │  │   Service   │  │  Service    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Asset     │  │  Indexing   │  │  Embedding  │  │   Export    │    │
│  │  Service    │  │  Service    │  │  Service    │  │  Service    │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Data Layer                                     │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────┐ │
│  │     ObjectBox       │  │   ObjectBox FTS     │  │  File System    │ │
│  │  (Structured Data)  │  │  + Vector Search    │  │  (Assets)       │ │
│  │  - Workspaces       │  │  - Full-text Index  │  │  - Documents    │ │
│  │  - Documents Meta   │  │  - Vector Index     │  │  - Images       │ │
│  │  - Model Configs    │  │  - HNSW Embeddings  │  │  - PDFs         │ │
│  │  - Chat History     │  │                     │  │  - Audio        │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           External Services                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   OpenAI    │  │  Anthropic  │  │  DeepSeek   │  │   Ollama    │    │
│  │    API      │  │    API      │  │    API      │  │   (Local)   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 目录结构设计

```
lib/
├── main.dart
├── app.dart                      # App 入口和路由配置
├── core/                         # 核心基础设施
│   ├── config/                   # 应用配置
│   ├── constants/                # 常量定义
│   ├── extensions/               # Dart 扩展方法
│   ├── utils/                    # 工具函数
│   └── errors/                   # 错误处理
├── data/                         # 数据层
│   ├── models/                   # 数据模型
│   │   ├── workspace.dart
│   │   ├── document.dart
│   │   ├── asset.dart
│   │   ├── model_profile.dart
│   │   └── chat_history.dart
│   ├── repositories/             # 数据仓库
│   │   ├── workspace_repository.dart
│   │   ├── document_repository.dart
│   │   └── search_repository.dart
│   └── datasources/              # 数据源
│       ├── objectbox/            # ObjectBox 实体和数据库
│       │   ├── entities/         # 实体定义
│       │   ├── vector_search.dart # 向量搜索封装
│       │   └── full_text_search.dart # 全文搜索封装
│       └── filesystem/           # 文件系统操作
├── services/                     # 业务服务层
│   ├── workspace_service.dart
│   ├── document_service.dart
│   ├── ai_service.dart
│   ├── search_service.dart
│   ├── indexing_service.dart
│   ├── embedding_service.dart
│   ├── asset_service.dart
│   └── export_service.dart
├── features/                     # 功能模块 (按功能组织)
│   ├── workspace/                # 工作空间模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   └── widgets/
│   ├── editor/                   # 编辑器模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   ├── widgets/
│   │   └── embeds/               # 自定义嵌入组件
│   ├── ai_assistant/             # AI 助手模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   └── widgets/
│   ├── search/                   # 搜索模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   └── widgets/
│   ├── deep_search/              # Deep Search 模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   └── widgets/
│   ├── settings/                 # 设置模块
│   │   ├── notifiers/
│   │   ├── views/
│   │   └── widgets/
│   └── tools/                    # 工具模块
│       ├── mindmap/
│       ├── kanban/
│       └── pomodoro/
└── shared/                       # 共享组件
    ├── widgets/                  # 通用 UI 组件
    ├── dialogs/                  # 对话框
    └── themes/                   # 主题定义
```



## Components and Interfaces

### 1. 工作空间管理组件

```dart
/// 工作空间服务接口
abstract class IWorkspaceService {
  /// 获取所有工作空间
  Future<List<Workspace>> getAllWorkspaces();
  
  /// 创建新工作空间
  Future<Workspace> createWorkspace(CreateWorkspaceRequest request);
  
  /// 切换当前工作空间
  Future<void> switchWorkspace(String workspaceId);
  
  /// 获取当前活动工作空间
  Workspace? get currentWorkspace;
  
  /// 更新工作空间信息
  Future<void> updateWorkspace(String id, UpdateWorkspaceRequest request);
  
  /// 归档工作空间
  Future<void> archiveWorkspace(String workspaceId);
  
  /// 置顶/取消置顶工作空间
  Future<void> togglePinWorkspace(String workspaceId);
  
  /// 获取工作空间统计信息
  Future<WorkspaceStats> getWorkspaceStats(String workspaceId);
}
```

### 2. 文档服务组件

```dart
/// 文档服务接口
abstract class IDocumentService {
  /// 创建新文档
  Future<Document> createDocument(String workspaceId, CreateDocumentRequest request);
  
  /// 获取文档内容
  Future<Document> getDocument(String documentId);
  
  /// 保存文档
  Future<void> saveDocument(String documentId, DocumentContent content);
  
  /// 删除文档
  Future<void> deleteDocument(String documentId);
  
  /// 移动文档到其他文件夹
  Future<void> moveDocument(String documentId, String targetFolderId);
  
  /// 导出文档
  Future<Uint8List> exportDocument(String documentId, ExportFormat format);
  
  /// 导入外部文件
  Future<Document> importFile(String workspaceId, File file);
}
```

### 3. AI 服务组件

```dart
/// AI 服务接口
abstract class IAIService {
  /// 获取所有模型配置
  Future<List<ModelProfile>> getModelProfiles();
  
  /// 创建模型配置
  Future<ModelProfile> createModelProfile(CreateModelProfileRequest request);
  
  /// 获取指定任务的模型
  ModelProfile? getModelForTask(AITask task);
  
  /// 流式聊天
  Stream<String> streamChat(ChatRequest request);
  
  /// RAG 问答 (带知识库检索)
  Stream<RAGResponse> ragQuery(RAGQueryRequest request);
  
  /// 文本嵌入
  Future<List<double>> getEmbedding(String text);
  
  /// 图片分析 (Vision)
  Future<String> analyzeImage(Uint8List imageData, String prompt);
}

/// AI 任务类型
enum AITask {
  writing,      // 写作
  qa,           // 问答
  translation,  // 翻译
  summarization,// 摘要
  code,         // 代码
}
```

### 4. 搜索服务组件

```dart
/// 搜索服务接口
abstract class ISearchService {
  /// 全文搜索
  Future<SearchResult> fullTextSearch(FullTextSearchRequest request);
  
  /// 语义搜索
  Future<SearchResult> semanticSearch(SemanticSearchRequest request);
  
  /// 混合搜索 (全文 + 语义)
  Future<SearchResult> hybridSearch(HybridSearchRequest request);
  
  /// 获取搜索建议
  Future<List<SearchSuggestion>> getSuggestions(String query);
  
  /// 保存搜索查询
  Future<void> saveSearchQuery(String query, String name);
  
  /// 获取已保存的搜索
  Future<List<SavedSearch>> getSavedSearches();
}

/// 搜索请求基类
class SearchRequest {
  final String query;
  final List<String> workspaceIds;  // 空表示当前工作空间
  final SearchFilters? filters;
  final int limit;
  final int offset;
}

/// 搜索结果
class SearchResult {
  final List<SearchResultItem> items;
  final int totalCount;
  final Map<String, int> workspaceCounts;  // 按工作空间分组的数量
}

/// 搜索结果项
class SearchResultItem {
  final String workspaceId;
  final String workspaceName;
  final String documentId;
  final String documentTitle;
  final String documentPath;
  final String snippet;           // 匹配片段
  final List<int> highlightRanges; // 高亮位置
  final double score;             // 相关性分数
  final DateTime lastModified;
}
```

### 5. 索引服务组件

```dart
/// 索引服务接口
abstract class IIndexingService {
  /// 索引单个文档
  Future<void> indexDocument(Document document);
  
  /// 批量索引文档
  Future<void> indexDocuments(List<Document> documents);
  
  /// 删除文档索引
  Future<void> removeDocumentIndex(String documentId);
  
  /// 重建工作空间索引
  Future<void> rebuildWorkspaceIndex(String workspaceId);
  
  /// 获取索引状态
  Future<IndexStatus> getIndexStatus(String workspaceId);
  
  /// 索引资产 (PDF, 图片等)
  Future<void> indexAsset(Asset asset);
}

/// 索引状态
class IndexStatus {
  final int totalDocuments;
  final int indexedDocuments;
  final int pendingDocuments;
  final DateTime lastUpdated;
  final bool isIndexing;
}
```

### 6. 资产服务组件

```dart
/// 资产服务接口
abstract class IAssetService {
  /// 上传资产
  Future<Asset> uploadAsset(String workspaceId, File file);
  
  /// 获取资产
  Future<Asset> getAsset(String assetId);
  
  /// 删除资产
  Future<void> deleteAsset(String assetId);
  
  /// 提取 PDF 文本
  Future<String> extractPdfText(String assetId);
  
  /// OCR 识别图片文字
  Future<String> ocrImage(String assetId);
  
  /// 转写音频
  Future<String> transcribeAudio(String assetId);
  
  /// 获取资产预览
  Future<AssetPreview> getAssetPreview(String assetId);
}
```



## Data Models

### ObjectBox 实体模型

```dart
/// 工作空间实体
@Entity()
class Workspace {
  @Id()
  int id = 0;
  
  @Unique()
  String uuid;
  
  String name;
  String? description;
  String? icon;           // emoji 或图标名称
  String? colorTheme;     // 主题色 hex
  String? category;       // 分类标签
  
  bool isPinned = false;
  bool isArchived = false;
  
  int createdAt;
  int updatedAt;
  int lastAccessedAt;
  
  /// 关联的文档
  @Backlink('workspace')
  final documents = ToMany<DocumentMeta>();
  
  /// 关联的资产
  @Backlink('workspace')
  final assets = ToMany<Asset>();
}

/// 文档元数据实体
@Entity()
class DocumentMeta {
  @Id()
  int id = 0;
  
  @Unique()
  String uuid;
  
  String title;
  String? parentFolderId;  // 父文件夹 ID，null 表示根目录
  String filePath;         // 文档文件路径
  
  int wordCount = 0;
  int characterCount = 0;
  
  bool isFolder = false;   // 是否为文件夹
  int sortOrder = 0;       // 排序顺序
  
  int createdAt;
  int updatedAt;
  
  /// 所属工作空间
  final workspace = ToOne<Workspace>();
  
  /// 标签
  List<String> tags = [];
}

/// 资产实体
@Entity()
class Asset {
  @Id()
  int id = 0;
  
  @Unique()
  String uuid;
  
  String name;
  String filePath;
  String mimeType;
  int fileSize;
  
  AssetType type;          // image, pdf, audio, video
  String? extractedText;   // 提取的文本内容
  String? thumbnailPath;   // 缩略图路径
  
  int createdAt;
  int updatedAt;
  
  /// 所属工作空间
  final workspace = ToOne<Workspace>();
}

/// 资产类型枚举
enum AssetType {
  image,
  pdf,
  audio,
  video,
  other,
}

/// 模型配置实体
@Entity()
class ModelProfile {
  @Id()
  int id = 0;
  
  @Unique()
  String uuid;
  
  String name;
  String provider;         // openai, anthropic, deepseek, ollama
  String modelName;        // gpt-4, claude-3, etc.
  String? apiKey;          // 加密存储
  String? baseUrl;         // 自定义 API 地址
  
  AITask taskType;         // 任务类型
  bool isDefault = false;  // 是否为该任务的默认模型
  
  double temperature = 0.7;
  int maxTokens = 4096;
  String? systemPrompt;
  
  int createdAt;
  int updatedAt;
}

/// 聊天历史实体
@Entity()
class ChatHistory {
  @Id()
  int id = 0;
  
  @Unique()
  String uuid;
  
  String? workspaceId;     // 关联的工作空间
  String? documentId;      // 关联的文档
  
  String title;            // 对话标题
  
  int createdAt;
  int updatedAt;
  
  /// 消息列表
  @Backlink('chatHistory')
  final messages = ToMany<ChatMessage>();
}

/// 聊天消息实体
@Entity()
class ChatMessage {
  @Id()
  int id = 0;
  
  String role;             // user, assistant, system
  String content;
  
  List<String>? citations; // 来源引用 (文档ID列表)
  
  int createdAt;
  
  /// 所属对话
  final chatHistory = ToOne<ChatHistory>();
}

/// 保存的搜索实体
@Entity()
class SavedSearch {
  @Id()
  int id = 0;
  
  String name;
  String query;
  String? filtersJson;     // 序列化的过滤条件
  
  int createdAt;
  int usedCount = 0;
  int lastUsedAt;
}
```

### ObjectBox 向量检索和全文检索实体

```dart
/// 文档内容实体 (支持全文检索)
@Entity()
class DocumentContent {
  @Id()
  int id = 0;
  
  @Unique()
  String documentId;
  
  String workspaceId;
  
  /// 文档标题
  String title;
  
  /// 文档内容
  String content;
  
  /// 标签
  List<String> tags = [];
  
  int updatedAt;
}

/// 文档向量块实体 (用于语义搜索)
@Entity()
class DocumentChunk {
  @Id()
  int id = 0;
  
  String documentId;
  String workspaceId;
  
  int chunkIndex;
  String chunkText;
  
  /// 向量嵌入 - 使用 ObjectBox HNSW 索引
  @HnswIndex(dimensions: 1536, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;
  
  int createdAt;
}

/// 搜索缓存实体
@Entity()
class SearchCache {
  @Id()
  int id = 0;
  
  @Unique()
  String queryHash;
  
  String workspaceIds;
  String resultJson;
  
  int createdAt;
  int expiresAt;
}
```

### ObjectBox 查询示例

```dart
/// 向量相似度搜索 (使用 ObjectBox HNSW)
Future<List<DocumentChunk>> semanticSearch(
  List<double> queryEmbedding,
  String workspaceId,
  {int limit = 10}
) async {
  final query = chunkBox.query(
    DocumentChunk_.workspaceId.equals(workspaceId)
  )
  .order(DocumentChunk_.embedding.nearestNeighborsF32(queryEmbedding, limit))
  .build();
  
  return query.find();
}

/// 跨工作空间向量搜索
Future<List<DocumentChunk>> crossWorkspaceSemanticSearch(
  List<double> queryEmbedding,
  List<String> workspaceIds,
  {int limit = 10}
) async {
  final query = chunkBox.query(
    DocumentChunk_.workspaceId.oneOf(workspaceIds)
  )
  .order(DocumentChunk_.embedding.nearestNeighborsF32(queryEmbedding, limit))
  .build();
  
  return query.find();
}

/// 全文搜索 (使用 ObjectBox 条件查询)
Future<List<DocumentContent>> fullTextSearch(
  String keyword,
  String workspaceId,
) async {
  final query = contentBox.query(
    DocumentContent_.workspaceId.equals(workspaceId) &
    (DocumentContent_.title.contains(keyword, caseSensitive: false) |
     DocumentContent_.content.contains(keyword, caseSensitive: false))
  ).build();
  
  return query.find();
}

/// 跨工作空间全文搜索
Future<List<DocumentContent>> crossWorkspaceFullTextSearch(
  String keyword,
  List<String> workspaceIds,
) async {
  final query = contentBox.query(
    DocumentContent_.workspaceId.oneOf(workspaceIds) &
    (DocumentContent_.title.contains(keyword, caseSensitive: false) |
     DocumentContent_.content.contains(keyword, caseSensitive: false))
  ).build();
  
  return query.find();
}
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Workspace ID Uniqueness
*For any* sequence of workspace creation operations, each created workspace should have a unique UUID that does not collide with any existing workspace.
**Validates: Requirements 1.2**

### Property 2: Workspace Data Persistence
*For any* workspace creation request with valid name, icon, color theme, description, and category, after creation, querying the workspace should return all the provided fields unchanged.
**Validates: Requirements 1.2**

### Property 3: Workspace Switch Context Consistency
*For any* workspace switch operation, the current workspace state should reflect the switched workspace's ID, and subsequent search/AI operations should use this workspace as the default scope.
**Validates: Requirements 1.3**

### Property 4: Pinned Workspace Ordering
*For any* list of workspaces where some are pinned and some are not, the sorted workspace list should always show all pinned workspaces before any unpinned workspaces.
**Validates: Requirements 1.9**

### Property 5: Document Index Consistency
*For any* document added to a workspace, after indexing completes, a full-text search for unique terms in that document should return that document in the results.
**Validates: Requirements 4.2, 5.4**

### Property 6: Vector Embedding Existence
*For any* workspace with documents, after indexing, each document should have corresponding vector embeddings in the vector store.
**Validates: Requirements 4.1, 4.2**

### Property 7: Semantic Search Scope Isolation
*For any* semantic search with a single workspace scope, all returned results should belong to that workspace only.
**Validates: Requirements 4.3**

### Property 8: Cross-Workspace Search Completeness
*For any* search across multiple specified workspaces, the results should include matches from all specified workspaces (if matches exist), and results should be grouped by workspace.
**Validates: Requirements 4.6, 5.5**

### Property 9: Search Result Citation Validity
*For any* search result item, the cited document ID should correspond to an existing document, and the snippet should be a substring of that document's content.
**Validates: Requirements 4.5, 7.10**

### Property 10: Advanced Search Query Parsing
*For any* search query with operators (AND, OR, NOT, quotes, workspace:, tag:), the parsed query should correctly identify all operators and operands, and the search results should satisfy the logical constraints.
**Validates: Requirements 5.8**

### Property 11: Model Profile Persistence
*For any* model profile creation with provider, model name, API key, and parameters, querying the profile should return all fields unchanged (except API key which may be encrypted).
**Validates: Requirements 7.5**

### Property 12: PDF Text Extraction Non-Empty
*For any* PDF file containing visible text, the text extraction function should return a non-empty string.
**Validates: Requirements 3.1**

### Property 13: HTML Content Extraction
*For any* valid HTML document with a main content area, the content extraction function should return the main text content without HTML tags.
**Validates: Requirements 6.4**

### Property 14: Document Export Round-Trip (Markdown)
*For any* document, exporting to Markdown and then importing the Markdown should produce a document with equivalent content structure.
**Validates: Requirements 1.7**



## Error Handling

### 错误分类

| 错误类型 | 处理策略 | 用户提示 |
|----------|----------|----------|
| 网络错误 | 重试 3 次，指数退避 | "网络连接失败，正在重试..." |
| API 限流 | 等待后重试，切换备用模型 | "请求过于频繁，请稍后再试" |
| API Key 无效 | 提示用户检查配置 | "API 密钥无效，请检查设置" |
| 文件读取失败 | 记录日志，跳过该文件 | "无法读取文件: {filename}" |
| 索引失败 | 标记文档为待索引，后台重试 | 静默处理，不打扰用户 |
| 数据库错误 | 尝试恢复，失败则提示 | "数据存储错误，请重启应用" |
| 内存不足 | 释放缓存，降级处理 | "内存不足，部分功能可能受限" |

### 错误恢复机制

```dart
/// 统一错误处理
class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  AppError({
    required this.type,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });
}

enum ErrorType {
  network,
  apiRateLimit,
  apiKeyInvalid,
  fileAccess,
  indexing,
  database,
  memory,
  unknown,
}

/// 错误处理服务
class ErrorHandlingService {
  /// 处理错误并返回用户友好的消息
  String handleError(AppError error) {
    // 记录日志
    _logError(error);
    
    // 尝试恢复
    _attemptRecovery(error);
    
    // 返回用户消息
    return error.userMessage ?? _getDefaultMessage(error.type);
  }
  
  /// 带重试的操作执行
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(initialDelay * attempt);
      }
    }
  }
}
```

## Testing Strategy

### 测试框架选择

- **单元测试**: `flutter_test` + `mocktail`
- **属性测试**: `glados` (Dart property-based testing library)
- **集成测试**: `integration_test`

### 单元测试覆盖

| 模块 | 测试重点 |
|------|----------|
| WorkspaceService | CRUD 操作、切换逻辑、排序 |
| DocumentService | 创建、保存、导入导出 |
| SearchService | 查询解析、结果排序、过滤 |
| IndexingService | 索引创建、更新、删除 |
| AIService | 模型选择、请求构建、响应解析 |
| EmbeddingService | 向量生成、相似度计算 |

### 属性测试策略

使用 `glados` 库进行属性测试，每个属性测试运行至少 100 次迭代。

```dart
// 示例：工作空间 ID 唯一性测试
// **Feature: knowledge-workspace-platform, Property 1: Workspace ID Uniqueness**
void main() {
  Glados<List<CreateWorkspaceRequest>>().test(
    'created workspaces should have unique IDs',
    (requests) async {
      final service = WorkspaceService();
      final workspaces = <Workspace>[];
      
      for (final request in requests) {
        final workspace = await service.createWorkspace(request);
        workspaces.add(workspace);
      }
      
      final ids = workspaces.map((w) => w.uuid).toSet();
      expect(ids.length, equals(workspaces.length));
    },
  );
}
```

### 集成测试场景

1. **工作空间生命周期**: 创建 → 编辑 → 切换 → 归档
2. **文档编辑流程**: 创建 → 编辑 → 保存 → 搜索
3. **跨空间搜索**: 多空间创建 → 添加文档 → 跨空间搜索
4. **AI 问答流程**: 添加文档 → 索引 → RAG 问答 → 验证引用
5. **导入导出**: 导入 Markdown → 编辑 → 导出 PDF



## AI Agent & Tool System

### Tool 系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AI Agent Layer                                 │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Agent Orchestrator                          │   │
│  │  - 任务规划 (Task Planning)                                      │   │
│  │  - 工具选择 (Tool Selection)                                     │   │
│  │  - 结果整合 (Result Aggregation)                                 │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Tool Registry                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │FullTextTool │  │ VectorTool  │  │DeepSearchTool│ │DocumentTool │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ SummaryTool │  │TranslateTool│  │  CodeTool   │  │ ImageTool   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Tool 接口定义

```dart
/// Tool 基础接口
abstract class ITool {
  /// 工具名称
  String get name;
  
  /// 工具描述 (供 LLM 理解)
  String get description;
  
  /// 参数 Schema (JSON Schema 格式)
  Map<String, dynamic> get parametersSchema;
  
  /// 执行工具
  Future<ToolResult> execute(Map<String, dynamic> parameters);
}

/// 工具执行结果
class ToolResult {
  final bool success;
  final dynamic data;
  final String? error;
  final List<SourceCitation>? citations;
  
  ToolResult({
    required this.success,
    this.data,
    this.error,
    this.citations,
  });
}

/// 来源引用
class SourceCitation {
  final String workspaceId;
  final String workspaceName;
  final String documentId;
  final String documentTitle;
  final String snippet;
  final int? startOffset;
  final int? endOffset;
}
```

### 核心 Tool 实现

```dart
/// 1. 全文检索工具
class FullTextSearchTool implements ITool {
  @override
  String get name => 'full_text_search';
  
  @override
  String get description => '''
在知识库中进行关键词搜索。支持以下功能：
- 在当前工作空间或指定工作空间中搜索
- 支持 AND、OR、NOT 等高级搜索语法
- 返回匹配的文档片段和来源信息
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': '搜索关键词或查询语句',
      },
      'workspace_ids': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': '要搜索的工作空间ID列表，为空则搜索当前工作空间',
      },
      'limit': {
        'type': 'integer',
        'default': 10,
        'description': '返回结果数量上限',
      },
    },
    'required': ['query'],
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现全文搜索逻辑
  }
}

/// 2. 向量检索工具
class VectorSearchTool implements ITool {
  @override
  String get name => 'vector_search';
  
  @override
  String get description => '''
在知识库中进行语义搜索。基于文本含义而非关键词匹配：
- 理解查询的语义含义
- 找到语义相关的文档，即使没有完全匹配的关键词
- 适合问答、概念查找等场景
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': '自然语言查询',
      },
      'workspace_ids': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': '要搜索的工作空间ID列表',
      },
      'limit': {
        'type': 'integer',
        'default': 10,
      },
      'similarity_threshold': {
        'type': 'number',
        'default': 0.7,
        'description': '相似度阈值 (0-1)',
      },
    },
    'required': ['query'],
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现向量搜索逻辑
  }
}

/// 3. 深度搜索工具
class DeepSearchTool implements ITool {
  @override
  String get name => 'deep_search';
  
  @override
  String get description => '''
在互联网上进行深度搜索并提取内容：
- 使用搜索引擎查找相关网页
- 自动访问和提取网页内容
- 可选择保存到知识库
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': '搜索查询',
      },
      'max_results': {
        'type': 'integer',
        'default': 5,
        'description': '最大结果数',
      },
      'extract_content': {
        'type': 'boolean',
        'default': true,
        'description': '是否提取网页内容',
      },
      'save_to_workspace': {
        'type': 'string',
        'description': '保存到指定工作空间ID',
      },
    },
    'required': ['query'],
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现深度搜索逻辑
  }
}

/// 4. 文档操作工具
class DocumentTool implements ITool {
  @override
  String get name => 'document_operation';
  
  @override
  String get description => '''
对文档进行操作：
- 创建新文档
- 读取文档内容
- 更新文档
- 获取文档元信息
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['create', 'read', 'update', 'get_info'],
        'description': '操作类型',
      },
      'document_id': {
        'type': 'string',
        'description': '文档ID (read/update/get_info 时必需)',
      },
      'workspace_id': {
        'type': 'string',
        'description': '工作空间ID (create 时必需)',
      },
      'title': {
        'type': 'string',
        'description': '文档标题',
      },
      'content': {
        'type': 'string',
        'description': '文档内容',
      },
    },
    'required': ['action'],
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现文档操作逻辑
  }
}

/// 5. 摘要工具
class SummaryTool implements ITool {
  @override
  String get name => 'summarize';
  
  @override
  String get description => '''
对文本或文档进行摘要：
- 生成简短摘要
- 提取关键要点
- 支持指定摘要长度
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'text': {
        'type': 'string',
        'description': '要摘要的文本',
      },
      'document_id': {
        'type': 'string',
        'description': '要摘要的文档ID',
      },
      'max_length': {
        'type': 'integer',
        'default': 200,
        'description': '摘要最大字数',
      },
      'style': {
        'type': 'string',
        'enum': ['brief', 'detailed', 'bullet_points'],
        'default': 'brief',
      },
    },
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现摘要逻辑
  }
}

/// 6. 翻译工具
class TranslateTool implements ITool {
  @override
  String get name => 'translate';
  
  @override
  String get description => '''
翻译文本：
- 自动检测源语言
- 支持多种目标语言
- 保持格式和语义
''';
  
  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'text': {
        'type': 'string',
        'description': '要翻译的文本',
      },
      'target_language': {
        'type': 'string',
        'description': '目标语言 (如: zh, en, ja)',
      },
      'source_language': {
        'type': 'string',
        'description': '源语言 (可选，自动检测)',
      },
    },
    'required': ['text', 'target_language'],
  };
  
  @override
  Future<ToolResult> execute(Map<String, dynamic> parameters) async {
    // 实现翻译逻辑
  }
}
```

### Agent Orchestrator

```dart
/// Agent 编排器
class AgentOrchestrator {
  final IAIService aiService;
  final ToolRegistry toolRegistry;
  
  AgentOrchestrator({
    required this.aiService,
    required this.toolRegistry,
  });
  
  /// 处理用户请求
  Stream<AgentResponse> processRequest(AgentRequest request) async* {
    // 1. 分析用户意图，规划任务
    final plan = await _planTasks(request);
    yield AgentResponse.planning(plan);
    
    // 2. 执行任务计划
    for (final task in plan.tasks) {
      // 选择合适的工具
      final tool = toolRegistry.getTool(task.toolName);
      if (tool == null) {
        yield AgentResponse.error('Tool not found: ${task.toolName}');
        continue;
      }
      
      // 执行工具
      yield AgentResponse.toolExecuting(task.toolName);
      final result = await tool.execute(task.parameters);
      yield AgentResponse.toolResult(task.toolName, result);
      
      // 收集结果
      plan.addResult(task.id, result);
    }
    
    // 3. 整合结果，生成最终回答
    yield* _generateFinalResponse(request, plan);
  }
  
  /// 任务规划
  Future<TaskPlan> _planTasks(AgentRequest request) async {
    final systemPrompt = '''
你是一个智能助手，需要根据用户请求规划任务。
可用的工具有：
${toolRegistry.getToolDescriptions()}

请分析用户请求，返回需要执行的工具调用序列。
''';
    
    // 调用 LLM 进行任务规划
    final response = await aiService.chat(ChatRequest(
      messages: [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: request.query),
      ],
      tools: toolRegistry.getToolSchemas(),
    ));
    
    return TaskPlan.fromLLMResponse(response);
  }
  
  /// 生成最终回答
  Stream<AgentResponse> _generateFinalResponse(
    AgentRequest request,
    TaskPlan plan,
  ) async* {
    final context = plan.getResultsContext();
    final citations = plan.getAllCitations();
    
    // 流式生成回答
    await for (final chunk in aiService.streamChat(ChatRequest(
      messages: [
        ChatMessage(role: 'system', content: '基于以下信息回答用户问题：\n$context'),
        ChatMessage(role: 'user', content: request.query),
      ],
    ))) {
      yield AgentResponse.streaming(chunk);
    }
    
    // 附加引用信息
    if (citations.isNotEmpty) {
      yield AgentResponse.citations(citations);
    }
  }
}

/// 工具注册表
class ToolRegistry {
  final Map<String, ITool> _tools = {};
  
  void register(ITool tool) {
    _tools[tool.name] = tool;
  }
  
  ITool? getTool(String name) => _tools[name];
  
  List<Map<String, dynamic>> getToolSchemas() {
    return _tools.values.map((tool) => {
      'type': 'function',
      'function': {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.parametersSchema,
      },
    }).toList();
  }
  
  String getToolDescriptions() {
    return _tools.values
        .map((t) => '- ${t.name}: ${t.description}')
        .join('\n');
  }
}

/// Agent 响应类型
class AgentResponse {
  final AgentResponseType type;
  final dynamic data;
  
  AgentResponse._(this.type, this.data);
  
  factory AgentResponse.planning(TaskPlan plan) => 
      AgentResponse._(AgentResponseType.planning, plan);
  factory AgentResponse.toolExecuting(String toolName) => 
      AgentResponse._(AgentResponseType.toolExecuting, toolName);
  factory AgentResponse.toolResult(String toolName, ToolResult result) => 
      AgentResponse._(AgentResponseType.toolResult, {'tool': toolName, 'result': result});
  factory AgentResponse.streaming(String chunk) => 
      AgentResponse._(AgentResponseType.streaming, chunk);
  factory AgentResponse.citations(List<SourceCitation> citations) => 
      AgentResponse._(AgentResponseType.citations, citations);
  factory AgentResponse.error(String message) => 
      AgentResponse._(AgentResponseType.error, message);
}

enum AgentResponseType {
  planning,
  toolExecuting,
  toolResult,
  streaming,
  citations,
  error,
}
```

### 预定义 Agent 配置

```dart
/// 预定义的 Agent 配置
class AgentPresets {
  /// 研究助手 - 擅长信息检索和整合
  static AgentConfig researchAssistant = AgentConfig(
    name: 'Research Assistant',
    description: '帮助你搜索、整理和分析信息',
    enabledTools: [
      'full_text_search',
      'vector_search',
      'deep_search',
      'summarize',
    ],
    systemPrompt: '''
你是一个研究助手，擅长：
1. 在知识库中查找相关信息
2. 在互联网上搜索补充资料
3. 整合多个来源的信息
4. 生成结构化的研究报告
始终标注信息来源。
''',
  );
  
  /// 写作助手 - 擅长内容创作
  static AgentConfig writingAssistant = AgentConfig(
    name: 'Writing Assistant',
    description: '帮助你写作、润色和翻译',
    enabledTools: [
      'vector_search',
      'document_operation',
      'summarize',
      'translate',
    ],
    systemPrompt: '''
你是一个写作助手，擅长：
1. 根据知识库内容辅助写作
2. 润色和改进文本
3. 翻译多种语言
4. 生成大纲和结构
保持用户的写作风格。
''',
  );
  
  /// 知识问答 - 擅长基于知识库回答问题
  static AgentConfig qaAssistant = AgentConfig(
    name: 'Q&A Assistant',
    description: '基于你的知识库回答问题',
    enabledTools: [
      'full_text_search',
      'vector_search',
    ],
    systemPrompt: '''
你是一个知识问答助手：
1. 仅基于知识库中的内容回答问题
2. 如果知识库中没有相关信息，明确告知用户
3. 始终提供信息来源
4. 回答要准确、简洁
''',
  );
}
```


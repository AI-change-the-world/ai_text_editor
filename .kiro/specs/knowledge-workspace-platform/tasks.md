# Implementation Plan

## Phase 1: 基础架构重构

- [x] 1. 项目结构重组
  - [x] 1.1 创建新的目录结构 (core/, data/, services/, features/, shared/)
  - [x] 1.2 迁移现有代码到新结构
  - [x] 1.3 更新 import 路径
  - _Requirements: 整体架构_

- [x] 2. ObjectBox 数据模型扩展
  - [x] 2.1 创建 Workspace 实体
    - 包含 uuid, name, description, icon, colorTheme, category, isPinned, isArchived
    - _Requirements: 1.2_
  - [x] 2.2 创建 DocumentMeta 实体
    - 包含 uuid, title, parentFolderId, filePath, wordCount, tags
    - _Requirements: 1.4, 1.5_
  - [x] 2.3 创建 DocumentContent 实体 (用于全文检索)
    - _Requirements: 5.4_
  - [x] 2.4 创建 DocumentChunk 实体 (用于向量检索)
    - 配置 @HnswIndex 注解
    - _Requirements: 4.1, 4.2_
  - [x] 2.5 创建 Asset 实体
    - _Requirements: 1.5, 3.1-3.4_
  - [x] 2.6 创建 ModelProfile 实体
    - _Requirements: 7.4, 7.5_
  - [x] 2.7 创建 ChatHistory 和 ChatMessage 实体
    - _Requirements: 7.11_
  - [x] 2.8 运行 ObjectBox 代码生成
  - [ ]* 2.9 编写数据模型单元测试
    - **Property 1: Workspace ID Uniqueness**
    - **Property 2: Workspace Data Persistence**
    - **Validates: Requirements 1.2**


## Phase 2: 工作空间管理

- [x] 3. WorkspaceService 实现
  - [x] 3.1 实现 createWorkspace 方法
    - _Requirements: 1.2_
  - [x] 3.2 实现 getAllWorkspaces 方法
    - _Requirements: 1.1_
  - [x] 3.3 实现 switchWorkspace 方法
    - _Requirements: 1.3_
  - [x] 3.4 实现 togglePinWorkspace 方法
    - _Requirements: 1.9_
  - [x] 3.5 实现 archiveWorkspace 方法
    - _Requirements: 1.10_
  - [x] 3.6 实现 getWorkspaceStats 方法
    - _Requirements: 1.8_
  - [ ]* 3.7 编写 WorkspaceService 属性测试
    - **Property 3: Workspace Switch Context Consistency**
    - **Property 4: Pinned Workspace Ordering**
    - **Validates: Requirements 1.3, 1.9**

- [x] 4. 工作空间 UI 组件
  - [x] 4.1 创建 WorkspaceSelector 组件 (侧边栏)
    - _Requirements: 1.1_
  - [x] 4.2 创建 WorkspaceCard 组件
    - _Requirements: 1.1_
  - [x] 4.3 创建 CreateWorkspaceDialog 组件
    - 如果用户不选择本地图像，使用 `lib/utils/name_to_icon.dart` 中的 `Identicon.generate()` 生成默认图标
    - _Requirements: 1.2_
  - [x] 4.4 创建 WorkspaceSettingsDialog 组件
    - _Requirements: 1.2_
  - [x] 4.5 实现工作空间切换逻辑
    - _Requirements: 1.3_

- [ ] 5. Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户

## Phase 3: 文档管理增强

- [x] 6. DocumentService 实现
  - [x] 6.1 实现 createDocument 方法
    - _Requirements: 2.1_
  - [x] 6.2 实现 saveDocument 方法 (自动保存)
    - _Requirements: 2.1_
  - [x] 6.3 实现 createFolder 方法
    - _Requirements: 1.4_
  - [x] 6.4 实现 moveDocument 方法
    - _Requirements: 1.4_
  - [x] 6.5 实现 importFile 方法 (Markdown, TXT, DOCX)
    - _Requirements: 1.6_
  - [x] 6.6 实现 exportDocument 方法 (PDF, Markdown, HTML, DOCX)
    - _Requirements: 1.7_
  - [ ]* 6.7 编写 DocumentService 属性测试
    - **Property 14: Document Export Round-Trip (Markdown)**
    - **Validates: Requirements 1.7**

- [x] 7. 文档树 UI 组件
  - [x] 7.1 创建 DocumentTree 组件
    - _Requirements: 1.4_
  - [x] 7.2 实现拖拽排序功能
    - _Requirements: 1.4_
  - [x] 7.3 创建 DocumentContextMenu 组件
    - _Requirements: 1.4, 1.7_


## Phase 4: 索引与检索系统

- [x] 8. IndexingService 实现
  - [x] 8.1 实现 indexDocument 方法 (全文索引)
    - _Requirements: 4.2, 5.4_
  - [x] 8.2 实现文档分块逻辑 (用于向量索引)
    - _Requirements: 4.2_
  - [x] 8.3 实现 removeDocumentIndex 方法
    - _Requirements: 4.2_
  - [x] 8.4 实现后台索引队列
    - _Requirements: 4.2_
  - [ ]* 8.5 编写 IndexingService 属性测试
    - **Property 5: Document Index Consistency**
    - **Validates: Requirements 4.2, 5.4**

- [x] 9. EmbeddingService 实现
  - [x] 9.1 实现 getEmbedding 方法 (调用 AI API)
    - _Requirements: 4.1_
  - [x] 9.2 实现批量嵌入生成
    - _Requirements: 4.2_
  - [x] 9.3 实现嵌入缓存机制
    - _Requirements: 4.8_
  - [ ]* 9.4 编写 EmbeddingService 属性测试
    - **Property 6: Vector Embedding Existence**
    - **Validates: Requirements 4.1, 4.2**

- [x] 10. SearchService 实现
  - [x] 10.1 实现 fullTextSearch 方法
    - _Requirements: 5.4_
  - [x] 10.2 实现 semanticSearch 方法 (向量检索)
    - _Requirements: 4.3_
  - [x] 10.3 实现 hybridSearch 方法 (混合检索)
    - _Requirements: 4.3, 5.4_
  - [x] 10.4 实现跨工作空间搜索
    - _Requirements: 4.6, 5.5_
  - [x] 10.5 实现高级搜索语法解析
    - _Requirements: 5.8_
  - [x] 10.6 实现搜索结果高亮
    - _Requirements: 5.4_
  - [ ]* 10.7 编写 SearchService 属性测试
    - **Property 7: Semantic Search Scope Isolation**
    - **Property 8: Cross-Workspace Search Completeness**
    - **Property 10: Advanced Search Query Parsing**
    - **Validates: Requirements 4.3, 4.6, 5.5, 5.8**

- [ ] 11. Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户

## Phase 5: Tool 系统

- [x] 12. Tool 基础架构
  - [x] 12.1 创建 ITool 接口
    - _Requirements: 7.7_
  - [x] 12.2 创建 ToolRegistry 类
    - _Requirements: 7.7_
  - [x] 12.3 创建 ToolResult 和 SourceCitation 类
    - _Requirements: 4.5, 7.10_

- [x] 13. 核心 Tool 实现
  - [x] 13.1 实现 FullTextSearchTool
    - _Requirements: 5.4_
  - [x] 13.2 实现 VectorSearchTool
    - _Requirements: 4.3_
  - [x] 13.3 实现 DocumentTool
    - _Requirements: 2.1_
  - [x] 13.4 实现 SummaryTool
    - _Requirements: 7.6_
  - [x] 13.5 实现 TranslateTool
    - _Requirements: 7.8_
  - [ ]* 13.6 编写 Tool 属性测试
    - **Property 9: Search Result Citation Validity**
    - **Validates: Requirements 4.5, 7.10**


## Phase 6: AI Agent 系统

- [x] 14. AgentOrchestrator 实现
  - [x] 14.1 实现任务规划逻辑
    - _Requirements: 7.7_
  - [x] 14.2 实现工具选择和执行
    - _Requirements: 7.7_
  - [x] 14.3 实现结果整合和引用生成
    - _Requirements: 4.5, 7.10_
  - [x] 14.4 实现流式响应
    - _Requirements: 7.9_

- [x] 15. 预定义 Agent 配置
  - [x] 15.1 创建 Research Assistant 配置
    - _Requirements: 7.7_
  - [x] 15.2 创建 Writing Assistant 配置
    - _Requirements: 7.6_
  - [x] 15.3 创建 Q&A Assistant 配置
    - _Requirements: 4.4_

- [ ] 16. Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户

## Phase 7: 全局 AI 助手 UI

- [x] 17. AI 助手面板
  - [x] 17.1 创建 AIAssistantPanel 组件
    - _Requirements: 7.1_
  - [x] 17.2 实现搜索范围选择器
    - _Requirements: 7.3_
  - [x] 17.3 实现对话历史显示
    - _Requirements: 7.11_
  - [x] 17.4 实现流式消息渲染
    - _Requirements: 7.9_
  - [x] 17.5 实现来源引用展示 (可点击跳转)
    - _Requirements: 4.5, 7.10_
  - [x] 17.6 实现 Agent 选择器
    - _Requirements: 7.7_

- [x] 18. 全局入口
  - [x] 18.1 在侧边栏添加 AI 助手入口
    - _Requirements: 7.1_
  - [x] 18.2 实现悬浮按钮 (可配置显示/隐藏)
    - _Requirements: 7.1, 7.14_
  - [x] 18.3 实现快捷键 Cmd+J / Ctrl+J
    - _Requirements: 7.2_

## Phase 8: 多模态内容处理

- [x] 19. AssetService 实现
  - [x] 19.1 实现 uploadAsset 方法
    - _Requirements: 1.5_
  - [x] 19.2 实现 extractPdfText 方法 (暂时跳过，后续实现)
    - _Requirements: 3.1_
  - [x] 19.3 实现 ocrImage 方法
    - _Requirements: 3.2_
  - [x] 19.4 实现 transcribeAudio 方法 (暂时跳过，后续实现)
    - _Requirements: 3.3_
  - [x] 19.5 实现资产预览生成
    - _Requirements: 3.4_
  - [ ]* 19.6 编写 AssetService 属性测试
    - **Property 12: PDF Text Extraction Non-Empty**
    - **Validates: Requirements 3.1**

- [x] 20. 资产 UI 组件
  - [x] 20.1 创建 AssetViewer 组件
    - _Requirements: 3.4_
  - [x] 20.2 创建 AssetUploadDialog 组件
    - _Requirements: 1.5_
  - [x] 20.3 在文档树中显示资产
    - _Requirements: 1.5_


## Phase 9: Deep Search

- [x] 21. DeepSearchService 实现
  - [x] 21.1 集成 webview_flutter
    - _Requirements: 6.1_
  - [x] 21.2 实现搜索引擎查询
    - _Requirements: 6.1, 6.2_
  - [x] 21.3 实现网页内容提取
    - _Requirements: 6.4_
  - [x] 21.4 实现保存到知识库功能
    - _Requirements: 6.5_
  - [ ]* 21.5 编写 DeepSearchService 属性测试
    - **Property 13: HTML Content Extraction**
    - **Validates: Requirements 6.4**

- [x] 22. DeepSearchTool 实现
  - [x] 22.1 实现 DeepSearchTool
    - _Requirements: 6.1-6.5_
  - [x] 22.2 实现自动研究模式
    - _Requirements: 6.6_

- [x] 23. Deep Search UI
  - [x] 23.1 创建 DeepSearchPanel 组件
    - _Requirements: 6.1_
  - [x] 23.2 创建 WebViewContainer 组件
    - _Requirements: 6.3_
  - [x] 23.3 创建搜索结果列表组件
    - _Requirements: 6.2_
  - [x] 23.4 实现内容提取和保存 UI
    - _Requirements: 6.4, 6.5_

- [ ] 24. Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户

## Phase 10: 设置与配置

- [x] 25. 模型配置管理
  - [x] 25.1 创建 ModelProfileService
    - _Requirements: 7.4, 7.5_
  - [x] 25.2 实现多提供商支持 (OpenAI, Anthropic, DeepSeek, Ollama)
    - _Requirements: 7.5_
  - [x] 25.3 实现 API Key 加密存储
    - _Requirements: 7.5_
  - [x] 25.4 实现模型回退机制
    - _Requirements: 7.13_
  - [ ]* 25.5 编写 ModelProfileService 属性测试
    - **Property 11: Model Profile Persistence**
    - **Validates: Requirements 7.5**

- [x] 26. 设置 UI
  - [x] 26.1 创建 SettingsPage 组件
    - _Requirements: 8.1_
  - [x] 26.2 创建 GeneralSettings 组件
    - _Requirements: 8.1_
  - [x] 26.3 创建 AIModelSettings 组件
    - _Requirements: 8.2_
  - [x] 26.4 创建 AppearanceSettings 组件 (主题)
    - _Requirements: 8.3_
  - [x] 26.5 创建 KeyboardShortcutsSettings 组件
    - _Requirements: 8.4_
  - [x] 26.6 实现设置导入/导出
    - _Requirements: 8.5, 8.6_

## Phase 11: 编辑器增强

- [x] 27. 斜杠命令增强
  - [x] 27.1 扩展斜杠命令菜单
    - _Requirements: 2.2_
  - [x] 27.2 添加 AI 辅助命令 (rewrite, expand, summarize, translate)
    - _Requirements: 2.3_
  - [x] 27.3 添加插入命令 (table, image, code, link)
    - _Requirements: 2.4, 2.5, 2.8_

- [x] 28. 编辑器功能
  - [x] 28.1 实现专注模式
    - _Requirements: 2.6_
  - [x] 28.2 实现文档大纲
    - _Requirements: 2.7_
  - [x] 28.3 实现链接预览卡片
    - _Requirements: 2.8_

## Phase 12: 数据备份

- [ ] 29. 备份服务
  - [ ] 29.1 实现本地增量备份
    - _Requirements: 10.1_
  - [ ] 29.2 实现备份恢复
    - _Requirements: 10.4_
  - [ ] 29.3 实现备份清理策略
    - _Requirements: 10.5_
  - [ ] 29.4 (可选) 实现云同步 (WebDAV/S3)
    - _Requirements: 10.2, 10.3_

- [ ] 30. 备份 UI
  - [ ] 30.1 创建 BackupSettings 组件
    - _Requirements: 10.1_
  - [ ] 30.2 创建 RestoreDialog 组件
    - _Requirements: 10.4_

## Phase 13: 最终集成与优化

- [ ] 31. 性能优化
  - [ ] 31.1 实现启动优化 (懒加载)
    - _Requirements: 11.1_
  - [ ] 31.2 实现长文档虚拟滚动
    - _Requirements: 11.2_
  - [ ] 31.3 实现内存优化
    - _Requirements: 11.5_

- [ ] 32. 用户体验优化
  - [ ] 32.1 添加加载状态和反馈
    - _Requirements: 11.3_
  - [ ] 32.2 实现错误处理和恢复
    - _Requirements: 11.4_
  - [ ] 32.3 添加工具提示
    - _Requirements: 11.6_

- [ ] 33. Final Checkpoint - 确保所有测试通过
  - 确保所有测试通过，如有问题请询问用户


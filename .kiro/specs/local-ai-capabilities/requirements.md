# Requirements Document

## Introduction

本文档定义了内容采集工具的规划。工作空间是应用的核心，所有工具的目标都是帮助用户高效地将各种来源的内容采集到工作空间中，最终作为知识库问答的素材。

本文档聚焦于**内容采集工具层**的设计，包括：语音转录工具、深度搜索工具。这些工具独立于工作空间，但最终输出都流向工作空间。

## 架构概述

```
┌─────────────────────────────────────────────────────────┐
│                    知识库问答 (AI Assistant)              │
│                  基于工作空间内容进行问答                   │
└─────────────────────────────────────────────────────────┘
                              ▲
                              │ 读取
┌─────────────────────────────────────────────────────────┐
│                      工作空间 (Workspace)                 │
│                    文档存储、组织、管理                     │
└─────────────────────────────────────────────────────────┘
                              ▲
                              │ 保存内容
┌─────────────────────────────────────────────────────────┐
│                    内容采集工具层                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  语音转录工具  │  │  深度搜索工具  │  │  (未来扩展)   │   │
│  │  Voice Tool  │  │  Search Tool │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                              ▲
                              │ 输入
┌─────────────────────────────────────────────────────────┐
│                      外部内容来源                         │
│           音频文件、网页、剪贴板、文件等                    │
└─────────────────────────────────────────────────────────┘
```

## Glossary

- **Workspace**: 工作空间，文档存储和组织的核心容器，知识库问答的数据来源
- **Content_Tool**: 内容采集工具，独立的功能模块，负责从外部来源采集内容并保存到工作空间
- **Voice_Tool**: 语音转录工具，将音频转为文字并可生成总结
- **Search_Tool**: 深度搜索工具，从网页搜索提取内容
- **Local_ASR**: 本地语音识别，基于 sherpa_onnx Dart 包的离线转录能力

## Requirements

### Requirement 1: 语音转录工具

**User Story:** As a user, I want a voice transcription tool to convert audio recordings into text documents, so that I can add lecture/meeting content to my workspace.

#### Acceptance Criteria

1. THE Voice_Tool SHALL be accessible as an independent tool from the main interface
2. WHEN a user opens Voice_Tool, THE System SHALL display a dedicated transcription interface
3. THE Voice_Tool SHALL support importing audio files (mp3, wav, m4a, flac)
4. WHEN transcription is complete, THE Voice_Tool SHALL display result with option to edit
5. THE Voice_Tool SHALL offer AI summary generation for transcribed content
6. WHEN user confirms, THE Voice_Tool SHALL save document to selected workspace
7. THE Voice_Tool SHALL support both local (sherpa-onnx) and cloud transcription

### Requirement 2: 语音转录 - 本地引擎

**User Story:** As a user, I want local speech recognition, so that I can transcribe audio offline and keep data private.

#### Acceptance Criteria

1. THE Local_ASR SHALL integrate sherpa-onnx Dart package (sherpa_onnx)
2. THE Local_ASR SHALL provide model management interface (download, delete, update)
3. WHEN no network is available, THE Voice_Tool SHALL use Local_ASR automatically
4. THE Local_ASR SHALL support Chinese and English models
5. THE Local_ASR SHALL display transcription progress
6. WHEN using Local_ASR, THE System SHALL not send audio to external servers

### Requirement 3: 语音转录 - 内容总结

**User Story:** As a user, I want to generate summaries from transcripts, so that I can quickly review key points from lectures or meetings.

#### Acceptance Criteria

1. WHEN transcription is complete, THE Voice_Tool SHALL offer "Generate Summary" option
2. THE Summary SHALL extract key points as bullet list
3. THE Summary SHALL identify action items if present
4. THE Summary SHALL support different lengths (brief, standard, detailed)
5. WHEN saving, THE Voice_Tool SHALL create document containing both transcript and summary

### Requirement 4: 深度搜索工具 - 入口优化

**User Story:** As a user, I want clear entry points to deep search tool, so that I can easily access it from anywhere in the app.

#### Acceptance Criteria

1. THE Search_Tool SHALL be accessible from the main toolbar as a dedicated button
2. THE Search_Tool SHALL be accessible via keyboard shortcut
3. WHEN text is selected in editor, THE Context_Menu SHALL offer "Deep Search" option
4. WHEN in workspace view, THE Action_Bar SHALL include Search_Tool entry
5. THE Search_Tool SHALL display recent searches for quick access

### Requirement 5: 深度搜索工具 - 保存到工作空间

**User Story:** As a user, I want to save search results to my workspace, so that I can build a knowledge base from web research.

#### Acceptance Criteria

1. WHEN viewing search results, THE Search_Tool SHALL provide "Save to Workspace" button
2. WHEN saving, THE Search_Tool SHALL allow user to select target workspace
3. THE Search_Tool SHALL save content with source URL and timestamp as metadata
4. THE Search_Tool SHALL support selecting multiple results for batch save
5. THE Search_Tool SHALL offer to generate summary before saving
6. WHEN save is complete, THE Search_Tool SHALL show confirmation with link to document

### Requirement 6: 工具输出标准化

**User Story:** As a developer, I want all tools to output content in a standard format, so that workspace can handle content consistently.

#### Acceptance Criteria

1. THE Content_Tool output SHALL include: content body, source type, source metadata, timestamp
2. THE Source_Type SHALL be one of: transcription, deep-search, manual, import
3. THE Workspace SHALL display source indicator on documents from tools
4. THE Workspace SHALL support filtering documents by source type
5. WHEN displaying document, THE System SHALL show source metadata (URL, audio file name, etc.)

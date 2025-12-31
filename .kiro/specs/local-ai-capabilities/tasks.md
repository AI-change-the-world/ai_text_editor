# Implementation Plan: 内容采集工具

## Overview

以用户交互流程为导向，先实现工具入口和页面框架，再逐步填充每个工具的具体功能。

## Tasks

- [x] 1. 工具中心入口页面（已重构为统一工具面板）
  - [x] 1.1 创建工具中心视图
    - 创建 `lib/features/tools/views/tools_center_view.dart`
    - 网格布局展示所有工具卡片
    - 每个卡片包含：图标、名称、简介
    - 工具列表：语音转录、深度搜索
    - _Requirements: 1.1, 4.1_
  - [x] 1.2 添加工具中心路由
    - 更新 `lib/routers.dart` 添加 `/tools` 路由
    - ~~在侧边栏添加"工具"入口~~ → 改为右下角 FAB
    - _Requirements: 1.1_
  - [x] 1.3 创建工具卡片组件
    - 创建 `lib/features/tools/widgets/tool_card.dart`
    - 点击跳转到对应工具页面
    - 悬停效果
    - _Requirements: 1.1_
  - [x] 1.4 重构：统一工具面板（替代原 AI 助手 FAB）
    - 创建 `lib/features/tools/widgets/tools_panel.dart` - 工具面板
    - 创建 `lib/features/tools/widgets/tools_fab.dart` - 浮动按钮
    - 创建 `lib/features/tools/widgets/tools_overlay.dart` - Overlay 包装
    - 创建 `lib/features/ai_assistant/widgets/embedded_ai_chat_panel.dart` - 嵌入式 AI 对话
    - 工具面板包含：AI 问答、语音转录、深度搜索
    - AI 问答在面板内打开，语音转录跳转新页面
    - _Requirements: 1.1, 7.1_

- [x] 2. 语音转录工具 - 页面框架
  - [x] 2.1 创建语音转录主页面
    - 创建 `lib/features/voice_tool/views/voice_tool_page.dart`
    - 顶部：返回按钮、标题"语音转录"
    - 中间：主要操作区域（后续填充）
    - 底部：操作按钮区
    - _Requirements: 1.2_
  - [x] 2.2 添加语音转录路由
    - 更新 `lib/routers.dart` 添加 `/tools/voice` 路由
    - _Requirements: 1.1_

- [x] 3. 语音转录 - 实时流式识别界面
  - [x] 3.1 创建流式识别状态管理
    - 创建 `lib/features/voice_tool/notifiers/streaming_asr_notifier.dart`
    - 状态：idle, recording, processing, completed, error
    - 管理识别文本流
    - 管理录音控制
    - _Requirements: 1.4, 2.5_
  - [x] 3.2 创建流式识别主界面
    - 创建 `lib/features/voice_tool/widgets/streaming_asr_widget.dart`
    - 初始状态：大的"开始录音"按钮（麦克风图标）
    - 录音中状态：
      - 顶部：录音时长显示、波形动画
      - 中间：多行文本框，实时显示识别结果
      - 底部："停止录音"按钮（红色）
    - _Requirements: 1.4, 2.5_
  - [x] 3.3 创建识别结果文本显示组件
    - 创建 `lib/features/voice_tool/widgets/transcription_text_view.dart`
    - 自动滚动到底部
    - 区分已确认文本和临时文本（不同颜色）
    - 支持手动编辑
    - _Requirements: 1.4_
  - [x] 3.4 创建录音控制按钮组件
    - 创建 `lib/features/voice_tool/widgets/recording_control_button.dart`
    - 开始/停止状态切换
    - 录音中显示动画效果
    - _Requirements: 1.4_

- [x] 4. 语音转录 - 停止后的处理流程
  - [x] 4.1 创建转录完成弹窗
    - 创建 `lib/features/voice_tool/widgets/transcription_complete_dialog.dart`
    - 显示完整转录文本（可编辑）
    - 操作按钮：
      - "AI 优化" - 调用 AI 润色
      - "生成摘要" - 生成要点总结
      - "存入工作空间" - 选择工作空间保存
      - "取消" - 关闭弹窗
    - _Requirements: 1.5, 1.6, 3.1_
  - [x] 4.2 创建 AI 优化功能
    - 创建 `lib/features/voice_tool/widgets/ai_polish_widget.dart`
    - 显示原文和优化后文本对比
    - "应用"/"取消"按钮
    - _Requirements: 3.1_
  - [x] 4.3 创建摘要生成功能
    - 创建 `lib/features/voice_tool/widgets/summary_generator_widget.dart`
    - 摘要长度选择：简短/标准/详细
    - 显示生成的摘要
    - 可选择是否包含摘要一起保存
    - _Requirements: 3.2, 3.3, 3.4_
  - [x] 4.4 创建工作空间选择弹窗
    - 创建 `lib/features/voice_tool/widgets/save_to_workspace_dialog.dart`
    - 工作空间列表（下拉或列表选择）
    - 文档标题输入
    - 确认保存按钮
    - _Requirements: 1.6_

- [x] 5. Checkpoint - 语音转录 UI 完成
  - UI 页面流程已完成
  - 录音 → 实时显示 → 停止 → 完成弹窗 → AI优化/摘要/保存
  - 所有组件已创建并通过诊断检查

- [x] 6. 语音转录 - 本地 ASR 引擎集成
  - [x] 6.1 添加 sherpa_onnx 依赖
    - 更新 `pubspec.yaml` 添加 sherpa_onnx
    - 配置 Windows/macOS/Linux 平台设置
    - _Requirements: 2.1_
  - [x] 6.2 创建 ASR 模型配置
    - 创建 `lib/services/voice_tool/asr_models_config.dart`
    - 定义支持的模型列表（中文、英文）
    - 模型下载 URL
    - 模型文件路径
    - _Requirements: 2.2, 2.4_
  - [x] 6.3 创建模型管理服务
    - 创建 `lib/services/voice_tool/asr_model_manager.dart`
    - 检查模型是否已下载
    - 下载模型（带进度）
    - 删除模型
    - _Requirements: 2.2_
  - [x] 6.4 创建本地 ASR 服务
    - 创建 `lib/services/voice_tool/local_asr_service.dart`
    - 初始化 sherpa_onnx recognizer
    - 实现流式识别：feedAudioData, getStreamingResult
    - 实现非流式识别：transcribeFile
    - _Requirements: 2.1, 2.5, 2.6_
  - [x] 6.5 创建麦克风录音服务
    - 创建 `lib/services/voice_tool/microphone_service.dart`
    - 开始/停止录音
    - 获取音频流数据
    - 音频格式配置（采样率等）
    - _Requirements: 1.4_

- [ ] 7. 语音转录 - 连接 UI 和服务
  - [ ] 7.1 完善 StreamingASRNotifier
    - 连接 MicrophoneService 和 LocalASRService
    - 实现开始录音 → 流式识别 → 停止录音流程
    - 处理错误状态
    - _Requirements: 1.4, 2.5_
  - [ ] 7.2 实现保存到工作空间
    - 创建 `lib/services/voice_tool/transcription_save_service.dart`
    - 格式化转录内容为 Markdown
    - 调用 WorkspaceService 创建文档
    - 保存来源元数据
    - _Requirements: 1.6, 6.1_

- [ ] 8. Checkpoint - 语音转录功能完成
  - 测试完整流程：录音 → 识别 → 优化 → 保存
  - 如有问题请询问用户

- [ ] 9. 语音转录 - 模型管理界面
  - [ ] 9.1 创建模型管理页面
    - 创建 `lib/features/voice_tool/views/asr_model_manager_page.dart`
    - 从语音转录页面设置图标进入
    - 显示模型列表
    - _Requirements: 2.2_
  - [ ] 9.2 创建模型卡片组件
    - 创建 `lib/features/voice_tool/widgets/asr_model_card.dart`
    - 显示：模型名称、语言、大小、状态
    - 操作：下载/删除按钮
    - 下载进度条
    - _Requirements: 2.2_

- [ ] 10. 深度搜索 - 入口优化
  - [ ] 10.1 添加工具栏快捷入口
    - 修改主工具栏，添加深度搜索图标按钮
    - 点击打开深度搜索面板
    - _Requirements: 4.1_
  - [ ] 10.2 添加编辑器右键菜单
    - 修改编辑器上下文菜单
    - 选中文本时显示"深度搜索此内容"
    - 点击后打开深度搜索并填入选中文本
    - _Requirements: 4.3_
  - [ ] 10.3 添加快捷键支持
    - 注册 Ctrl+Shift+S 快捷键
    - 打开深度搜索面板
    - _Requirements: 4.2_
  - [ ] 10.4 添加搜索历史下拉
    - 修改深度搜索输入框
    - 聚焦时显示最近搜索历史
    - 点击历史项填入搜索框
    - _Requirements: 4.5_

- [ ] 11. 深度搜索 - 保存到工作空间
  - [ ] 11.1 添加搜索结果选择功能
    - 修改搜索结果列表项
    - 添加复选框支持多选
    - 底部显示已选数量
    - _Requirements: 5.4_
  - [ ] 11.2 创建保存到工作空间按钮
    - 在搜索结果区域添加"保存到工作空间"按钮
    - 选中结果后按钮可用
    - _Requirements: 5.1_
  - [ ] 11.3 创建保存确认弹窗
    - 创建 `lib/features/deep_search/widgets/save_results_dialog.dart`
    - 显示已选结果列表
    - 工作空间选择
    - "生成摘要"开关
    - 确认/取消按钮
    - _Requirements: 5.2, 5.5_
  - [ ] 11.4 实现批量保存服务
    - 创建 `lib/services/deep_search/search_result_save_service.dart`
    - 批量创建文档
    - 保存来源 URL 和元数据
    - 可选生成摘要
    - _Requirements: 5.3, 5.4, 5.6_

- [ ] 12. 深度搜索 - 搜索历史服务
  - [ ] 12.1 创建搜索历史服务
    - 创建 `lib/services/deep_search/search_history_service.dart`
    - 保存搜索记录（关键词、时间、结果数）
    - 获取最近 N 条历史
    - 清除历史
    - _Requirements: 4.5_

- [ ] 13. Final Checkpoint
  - 测试语音转录完整流程
  - 测试深度搜索保存流程
  - 验证工具中心入口
  - 如有问题请询问用户

## Notes

- 先实现 UI 框架，再填充服务逻辑
- 每个 Checkpoint 确保当前阶段可用
- sherpa_onnx 模型较大，需要单独的模型管理页面
- 深度搜索优化基于现有功能扩展

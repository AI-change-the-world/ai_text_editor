import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../widgets/hybrid_asr_widget.dart';
import '../widgets/streaming_asr_widget.dart';

/// 语音转录工具主页面
/// 提供实时语音识别和音频文件转录功能
class VoiceToolPage extends ConsumerStatefulWidget {
  const VoiceToolPage({super.key});

  @override
  ConsumerState<VoiceToolPage> createState() => _VoiceToolPageState();
}

class _VoiceToolPageState extends ConsumerState<VoiceToolPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/tools'),
        ),
        title: Text(
          '语音转录',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          // 模型管理按钮
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
            onPressed: _openModelManager,
            tooltip: '模型管理',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '混合识别'),
            Tab(text: '流式识别'),
            Tab(text: '导入音频'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 混合识别（流式 + 分段非流式）
          const HybridASRWidget(),
          // 纯流式识别
          const StreamingASRWidget(),
          // 导入音频文件转录
          _buildImportAudioTab(colors),
        ],
      ),
    );
  }

  Widget _buildImportAudioTab(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border, width: 2),
            ),
            child: Icon(
              Icons.audio_file,
              size: 48,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '导入音频文件',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持 MP3, WAV, M4A, FLAC 格式',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importAudioFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('选择文件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.dialogBackground,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _openModelManager() {
    // TODO: 打开模型管理页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('模型管理功能开发中...')),
    );
  }

  void _importAudioFile() {
    // TODO: 实现音频文件导入
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('音频导入功能开发中...')),
    );
  }
}

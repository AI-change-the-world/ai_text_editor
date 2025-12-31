import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../../ai_assistant/widgets/embedded_ai_chat_panel.dart';

/// 工具面板状态
enum ToolsPanelView {
  /// 工具列表
  toolList,

  /// AI 问答
  aiChat,

  /// 深度搜索（面板内）
  deepSearch,
}

/// 工具面板状态管理
class ToolsPanelState {
  final bool isVisible;
  final ToolsPanelView currentView;

  const ToolsPanelState({
    this.isVisible = false,
    this.currentView = ToolsPanelView.toolList,
  });

  ToolsPanelState copyWith({
    bool? isVisible,
    ToolsPanelView? currentView,
  }) {
    return ToolsPanelState(
      isVisible: isVisible ?? this.isVisible,
      currentView: currentView ?? this.currentView,
    );
  }
}

/// 工具面板 Notifier
class ToolsPanelNotifier extends Notifier<ToolsPanelState> {
  @override
  ToolsPanelState build() => const ToolsPanelState();

  void showPanel() {
    state = state.copyWith(isVisible: true);
  }

  void hidePanel() {
    state =
        state.copyWith(isVisible: false, currentView: ToolsPanelView.toolList);
  }

  void togglePanel() {
    if (state.isVisible) {
      hidePanel();
    } else {
      showPanel();
    }
  }

  void switchView(ToolsPanelView view) {
    state = state.copyWith(currentView: view);
  }

  void backToToolList() {
    state = state.copyWith(currentView: ToolsPanelView.toolList);
  }
}

final toolsPanelProvider =
    NotifierProvider<ToolsPanelNotifier, ToolsPanelState>(
  ToolsPanelNotifier.new,
);

/// 工具定义
class ToolItem {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  /// 是否在面板内打开，false 则跳转到新页面
  final bool openInPanel;

  /// 面板内视图类型（如果 openInPanel 为 true）
  final ToolsPanelView? panelView;

  /// 跳转路由（如果 openInPanel 为 false）
  final String? route;

  const ToolItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.openInPanel = false,
    this.panelView,
    this.route,
  });
}

/// 工具列表
const List<ToolItem> toolItems = [
  ToolItem(
    id: 'ai-chat',
    name: 'AI 问答',
    description: '智能对话助手',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFF6366F1),
    openInPanel: true,
    panelView: ToolsPanelView.aiChat,
  ),
  ToolItem(
    id: 'voice-transcription',
    name: '语音转录',
    description: '实时语音转文字',
    icon: Icons.mic,
    color: Color(0xFFEC4899),
    openInPanel: false,
    route: '/tools/voice',
  ),
  ToolItem(
    id: 'deep-search',
    name: '深度搜索',
    description: '联网搜索资料',
    icon: Icons.travel_explore,
    color: Color(0xFF10B981),
    openInPanel: true,
    panelView: ToolsPanelView.deepSearch,
  ),
];

/// 工具中心面板
/// 统一的工具入口，包含 AI 问答、语音转录、深度搜索等
class ToolsPanel extends ConsumerWidget {
  const ToolsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(toolsPanelProvider);
    final colors = context.colors;

    if (!state.isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // 背景点击关闭
          Positioned.fill(
            child: GestureDetector(
              onTap: () => ref.read(toolsPanelProvider.notifier).hidePanel(),
              child: Container(color: Colors.transparent),
            ),
          ),
          // 面板
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.8,
              constraints: const BoxConstraints(
                maxWidth: 800,
                maxHeight: 700,
              ),
              decoration: BoxDecoration(
                color: colors.dialogBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildContent(context, ref, state, colors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ToolsPanelState state,
    AppColors colors,
  ) {
    switch (state.currentView) {
      case ToolsPanelView.toolList:
        return _ToolListView(colors: colors);
      case ToolsPanelView.aiChat:
        return _AIChatView(colors: colors);
      case ToolsPanelView.deepSearch:
        return _DeepSearchView(colors: colors);
    }
  }
}

/// 工具列表视图
class _ToolListView extends ConsumerWidget {
  final AppColors colors;

  const _ToolListView({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 头部
        _buildHeader(context, ref),
        // 工具网格
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: toolItems.length,
              itemBuilder: (context, index) {
                return _ToolCard(
                  tool: toolItems[index],
                  colors: colors,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.widgets_outlined, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            '工具中心',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary),
            onPressed: () => ref.read(toolsPanelProvider.notifier).hidePanel(),
            tooltip: '关闭 (Esc)',
          ),
        ],
      ),
    );
  }
}

/// 工具卡片
class _ToolCard extends ConsumerWidget {
  final ToolItem tool;
  final AppColors colors;

  const _ToolCard({required this.tool, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _onTap(context, ref),
        borderRadius: BorderRadius.circular(12),
        hoverColor: tool.color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tool.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: tool.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                tool.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.description,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    if (tool.openInPanel && tool.panelView != null) {
      ref.read(toolsPanelProvider.notifier).switchView(tool.panelView!);
    } else if (tool.route != null) {
      ref.read(toolsPanelProvider.notifier).hidePanel();
      context.go(tool.route!);
    }
  }
}

/// AI 问答视图（嵌入在工具面板内）
class _AIChatView extends ConsumerWidget {
  final AppColors colors;

  const _AIChatView({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 头部带返回按钮
        _buildHeader(context, ref),
        // AI 对话内容
        const Expanded(
          child: EmbeddedAIChatPanel(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textSecondary, size: 20),
            onPressed: () =>
                ref.read(toolsPanelProvider.notifier).backToToolList(),
            tooltip: '返回工具列表',
          ),
          Icon(Icons.chat_bubble_outline,
              color: const Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          Text(
            'AI 问答',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
            onPressed: () => ref.read(toolsPanelProvider.notifier).hidePanel(),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}

/// 深度搜索视图（嵌入在工具面板内）
class _DeepSearchView extends ConsumerWidget {
  final AppColors colors;

  const _DeepSearchView({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 头部带返回按钮
        _buildHeader(context, ref),
        // 深度搜索内容
        Expanded(
          child: _buildSearchContent(context, ref),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textSecondary, size: 20),
            onPressed: () =>
                ref.read(toolsPanelProvider.notifier).backToToolList(),
            tooltip: '返回工具列表',
          ),
          Icon(Icons.travel_explore, color: const Color(0xFF10B981), size: 20),
          const SizedBox(width: 8),
          Text(
            '深度搜索',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          // 在新页面打开
          TextButton.icon(
            onPressed: () {
              ref.read(toolsPanelProvider.notifier).hidePanel();
              context.go('/tools/deep-search');
            },
            icon:
                Icon(Icons.open_in_new, size: 16, color: colors.textSecondary),
            label: Text('新页面打开',
                style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
          IconButton(
            icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
            onPressed: () => ref.read(toolsPanelProvider.notifier).hidePanel(),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(BuildContext context, WidgetRef ref) {
    // TODO: 集成实际的深度搜索组件
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore, size: 64, color: colors.textHint),
          const SizedBox(height: 16),
          Text(
            '深度搜索功能',
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '即将集成现有的深度搜索组件',
            style: TextStyle(fontSize: 13, color: colors.textHint),
          ),
        ],
      ),
    );
  }
}

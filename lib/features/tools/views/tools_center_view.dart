import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_theme.dart';
import '../widgets/tool_card.dart';

/// 工具定义
class ToolDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final Color? iconColor;

  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    this.iconColor,
  });
}

/// 工具中心视图
/// 展示所有可用的内容采集工具
class ToolsCenterView extends StatelessWidget {
  const ToolsCenterView({super.key});

  static const List<ToolDefinition> tools = [
    ToolDefinition(
      id: 'voice',
      name: '语音转录',
      description: '将录音或实时语音转换为文字，支持AI总结',
      icon: Icons.mic,
      route: '/tools/voice',
      iconColor: Color(0xFF10B981),
    ),
    ToolDefinition(
      id: 'deep_search',
      name: '深度搜索',
      description: '从网页搜索并提取有价值内容到工作空间',
      icon: Icons.travel_explore,
      route: '/tools/deep-search',
      iconColor: Color(0xFF3B82F6),
    ),
  ];

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
          onPressed: () => context.go('/'),
        ),
        title: Text(
          '工具中心',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Text(
              '内容采集工具',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '使用这些工具将各种来源的内容采集到工作空间',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // 工具网格
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return ToolCard(
                    name: tool.name,
                    description: tool.description,
                    icon: tool.icon,
                    iconColor: tool.iconColor,
                    onTap: () => context.go(tool.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

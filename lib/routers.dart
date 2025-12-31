import 'package:ai_text_editor/editor_home.dart';
import 'package:ai_text_editor/features/workspace/workspace.dart';
import 'package:ai_text_editor/features/tools/tools.dart';
import 'package:ai_text_editor/features/voice_tool/voice_tool.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(routes: <RouteBase>[
  GoRoute(
    path: '/',
    builder: (BuildContext context, GoRouterState state) {
      // 使用工作空间首页作为主页
      // Requirements: 1.1 - 显示工作空间选择器
      return const ToolsOverlay(
        showFAB: true,
        child: WorkspaceHomeView(),
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: 'editor',
        builder: (BuildContext context, GoRouterState state) {
          return EditorHome();
        },
      ),
      GoRoute(
        path: 'tools',
        builder: (BuildContext context, GoRouterState state) {
          return const ToolsCenterView();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'voice',
            builder: (BuildContext context, GoRouterState state) {
              return const VoiceToolPage();
            },
          ),
          GoRoute(
            path: 'deep-search',
            builder: (BuildContext context, GoRouterState state) {
              // TODO: 跳转到深度搜索
              return const Scaffold(
                body: Center(child: Text('深度搜索工具 - 待实现')),
              );
            },
          ),
        ],
      ),
    ],
  )
]);

import 'package:ai_text_editor/home.dart';
import 'package:ai_text_editor/editor_home.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(routes: <RouteBase>[
  GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return Home();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'editor',
          builder: (BuildContext context, GoRouterState state) {
            return EditorHome();
          },
        ),
      ])
]);

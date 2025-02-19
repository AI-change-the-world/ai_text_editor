import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'components/app_body.dart';
import 'components/app_title.dart';

class App extends StatelessWidget {
  const App({super.key, this.title = 'AI Text Editor'});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
        child: ProviderScope(
            child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Styles.lightTheme,
      title: title,
      home: Home(),
    )));
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [AppTitle(), Expanded(child: AppBody())],
      ),
    );
  }
}

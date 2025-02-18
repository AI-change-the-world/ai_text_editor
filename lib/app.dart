import 'package:ai_text_editor/utils/styles.dart';
import 'package:cards/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

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
      body: Center(
        child: ClipRect(
          child: SizedBox(
            width: 400,
            height: 300,
            child: TwoCards(
              width: 300,
              height: 200,
              autoAnimate: true,
              duration: Duration(seconds: 5),
              child1: Container(),
              child2: Container(),
              onChild1Pressed: () {},
              onChild2Pressed: () {},
            ),
          ),
        ),
      ),
    );
  }
}

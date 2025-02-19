import 'dart:async';
import 'dart:math';

import 'package:ai_text_editor/init.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTitleState {
  final String word;
  final String region;
  final String from;
  final bool isLoading;

  final DateTime current;

  AppTitleState({
    required this.word,
    required this.region,
    required this.from,
    required this.current,
    this.isLoading = false,
  });

  AppTitleState copyWith({
    String? word,
    String? region,
    String? from,
    bool? isLoading,
  }) {
    return AppTitleState(
      word: word ?? this.word,
      region: region ?? this.region,
      from: from ?? this.from,
      current: DateTime.now(),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppTitleNotifier extends Notifier<AppTitleState> {
  final random = Random();

  late final Timer timer;

  @override
  AppTitleState build() {
    timer = Timer.periodic(Duration(seconds: 60), (timer) async {
      state = state.copyWith(
        isLoading: true,
      );

      await Future.delayed(Duration(seconds: 1));

      final words = APPConfig.words;
      if (words.isEmpty) {
        state = state.copyWith(isLoading: false);
      } else {
        final word = words[random.nextInt(words.length)];
        state = state.copyWith(
            word: word.text ?? "",
            region: word.region ?? "",
            from: word.from ?? "",
            isLoading: false);
      }
    });

    ref.onDispose(() {
      timer.cancel();
    });
    final words = APPConfig.words;
    if (words.isEmpty) {
      return AppTitleState(
        word: "",
        region: "",
        from: "",
        current: DateTime.now(),
      );
    } else {
      final word = words[random.nextInt(words.length)];
      return AppTitleState(
        word: word.text ?? "",
        region: word.region ?? "",
        from: word.from ?? "",
        current: DateTime.now(),
      );
    }
  }
}

final appTitleProvider =
    NotifierProvider<AppTitleNotifier, AppTitleState>(AppTitleNotifier.new);

import 'dart:async';
import 'dart:math';

import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/objectbox.g.dart';
import 'package:ai_text_editor/objectbox/database.dart';
import 'package:ai_text_editor/objectbox/recent_files.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBodyState {
  final String word;
  final String region;
  final String from;
  final bool isLoading;

  final DateTime current;

  AppBodyState({
    required this.word,
    required this.region,
    required this.from,
    required this.current,
    this.isLoading = false,
  });

  AppBodyState copyWith({
    String? word,
    String? region,
    String? from,
    bool? isLoading,
  }) {
    return AppBodyState(
      word: word ?? this.word,
      region: region ?? this.region,
      from: from ?? this.from,
      current: DateTime.now(),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AppBodyNotifier extends Notifier<AppBodyState> {
  final random = Random();

  late final Timer timer;

  @override
  AppBodyState build() {
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
      return AppBodyState(
        word: "",
        region: "",
        from: "",
        current: DateTime.now(),
      );
    } else {
      final word = words[random.nextInt(words.length)];
      return AppBodyState(
        word: word.text ?? "",
        region: word.region ?? "",
        from: word.from ?? "",
        current: DateTime.now(),
      );
    }
  }
}

final appBodyProvider =
    NotifierProvider<AppBodyNotifier, AppBodyState>(AppBodyNotifier.new);

class RecentFilesNotifier extends Notifier<List<RecentFiles>> {
  @override
  List<RecentFiles> build() {
    final filesQuery = ObxDatabase.db.recentFilesBox
        .query()
        .order(RecentFiles_.createdAt, flags: Order.descending)
        .build();
    filesQuery.limit = 5;

    final result = filesQuery.find();
    return result;
  }

  void add(RecentFiles file) {
    state = [...state, file];
  }

  void remove(RecentFiles file) {
    state = state.where((element) => element.id != file.id).toList();
  }
}

final recentFilesProvider =
    NotifierProvider<RecentFilesNotifier, List<RecentFiles>>(
        RecentFilesNotifier.new);

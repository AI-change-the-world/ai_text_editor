import 'dart:async';
import 'dart:math';

import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/objectbox.g.dart';
import 'package:ai_text_editor/data/datasources/objectbox/database.dart';
import 'package:ai_text_editor/data/datasources/objectbox/entities/document_meta.dart';
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

/// 最近文档 Notifier - 使用新的 DocumentMeta
class RecentDocumentsNotifier extends Notifier<List<DocumentMeta>> {
  @override
  List<DocumentMeta> build() {
    final query = ObxDatabase.db.documentMetaBox
        .query(DocumentMeta_.isFolder.equals(false))
        .order(DocumentMeta_.lastAccessedAt, flags: Order.descending)
        .build();
    query.limit = 10;

    final result = query.find();
    query.close();
    return result;
  }

  void refresh() {
    final query = ObxDatabase.db.documentMetaBox
        .query(DocumentMeta_.isFolder.equals(false))
        .order(DocumentMeta_.lastAccessedAt, flags: Order.descending)
        .build();
    query.limit = 10;

    state = query.find();
    query.close();
  }

  void add(DocumentMeta doc) {
    state = [doc, ...state.where((d) => d.uuid != doc.uuid)].take(10).toList();
  }

  void remove(DocumentMeta doc) {
    state = state.where((element) => element.uuid != doc.uuid).toList();
  }
}

final recentDocumentsProvider =
    NotifierProvider<RecentDocumentsNotifier, List<DocumentMeta>>(
        RecentDocumentsNotifier.new);

/// @deprecated Use recentDocumentsProvider instead
final recentFilesProvider = recentDocumentsProvider;

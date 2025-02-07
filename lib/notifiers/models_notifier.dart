import 'package:ai_text_editor/isar/database.dart';
import 'package:ai_text_editor/isar/model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

class ModelsState {
  final List<Model> models;
  final String? current;
  ModelsState({required this.models, this.current});

  ModelsState copyWith({List<Model>? models, String? current}) {
    return ModelsState(
        models: models ?? this.models, current: current ?? this.current);
  }
}

class ModelsNotifier extends AutoDisposeNotifier<ModelsState> {
  final IsarDatabase database = IsarDatabase();

  @override
  ModelsState build() {
    final models = database.isar!.models.where().findAllSync();
    final last = database.isar!.modelChangeHistorys
        .where(sort: Sort.desc)
        .findFirstSync();

    return ModelsState(
        models: models,
        current: models
            .firstWhere(
              (v) => v.tag == last?.tag,
              orElse: () => Model()..tag = '',
            )
            .tag);
  }

  Future<void> addChangeHistory(Model model) async {
    final history = ModelChangeHistory()
      ..tag = model.tag!
      ..createdAt = DateTime.now().millisecondsSinceEpoch;
    database.isar!.writeTxnSync(() {
      database.isar!.modelChangeHistorys.putSync(history);
    });

    state = state.copyWith(current: model.tag);
  }

  Future<void> addModel(Model model) async {
    final models = database.isar!.models.where().findAllSync();
    final modelExists = models.any((m) => m.tag == model.tag);
    if (modelExists) {
      return;
    }
    database.isar!.writeTxnSync(() {
      database.isar!.models.putSync(model);
    });
    state = state.copyWith(models: [...state.models, model]);
  }

  Future<void> deleteModel(Model model) async {
    database.isar!.writeTxnSync(() {
      database.isar!.models.deleteSync(model.id);
    });
    state = state.copyWith(models: [
      for (final m in state.models)
        if (m.id != model.id) m,
    ]);
  }
}

final modelsProvider =
    AutoDisposeNotifierProvider<ModelsNotifier, ModelsState>(() {
  return ModelsNotifier();
});

import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/objectbox.g.dart';
import 'package:ai_text_editor/objectbox/database.dart';
import 'package:ai_text_editor/objectbox/model.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final ObxDatabase database = ObxDatabase.db;

  @override
  ModelsState build() {
    final models = database.modelBox.getAll();
    final lastQuery = database.modelChangeHistoryBox
        .query()
        .order(ModelChangeHistory_.createdAt, flags: Order.descending)
        .build();
    final List<ModelChangeHistory> lastList = lastQuery.find();
    final last = lastList.firstOrNull;

    return ModelsState(
        models: models,
        current: models
            .firstWhere(
              (v) => v.tag == last?.tag,
              orElse: () => Model.empty(),
            )
            .tag);
  }

  Future<void> addChangeHistory(Model model) async {
    final history = ModelChangeHistory(tag: model.tag)
      ..createdAt = DateTime.now().millisecondsSinceEpoch;
    database.modelChangeHistoryBox.put(history);

    state = state.copyWith(current: model.tag);
    GlobalModel.setModel(OpenAIInfo(model.baseUrl, model.sk, model.modelName));
  }

  Model? getCurrent() {
    if (state.current == null || state.current == "") return null;
    final m =
        state.models.firstWhere((element) => element.tag == state.current);
    return m;
  }

  Future<void> addModel(Model model) async {
    final models = database.modelBox.getAll();

    final modelExists = models.any((m) => m.tag == model.tag);
    if (modelExists) {
      return;
    }

    database.modelBox.put(model);
    state = state.copyWith(models: [...state.models, model]);
  }

  Future<void> deleteModel(Model model) async {
    if (model.tag == state.current) {
      ToastUtils.error(null, title: "Cannot delete current model");
      return;
    }

    database.modelBox.remove(model.id);

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

import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/data/datasources/objectbox/database.dart';
import 'package:ai_text_editor/data/datasources/objectbox/entities/model_profile.dart';
import 'package:ai_text_editor/services/model_profile_service.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModelsState {
  final List<ModelProfile> models;
  final String? currentTag;

  ModelsState({required this.models, this.currentTag});

  ModelsState copyWith({List<ModelProfile>? models, String? currentTag}) {
    return ModelsState(
      models: models ?? this.models,
      currentTag: currentTag ?? this.currentTag,
    );
  }
}

class ModelsNotifier extends AutoDisposeNotifier<ModelsState> {
  final ObxDatabase database = ObxDatabase.db;

  @override
  ModelsState build() {
    final profiles = database.modelProfileBox.getAll();

    // 找到默认的 chat 模型
    final defaultChat = profiles
        .where((p) => p.taskType == AITask.chat && p.isDefault)
        .firstOrNull;

    return ModelsState(
      models: profiles,
      currentTag: defaultChat?.tag,
    );
  }

  /// 设置当前模型
  Future<void> setCurrentModel(ModelProfile profile) async {
    // 更新为默认模型
    await ModelProfileService.instance
        .setDefaultProfileForTask(profile.tag, AITask.chat);

    state = state.copyWith(currentTag: profile.tag);

    // 解密 API Key 并设置全局模型
    final apiKey =
        ModelProfileService.instance.decryptApiKey(profile.apiKey) ?? '';
    GlobalModel.setModel(
        OpenAIInfo(profile.baseUrl, apiKey, profile.modelName));
  }

  /// 获取当前模型
  ModelProfile? getCurrent() {
    if (state.currentTag == null || state.currentTag!.isEmpty) return null;
    return state.models.where((m) => m.tag == state.currentTag).firstOrNull;
  }

  /// 添加模型
  Future<void> addModel(ModelProfile profile) async {
    final exists = state.models.any((m) => m.tag == profile.tag);
    if (exists) {
      ToastUtils.error(null, title: "Model tag already exists");
      return;
    }

    database.modelProfileBox.put(profile);
    state = state.copyWith(models: [...state.models, profile]);
  }

  /// 更新模型
  Future<void> updateModel(ModelProfile profile) async {
    database.modelProfileBox.put(profile);
    state = state.copyWith(models: [
      for (final m in state.models)
        if (m.tag == profile.tag) profile else m
    ]);
  }

  /// 删除模型
  Future<void> deleteModel(ModelProfile profile) async {
    if (profile.tag == state.currentTag) {
      ToastUtils.error(null, title: "Cannot delete current model");
      return;
    }

    database.modelProfileBox.remove(profile.id);

    state = state.copyWith(models: [
      for (final m in state.models)
        if (m.id != profile.id) m,
    ]);
  }

  /// 刷新模型列表
  void refresh() {
    final profiles = database.modelProfileBox.getAll();
    state = state.copyWith(models: profiles);
  }

  /// 获取指定任务的模型列表
  List<ModelProfile> getModelsForTask(AITask task) {
    return state.models
        .where((m) => m.taskType == task && m.isEnabled)
        .toList();
  }
}

final modelsProvider =
    AutoDisposeNotifierProvider<ModelsNotifier, ModelsState>(() {
  return ModelsNotifier();
});

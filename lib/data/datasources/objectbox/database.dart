// ignore_for_file: depend_on_referenced_packages

import 'package:ai_text_editor/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'entities/entities.dart';

class ObxDatabase {
  late final Store store;
  static ObxDatabase? _instance;

  static ObxDatabase get db => _instance!;

  // Entity boxes
  late final Box<Workspace> workspaceBox;
  late final Box<DocumentMeta> documentMetaBox;
  late final Box<DocumentContent> documentContentBox;
  late final Box<DocumentChunk> documentChunkBox;
  late final Box<Asset> assetBox;
  late final Box<ModelProfile> modelProfileBox;
  late final Box<ChatHistory> chatHistoryBox;
  late final Box<ChatMessage> chatMessageBox;
  late final Box<EmbeddingCache> embeddingCacheBox;

  ObxDatabase._create(this.store) {
    workspaceBox = Box<Workspace>(store);
    documentMetaBox = Box<DocumentMeta>(store);
    documentContentBox = Box<DocumentContent>(store);
    documentChunkBox = Box<DocumentChunk>(store);
    assetBox = Box<Asset>(store);
    modelProfileBox = Box<ModelProfile>(store);
    chatHistoryBox = Box<ChatHistory>(store);
    chatMessageBox = Box<ChatMessage>(store);
    embeddingCacheBox = Box<EmbeddingCache>(store);
  }

  static Future<void> create() async {
    final docsDir = await getApplicationSupportDirectory();
    final store =
        await openStore(directory: p.join(docsDir.path, "AITextEditor"));
    _instance = ObxDatabase._create(store);

    // 确保有默认工作空间
    await _instance!._ensureDefaultWorkspace();
  }

  /// 确保有默认工作空间
  Future<void> _ensureDefaultWorkspace() async {
    final existing = workspaceBox
        .query(Workspace_.name.equals('Default'))
        .build()
        .findFirst();

    if (existing == null) {
      final workspace = Workspace(
        uuid: const Uuid().v4(),
        name: 'Default',
        description: 'Default workspace',
        colorTheme: '#2196F3',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      workspaceBox.put(workspace);
    }
  }

  /// 获取默认工作空间
  Workspace? getDefaultWorkspace() {
    return workspaceBox
        .query(Workspace_.name.equals('Default'))
        .build()
        .findFirst();
  }

  /// 获取指定任务的默认模型
  ModelProfile? getDefaultModel(AITask task) {
    final profiles = modelProfileBox.getAll();
    return profiles
        .where((p) => p.taskTypeIndex == task.index && p.isDefault)
        .firstOrNull;
  }

  /// 获取指定任务的所有模型
  List<ModelProfile> getModelsForTask(AITask task) {
    final profiles = modelProfileBox.getAll();
    return profiles
        .where((p) => p.taskTypeIndex == task.index && p.isEnabled)
        .toList();
  }

  /// 检查是否配置了嵌入模型
  bool hasEmbeddingModel() {
    final profiles = modelProfileBox.getAll();
    return profiles
        .any((p) => p.taskTypeIndex == AITask.embedding.index && p.isEnabled);
  }
}

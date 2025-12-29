// ignore_for_file: depend_on_referenced_packages

import 'package:ai_text_editor/objectbox.g.dart';
import 'package:ai_text_editor/objectbox/model.dart';
import 'package:ai_text_editor/objectbox/recent_files.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'entities/entities.dart';

class ObxDatabase {
  late final Store store;
  static ObxDatabase? _instance;

  static ObxDatabase get db => _instance!;

  // Legacy boxes
  late final Box<Model> modelBox;
  late final Box<ModelChangeHistory> modelChangeHistoryBox;
  late final Box<RecentFiles> recentFilesBox;

  // New entity boxes
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
    // Legacy boxes
    modelBox = Box<Model>(store);
    modelChangeHistoryBox = Box<ModelChangeHistory>(store);
    recentFilesBox = Box<RecentFiles>(store);

    // New entity boxes
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
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store =
        await openStore(directory: p.join(docsDir.path, "AITextEditor"));
    _instance = ObxDatabase._create(store);
  }
}

// ignore_for_file: depend_on_referenced_packages

import 'package:ai_text_editor/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'model.dart';
import 'recent_files.dart';

class ObxDatabase {
  late final Store store;
  static ObxDatabase? _instance;

  static ObxDatabase get db => _instance!;

  late final Box<Model> modelBox;
  late final Box<ModelChangeHistory> modelChangeHistoryBox;
  late final Box<RecentFiles> recentFilesBox;

  ObxDatabase._create(this.store) {
    modelBox = Box<Model>(store);
    modelChangeHistoryBox = Box<ModelChangeHistory>(store);
    recentFilesBox = Box<RecentFiles>(store);
  }

  static Future<void> create() async {
    final docsDir = await getApplicationSupportDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store =
        await openStore(directory: p.join(docsDir.path, "AITextEditor"));
    _instance = ObxDatabase._create(store);
  }
}

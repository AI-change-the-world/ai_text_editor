import 'package:isar/isar.dart';

part 'recent_files.g.dart';

@collection
class RecentFiles {
  Id id = Isar.autoIncrement;

  String? path;
  int createdAt = DateTime.now().millisecondsSinceEpoch;
}

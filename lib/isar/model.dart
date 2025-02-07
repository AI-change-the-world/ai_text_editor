import 'package:isar/isar.dart';

part 'model.g.dart';

@collection
class Model {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? tag;
  String? baseUrl;
  String? modelName;
  String? sk;
  int createdAt = DateTime.now().millisecondsSinceEpoch;
}

@collection
class ModelChangeHistory {
  Id id = Isar.autoIncrement;
  late String tag;
  int createdAt = DateTime.now().millisecondsSinceEpoch;
}

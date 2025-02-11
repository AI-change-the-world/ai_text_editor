import 'package:objectbox/objectbox.dart';

@Entity()
class Model {
  @Id()
  int id;
  @Unique()
  String tag;
  String baseUrl;
  String modelName;
  String sk;
  int createdAt = DateTime.now().millisecondsSinceEpoch;

  Model({
    this.id = 0,
    required this.tag,
    required this.baseUrl,
    required this.modelName,
    required this.sk,
  });

  static Model empty() {
    return Model(
      tag: "",
      baseUrl: "",
      modelName: "",
      sk: "",
    );
  }
}

@Entity()
class ModelChangeHistory {
  @Id()
  int id;
  late String tag;
  int createdAt = DateTime.now().millisecondsSinceEpoch;

  ModelChangeHistory({
    this.id = 0,
    required this.tag,
  });
}

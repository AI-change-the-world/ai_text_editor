import 'package:objectbox/objectbox.dart';

@Entity()
class RecentFiles {
  @Id()
  int id;

  String path;
  int createdAt = DateTime.now().millisecondsSinceEpoch;
  int lastEdited = DateTime.now().millisecondsSinceEpoch;

  RecentFiles({
    this.id = 0,
    required this.path,
  });
}

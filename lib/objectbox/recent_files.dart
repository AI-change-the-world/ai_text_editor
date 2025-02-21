import 'package:get_time_ago/get_time_ago.dart';
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

Map<String, List<RecentFiles>> groupRecentFilesByDay(List<RecentFiles> files) {
  Map<String, List<RecentFiles>> grouped = {};

  for (var file in files) {
    String dayKey =
        GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(file.lastEdited));

    if (!grouped.containsKey(dayKey)) {
      grouped[dayKey] = [];
    }
    grouped[dayKey]!.add(file);
  }

  return grouped;
}

// 按天聚合 RecentFiles，并按日期倒序排列
Map<String, List<RecentFiles>> groupRecentFilesByDayDesc(
    List<RecentFiles> files) {
  Map<String, List<RecentFiles>> grouped = {};

  for (var file in files) {
    String dayKey =
        GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(file.lastEdited));

    grouped.putIfAbsent(dayKey, () => []).add(file);
  }

  // 按日期倒序排列
  var sortedKeys = grouped.keys.toList()
    ..sort((a, b) => b.compareTo(a)); // 降序排序

  // 重新构建排序后的 Map
  Map<String, List<RecentFiles>> sortedGrouped = {
    for (var key in sortedKeys) key: grouped[key]!
  };

  return sortedGrouped;
}

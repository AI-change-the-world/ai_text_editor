import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

void customTableEmbedToMarkdown(Embed embed, StringSink out) {
  final data = embed.value.data;
  out.write(_toMarkdownTable(jsonDecode(data)));
}

String _toMarkdownTable(Map<String, dynamic> data) {
  int rowCount = data["rowCount"];
  int colCount = data["colCount"];
  List<String> values = List<String>.from(data["values"]);

  // 生成表头
  String header = List.filled(colCount, "Column").join(" | ");
  String separator = List.filled(colCount, "---").join(" | ");

  // 生成数据行
  List<String> rows = [];
  for (int i = 0; i < rowCount; i++) {
    List<String> rowValues = values.sublist(i * colCount, (i + 1) * colCount);
    rows.add(rowValues.join(" | "));
  }

  // 拼接成 Markdown 表格
  return "| $header |\n| $separator |\n${rows.map((r) => "| $r |").join("\n")}";
}

const String customTableEmbedType = 'custom-embed-table';

class CustomTableEmbed extends CustomBlockEmbed {
  CustomTableEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomTableEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomTableEmbed(customTableEmbedType, embeddable.data);
  }
}

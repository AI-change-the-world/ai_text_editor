import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

const String customRollEmbedType = 'custom-embed-roll';

void customRollEmbedToMarkdown(Embed embed, StringSink out) {
  out.write("~~this is a rolling dice, meaningless~~");
}

class CustomRollEmbed extends CustomBlockEmbed {
  CustomRollEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomRollEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomRollEmbed(customRollEmbedType, embeddable.data);
  }
}

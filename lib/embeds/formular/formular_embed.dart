import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

const String customFormularEmbedType = 'custom-embed-formular';

void customFormularEmbedToMarkdown(Embed embed, StringSink out) {
  if (embed.value.data == null) {
    out.write("~~this is a deleted formular, meaningless~~");
    return;
  }

  Map<String, dynamic> j = jsonDecode(embed.value.data);
  if (j['image'] == null) {
    out.write("~~this is a deleted formular, meaningless~~");
    return;
  }
  out.write("![](data:image/png;base64,${j['image']})");
}

class CustomFormularEmbed extends CustomBlockEmbed {
  CustomFormularEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomBlockEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomBlockEmbed(customFormularEmbedType, embeddable.data);
  }
}

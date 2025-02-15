import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';

const String customRefEmbedType = 'custom-embed-ref';

void customRefEmbedToMarkdown(Embed embed, StringSink out) {
  final data = embed.value.data;
  final m = jsonDecode(data);
  if (Platform.isWindows) {
    out.write('[${m['url']}](${m['url'].replaceAll('\\', '/')})');
  } else {
    out.write('[${m['url']}](${m['url']})');
  }
}

class CustomRefEmbed extends CustomBlockEmbed {
  CustomRefEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomRefEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomRefEmbed(customRefEmbedType, embeddable.data);
  }
}

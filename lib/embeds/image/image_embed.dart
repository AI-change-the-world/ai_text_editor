import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';

const String customImageEmbedType = 'custom-embed-image';

void customImageEmbedToMarkdown(Embed embed, StringSink out) {
  final data = embed.value.data;
  final m = jsonDecode(data);
  if (Platform.isWindows) {
    out.write('![${m['url']}](${m['url'].replaceAll('\\', '/')})');
  } else {
    out.write('![${m['url']}](${m['url']})');
  }
}

class CustomImageEmbed extends CustomBlockEmbed {
  CustomImageEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomImageEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomImageEmbed(customImageEmbedType, embeddable.data);
  }
}

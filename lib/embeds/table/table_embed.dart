import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

void customTableEmbedToMarkdown(Embed embed, StringSink out) {
  // TODO: Implement custom table embed to markdown
  out.write('<table class="custom-table">');
  out.write('<tr>');
  out.write('<td></td>');
  out.write('</tr>');
  out.write('</table>');
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

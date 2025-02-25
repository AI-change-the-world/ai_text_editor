import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'dart:math';

import 'package:flutter/material.dart';

part 'roll_builder.dart';

const String customRollEmbedType = 'custom-embed-roll';

void customRollEmbedToMarkdown(Embed embed, StringSink out) {
  if (embed.value.data == null) {
    out.write("~~this is a rolling dice1, meaningless~~");
    return;
  }
  if (embed.value.data is! String) {
    out.write("~~this is a rolling dice2, meaningless~~");
    return;
  }

  /// FIXME: WTF?
  if (embed.value.data.isEmpty) {
    out.write("~~this is a rolling dice3, meaningless~~");
    return;
  }

  Map<String, dynamic> j = jsonDecode(embed.value.data);
  if (j['image'] == null) {
    out.write("~~this is a rolling dice4, meaningless~~");
    return;
  }
  out.write("![](data:image/png;base64,${j['image']})");
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

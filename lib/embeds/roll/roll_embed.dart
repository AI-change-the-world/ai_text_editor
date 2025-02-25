import 'dart:convert';

import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

part 'roll_builder.dart';

const String customRollEmbedType = 'custom-embed-roll';

void customRollEmbedToMarkdown(Embed embed, StringSink out) {
  if (embed.value.data == null) {
    out.write("~~this is a rolling dice1, meaningless~~");
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

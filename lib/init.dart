// ignore_for_file: no_leading_underscores_for_local_identifiers, library_private_types_in_public_api, unused_element, unused_element_parameter

import 'dart:convert';

import 'package:ai_text_editor/utils/logger.dart';
import 'package:flutter/services.dart';

class APPConfig {
  static String appName = "AI Text Editor";
  static String spellCheckPrompt =
      "Please correct the spelling mistakes in the following text: {text}";

  static List<_Word> words = [];

  static const List<String> supportFormats = [
    "csv",
  ];

  static Future<void> init() async {
    late Map<String, dynamic> config = {};
    try {
      final String r = await rootBundle.loadString("assets/config.json");
      config = json.decode(r);
      String _appName = config['app-name'] ?? "AI Text Editor";

      if (config['words'] != null) {
        words = <_Word>[];
        config['words'].forEach((v) {
          words.add(_Word.fromJson(v));
        });
      }
      final String _spellCheck =
          await rootBundle.loadString("assets/prompts/spell-check-prompt.txt");
      // return APPConfig(appName: appName, spellCheckPrompt: spellCheck);
      appName = _appName;
      spellCheckPrompt = _spellCheck;
    } catch (e) {
      logger.e("Error loading config.json: $e");
    }
  }
}

class _Word {
  String? text;
  String? from;
  String? region;

  _Word({this.text, this.from, this.region});

  _Word.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    from = json['from'];
    region = json['region'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['text'] = text;
    data['from'] = from;
    data['region'] = region;
    return data;
  }
}

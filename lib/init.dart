// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:flutter/services.dart';

class APPConfig {
  static String appName = "AI Text Editor";
  static String spellCheckPrompt =
      "Please correct the spelling mistakes in the following text: {text}";

  static Future<void> init() async {
    late Map<String, dynamic> config = {};
    try {
      final String r = await rootBundle.loadString("assets/config.json");
      config = json.decode(r);
      String _appName = config['app-name'] ?? "AI Text Editor";
      final String _spellCheck =
          await rootBundle.loadString("assets/prompts/spell-check-prompt.txt");
      // return APPConfig(appName: appName, spellCheckPrompt: spellCheck);
      appName = _appName;
      spellCheckPrompt = _spellCheck;
    } catch (_) {}
  }
}

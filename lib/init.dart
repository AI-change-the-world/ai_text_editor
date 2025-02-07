import 'dart:convert';

import 'package:ai_text_editor/models/ai_model.dart';
import 'package:flutter/services.dart';

class APPConfig {
  final String appName;
  APPConfig({this.appName = "AI Text Editor"});

  static Future<APPConfig> init() async {
    late Map<String, dynamic> config = {};
    try {
      final String r = await rootBundle.loadString("assets/config.json");
      config = json.decode(r);
      String appName = config['app-name'] ?? "AI Text Editor";
      return APPConfig(appName: appName);
    } catch (_) {
      return APPConfig();
    }
  }
}

@Deprecated("Use `APPConfig.init()` instead")
Future<OpenAIInfo?> initOpenAILikeModel() async {
  late Map<String, dynamic> config = {};
  try {
    final String r = await rootBundle.loadString("assets/config.json");
    config = json.decode(r);
    String sk = config['llm-sk'];
    String model = config['llm-model-name'];
    String baseUrl = config['llm-base'];
    OpenAIInfo openAIInfo = OpenAIInfo(baseUrl, sk, model);
    return openAIInfo;
  } catch (_) {
    return null;
  }
}

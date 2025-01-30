import 'dart:convert';

import 'package:ai_text_editor/models/ai_model.dart';
import 'package:flutter/services.dart';

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

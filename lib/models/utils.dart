import 'package:ai_packages_core/ai_packages_core.dart';
import 'package:langchain/langchain.dart' as lc;

List<lc.ChatMessage> getMessagesFromList(List<ChatMessage> history) {
  return history.map((e) {
    if (e.role == "user") {
      return lc.HumanChatMessage(
          content: lc.ChatMessageContent.text(e.content));
    } else if (e.role == "assistant") {
      return lc.AIChatMessage(content: e.content);
    } else {
      return lc.SystemChatMessage(content: e.content);
    }
  }).toList();
}

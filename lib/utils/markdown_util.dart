import '../models/markdown_model.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart';

class MarkdownUtil {
  MarkdownUtil._();

  static List<MarkdownModel> fromMdString(String mdString) {
    List<Node> parsedResult = Document().parse(mdString);
    return parsedResult.map((node) {
      if (node is! Element) return MarkdownModel(tag: "", text: "");
      return MarkdownModel(tag: node.tag, text: node.textContent);
    }).toList();
  }
}

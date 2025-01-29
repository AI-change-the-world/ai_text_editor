// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart';

void main() {
  String markdownContent = """
# 标题1
这是第一个一级标题下的文本

## 标题2
这是二级标题下的文本

### 标题3
这是三级标题下的文本
""";

  // 解析Markdown文本
  List<Node> parsedResult = Document().parse(markdownContent);

  // 遍历解析结果，寻找标题节点
  for (Node node in parsedResult) {
    // ignore: avoid_print
    print((node as Element).tag);
  }
}

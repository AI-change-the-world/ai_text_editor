// ignore_for_file: unnecessary_string_escapes, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

const String mdString = """
## ChatGPT Response

----

Welcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:

### Markdown Example

You can use Markdown to format text easily. Here are some examples:

- **Bold Text**: **This text is bold**
- *Italic Text*: *This text is italicized*
- [Link](https://www.example.com): [This is a link](https://www.example.com)
- Lists:
  1. Item 1
  2. Item 2
  3. Item 3

### LaTeX Example

You can also use LaTeX for mathematical expressions. Here's an example:

- **Equation**: \( f(x) = x^2 + 2x + 1 \)
- **Integral**: \( \int_{0}^{1} x^2 \, dx \)
- **Matrix**:

\[
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
\]

### Conclusion

Markdown and LaTeX can be powerful tools for formatting text and mathematical expressions in your Flutter app. If you have any questions or need further assistance, feel free to ask!

""";

void main() {
  late final mdDocument = md.Document(encodeHtml: false);
  late final mdToDelta = MarkdownToDelta(markdownDocument: mdDocument);
  final delta = mdToDelta.convert(mdString);
  final text = delta.toJson();
  print(jsonEncode(text));

  for (final op in delta.toList()) {
    print("op.key  ${op.key}  ${op.value}  ${op.value.runtimeType}");
  }
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(),
    );
  }
}

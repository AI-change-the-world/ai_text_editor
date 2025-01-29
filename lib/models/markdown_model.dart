class MarkdownModel {
  final String tag;
  final String text;

  MarkdownModel({required this.tag, required this.text});

  @override
  String toString() {
    return 'MarkdownModel{tag: $tag, text: $text}';
  }
}

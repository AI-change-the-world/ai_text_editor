import 'package:flutter_quill/flutter_quill.dart';

// ignore: prefer_function_declarations_over_variables
final customTableEmbed =
    (String data) => CustomBlockEmbed('custom-embed-table', data);

void customTableEmbedToMarkdown(Embed embed, StringSink out) {
  // TODO: Implement custom table embed to markdown
  out.write('<table class="custom-table">');
  out.write('<tr>');
  out.write('<td></td>');
  out.write('</tr>');
  out.write('</table>');
}

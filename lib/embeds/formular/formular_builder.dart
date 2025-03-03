import 'dart:convert';

import 'package:ai_text_editor/components/dialogs/formular_editor_dialog.dart';
import 'package:ai_text_editor/embeds/formular/formular_embed.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:screenshot/screenshot.dart';

class CustomFormularEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    final m = jsonDecode(node.value.data);
    return _FormularWidget(m['formular'], m['uuid']);
  }

  @override
  String get key => customFormularEmbedType;

  @override
  String toPlainText(Embed node) {
    final m = jsonDecode(node.value.data);
    return m['uuid'];
  }
}

class _FormularWidget extends ConsumerStatefulWidget {
  const _FormularWidget(this.data, this.uuid);
  final String data;
  final String uuid;

  @override
  ConsumerState<_FormularWidget> createState() => __FormularWidgetState();
}

class __FormularWidgetState extends ConsumerState<_FormularWidget> {
  final ScreenshotController screenshotController = ScreenshotController();
  late String data = widget.data;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onDoubleTap: () {
          showGeneralDialog(
              barrierColor: Colors.white.withValues(alpha: 0.1),
              barrierDismissible: true,
              barrierLabel: 'formular modify',
              context: context,
              pageBuilder: (c, _, __) {
                return Center(
                  child: FormularEditorDialog(
                    formular: data,
                  ),
                );
              }).then((v) {
            if (v != null) {
              setState(() {
                data = v.toString();
              });
              screenshotController.capture().then((img) {
                if (img != null) {
                  ref
                      .read(editorNotifierProvider.notifier)
                      .onEmbedTrigger(widget.uuid);
                  Map<String, dynamic> m = {
                    'uuid': widget.uuid,
                    'formular': data,
                    "image": base64Encode(img)..replaceAll("\n", "")
                  };
                  ref.read(editorNotifierProvider.notifier).changeFormular(m);
                }
              });
            }
          });
        },
        child: Screenshot(
            controller: screenshotController,
            child: Center(
              child: GptMarkdown(data),
            )),
      ),
    );
  }
}

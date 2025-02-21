import 'dart:convert';
import 'dart:io';

import 'package:ai_text_editor/embeds/models/models.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

// ignore: unused_import, depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';

import 'ref_embed.dart';

class CustomRefEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    final data = node.value.data;
    final m = FileModel.fromJson(jsonDecode(data));
    assert(m.validate());
    return _ReferenceWidget(model: m);
  }

  @override
  String get key => customRefEmbedType;
}

class _ReferenceWidget extends StatefulWidget {
  const _ReferenceWidget({required this.model});
  final FileModel model;

  @override
  State<_ReferenceWidget> createState() => __ReferenceWidgetState();
}

class __ReferenceWidgetState extends State<_ReferenceWidget> {
  bool onHover = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.model.type == 'web') {
          final Uri url = Uri.parse(widget.model.url!);
          launchUrl(url);
        } else {
          final Uri uri = Uri.file(widget.model.url!);
          if (!File(uri.toFilePath()).existsSync()) {
            ToastUtils.error(context, title: "File not found");
            return;
          }
          launchUrl(uri);
        }
      },
      child: MouseRegion(
        onEnter: (event) {
          setState(() {
            onHover = true;
          });
        },
        onExit: (event) {
          setState(() {
            onHover = false;
          });
        },
        child: Material(
          elevation: onHover ? 10 : 4,
          borderRadius: BorderRadius.circular(10),
          child: Container(
              width: 400,
              height: widget.model.description == null ||
                      widget.model.description == ""
                  ? 50
                  : 300,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Column(children: [
                Text(widget.model.url!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    )),
                if (widget.model.description != null &&
                    widget.model.description != "")
                  Text(widget.model.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ))
              ])),
        ),
      ),
    );
  }
}

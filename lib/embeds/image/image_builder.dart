import 'dart:convert';
import 'dart:io';

import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomImageEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    /// {"url":string,"type":local/web,"uuid":string}
    final m = jsonDecode(node.value.data);
    if (m['type'] == 'local') {
      return ExtendedImage.file(
        File(m['url']),
        width: 600,
        height: 400,
        fit: BoxFit.contain,
      );
    } else {
      return ExtendedImage.network(m['url'],
          fit: BoxFit.contain,
          cache: true,
          width: 600,
          height: 400, loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Container(
              color: Colors.grey,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );

          case LoadState.completed:
            return ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              width: 600,
              height: 400,
            );

          case LoadState.failed:
            return Container(
              color: Colors.grey,
              child: Center(
                child: Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
            );
        }
      });
    }
  }

  @override
  String toPlainText(Embed node) {
    final m = jsonDecode(node.value.data);
    return m['uuid'];
  }

  @override
  String get key => customImageEmbedType;
}

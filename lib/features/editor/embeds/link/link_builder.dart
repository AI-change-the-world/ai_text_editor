import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ai_text_editor/features/editor/widgets/link_preview_card.dart';
import 'link_embed.dart';

/// Custom link embed builder for flutter_quill
/// Requirements: 2.8 - WHEN a user embeds a link THEN the System SHALL fetch
/// and display a rich preview card with title, description, and thumbnail
class CustomLinkEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedCtx) {
    final data = embedCtx.node.value.data;
    final linkData = LinkEmbedData.fromJson(jsonDecode(data));

    return _LinkEmbedWidget(
      data: linkData,
      readOnly: embedCtx.controller.readOnly,
    );
  }

  @override
  String get key => customLinkEmbedType;
}

class _LinkEmbedWidget extends StatelessWidget {
  final LinkEmbedData data;
  final bool readOnly;

  const _LinkEmbedWidget({
    required this.data,
    required this.readOnly,
  });

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(data.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: LinkPreviewCard(
          url: data.url,
          onTap: _openUrl,
          compact: false,
        ),
      ),
    );
  }
}

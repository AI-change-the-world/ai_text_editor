import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

const String customLinkEmbedType = 'custom-embed-link';

/// Convert link embed to markdown format
void customLinkEmbedToMarkdown(Embed embed, StringSink out) {
  final data = embed.value.data;
  final m = jsonDecode(data);
  final url = m['url'] ?? '';
  final title = m['title'] ?? url;
  out.write('[$title]($url)');
}

/// Link embed data model
class LinkEmbedData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  LinkEmbedData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  factory LinkEmbedData.fromJson(Map<String, dynamic> json) {
    return LinkEmbedData(
      url: json['url'] ?? '',
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

/// Custom link embed for flutter_quill
class CustomLinkEmbed extends CustomBlockEmbed {
  CustomLinkEmbed(super.type, super.data);

  @override
  String toJsonString() {
    return jsonEncode(toJson());
  }

  static CustomLinkEmbed fromJson(Map<String, dynamic> json) {
    final embeddable = Embeddable.fromJson(json);
    return CustomLinkEmbed(customLinkEmbedType, embeddable.data);
  }

  static CustomLinkEmbed fromUrl(String url,
      {String? title, String? description, String? imageUrl}) {
    final data = LinkEmbedData(
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
    );
    return CustomLinkEmbed(customLinkEmbedType, jsonEncode(data.toJson()));
  }
}
